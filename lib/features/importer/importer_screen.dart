import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/importers/import_decoding.dart';
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
            ImporterMapping(:final importer, :final file) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.detectedFormat(importer.formatName)),
                  Text(file.name),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<ImporterCubit>().runImport(),
                    child: Text(l10n.importAction),
                  ),
                ],
              ),
            ),
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
