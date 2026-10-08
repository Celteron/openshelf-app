import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_decoding.dart';
import 'package:openreads/data/importers/own_csv_importer.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/features/importer/importer_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Importer screen: pick a CSV/JSON file, auto-detect the format, run the
/// import, and show the result (spec §6.4, US4).
class ImporterScreen extends StatefulWidget {
  const ImporterScreen({super.key});

  @override
  State<ImporterScreen> createState() => _ImporterScreenState();
}

class _ImporterScreenState extends State<ImporterScreen> {
  final _path = TextEditingController();

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  /// Desktop Linux has no file dialog without zenity/kdialog, so a path can be
  /// typed in as well.
  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;
      _select(file.name, bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).filePickerFailed)),
      );
    }
  }

  Future<void> _loadFromPath() async {
    final path = _path.text.trim();
    if (path.isEmpty) return;
    try {
      _select(
        path.split(RegExp(r'[\\/]')).last,
        await File(path).readAsBytes(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fileNotReadable)),
      );
    }
  }

  void _select(String name, Uint8List bytes) {
    // ZIP archives (legacy Openreads backups) start with "PK".
    final isZip = bytes.length > 3 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    final lower = name.toLowerCase();
    final type = isZip
        ? ImportFileType.zip
        : lower.endsWith('.json')
        ? ImportFileType.json
        : ImportFileType.csv;

    if (!mounted) return;
    context.read<ImporterCubit>().selectFile(
      ImportFile(
        name: name,
        content: isZip ? '' : decodeImportBytes(bytes),
        type: type,
        bytes: isZip ? bytes : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: BlocBuilder<ImporterCubit, ImporterState>(
        builder: (context, state) {
          return switch (state) {
            ImporterSelecting() => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.file_open),
                      label: Text(l10n.chooseFile),
                    ),
                    if (_isDesktop) ...[
                      const SizedBox(height: 24),
                      TextField(
                        key: const ValueKey('import-path'),
                        controller: _path,
                        onSubmitted: (_) => _loadFromPath(),
                        decoration: InputDecoration(
                          labelText: l10n.importPathLabel,
                          hintText: '/home/deck/backup.json',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('import-from-path'),
                        onPressed: _loadFromPath,
                        child: Text(l10n.importFromPath),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ImporterMapping() => _MatcherView(state: state),
            ImporterImporting(:final processed) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  Text(l10n.rowsProcessed(processed)),
                ],
              ),
            ),
            ImporterDone(:final result) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.importedCount(result.imported)),
                  Text(l10n.updatedCount(result.updated)),
                  Text(l10n.skippedCount(result.skipped)),
                  if (result.duplicates > 0)
                    Text(l10n.duplicatesSkippedCount(result.duplicates)),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final error in result.errors)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.error_outline),
                            title: Text(
                              l10n.rowError(error.rowNumber, error.reason),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ImporterError(:final message) => Center(child: Text(message)),
          };
        },
      ),
    );
  }
}

String _formatLabel(AppLocalizations l10n, BookImporter importer) =>
    importer is OwnCsvImporter ? l10n.importFormatOwnCsv : importer.formatName;

/// Format choice, column matcher and the import button.
class _MatcherView extends StatelessWidget {
  final ImporterMapping state;
  const _MatcherView({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ImporterCubit>();
    final importer = state.importer;
    final fields = importer is CsvImporter
        ? (importer.mappableFields.toList()..sort(
            (a, b) =>
                l10n.importFieldName(a).compareTo(l10n.importFieldName(b)),
          ))
        : const <String>[];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.detectedFormat(_formatLabel(l10n, importer))),
              Text(state.file.name),
              if (state.alternatives.length > 1) ...[
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.importFormatLabel,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BookImporter>(
                      key: const ValueKey('import-format'),
                      value: importer,
                      isExpanded: true,
                      items: [
                        for (final i in state.alternatives)
                          DropdownMenuItem(
                            value: i,
                            child: Text(_formatLabel(l10n, i)),
                          ),
                      ],
                      onChanged: (i) {
                        if (i != null) cubit.changeImporter(i);
                      },
                    ),
                  ),
                ),
              ],
              if (state.columns.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.importColumnsHint),
                if (!state.canImport)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.importNeedsTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                for (final column in state.columns)
                  _ColumnRow(column: column, fields: fields),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('import-run'),
                onPressed: state.canImport ? cubit.runImport : null,
                child: Text(l10n.importAction),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColumnRow extends StatelessWidget {
  final ImportColumn column;
  final List<String> fields;
  const _ColumnRow({required this.column, required this.fields});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // An assignment outside the format's own fields is not offered twice.
    final options = {
      if (column.field != null) column.field!,
      ...fields,
    }.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    column.header.isEmpty
                        ? l10n.importColumnN(column.index + 1)
                        : column.header,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (column.sample.isNotEmpty)
                    Text(
                      column.sample,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String?>(
              key: ValueKey('map:${column.index}'),
              value: column.field,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.importIgnoreColumn),
                ),
                for (final field in options)
                  DropdownMenuItem<String?>(
                    value: field,
                    child: Text(l10n.importFieldName(field)),
                  ),
              ],
              onChanged: (field) =>
                  context.read<ImporterCubit>().assign(column.index, field),
            ),
          ],
        ),
      ),
    );
  }
}
