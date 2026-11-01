import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/export/export_file_saver.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_decoding.dart';
import 'package:openreads/data/importers/own_csv_importer.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/features/importer/importer_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Import and export in one place (spec 004 FR-R2-04/05). Import: pick a
/// CSV/JSON file, auto-detect the format, match columns, run the import with
/// a progress bar and show the result (spec §6.4, US4). Export: JSON backup or
/// CSV through the platform's save dialog.
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _path = TextEditingController();

  // Read once: `context` must not be used in dispose.
  late final ImporterCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ImporterCubit>();
  }

  @override
  void dispose() {
    // The cubit is app-wide; without this, a result or an abandoned matcher
    // would greet the next visit and block a new import. A running import is
    // left alone (reset ignores it).
    _cubit.reset();
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
      final file = await FilePicker.pickFile();
      if (file == null) return;
      _select(file.name, await file.readAsBytes());
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

  Future<void> _exportJson() async {
    final json = await context.read<ExportService>().exportJson();
    await _writeExport('openshelf_export.json', json);
  }

  Future<void> _exportCsv() async {
    final csv = await context.read<ExportService>().exportBooksCsv();
    await _writeExport('openshelf_books.csv', csv);
  }

  Future<void> _writeExport(String name, String content) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saver = context.read<ExportFileSaver>();
    final String? path;
    try {
      path = await saver.save(name, content);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
      return;
    }
    if (path == null) return;
    messenger.showSnackBar(SnackBar(content: Text('${l10n.exportDone} $path')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportLabel)),
      body: BlocBuilder<ImporterCubit, ImporterState>(
        builder: (context, state) {
          return switch (state) {
            ImporterSelecting() => _startView(context, l10n),
            ImporterMapping() => _MatcherView(state: state),
            ImporterImporting(:final processed, :final total) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.importRunning,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: total == 0 ? null : processed / total,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.importProgress(processed, total)),
                  ],
                ),
              ),
            ),
            ImporterDone(:final result) => _ResultView(
              icon: Icons.check_circle_outline,
              title: l10n.importDoneTitle,
              children: [
                Text(l10n.importedCount(result.imported)),
                Text(l10n.updatedCount(result.updated)),
                Text(l10n.skippedCount(result.skipped)),
                if (result.duplicates > 0)
                  Text(l10n.duplicatesSkippedCount(result.duplicates)),
                for (final error in result.errors)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.error_outline),
                    title: Text(l10n.rowError(error.rowNumber, error.reason)),
                  ),
              ],
            ),
            ImporterError(:final message) => _ResultView(
              icon: Icons.error_outline,
              isError: true,
              title: l10n.importFailedTitle,
              children: [Text(message, textAlign: TextAlign.center)],
            ),
          };
        },
      ),
    );
  }

  Widget _startView(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActionCard(
          icon: Icons.file_download_outlined,
          title: l10n.importAction,
          body: l10n.restoreBackupHint,
          children: [
            FilledButton.icon(
              key: const ValueKey('import-choose-file'),
              onPressed: _pickFile,
              icon: const Icon(Icons.file_open),
              label: Text(l10n.chooseFile),
            ),
            if (_isDesktop) ...[
              const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.file_upload_outlined,
          title: l10n.exportAction,
          body: l10n.exportActionHint,
          children: [
            ListTile(
              key: const ValueKey('export-json'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.data_object),
              title: Text(l10n.exportJson),
              subtitle: Text(l10n.exportJsonHint),
              onTap: _exportJson,
            ),
            ListTile(
              key: const ValueKey('export-csv'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.table_chart),
              title: Text(l10n.exportCsv),
              subtitle: Text(l10n.exportCsvHint),
              onTap: _exportCsv,
            ),
          ],
        ),
      ],
    );
  }
}

/// One of the two actions on the start view.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// End of an import: outcome, details, and the way on.
class _ResultView extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool isError;

  const _ResultView({
    required this.icon,
    required this.title,
    required this.children,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          icon,
          size: 64,
          color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('import-again'),
              onPressed: () => context.read<ImporterCubit>().reset(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.importAgain),
            ),
            FilledButton(
              key: const ValueKey('import-done'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.importFinish),
            ),
          ],
        ),
      ],
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
