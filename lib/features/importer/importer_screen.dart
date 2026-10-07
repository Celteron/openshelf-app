import 'package:file_picker/file_picker.dart';
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
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    // ZIP archives (legacy Openreads backups) start with "PK".
    final isZip = bytes.length > 3 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    final lower = file.name.toLowerCase();
    final type = isZip
        ? ImportFileType.zip
        : lower.endsWith('.json')
        ? ImportFileType.json
        : ImportFileType.csv;

    if (!mounted) return;
    context.read<ImporterCubit>().selectFile(
      ImportFile(
        name: file.name,
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
              child: FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_open),
                label: Text(l10n.chooseFile),
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
