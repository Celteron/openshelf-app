import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

sealed class ImporterState {
  const ImporterState();
}

class ImporterSelecting extends ImporterState {
  const ImporterSelecting();
}

/// The file is chosen and its format detected; for CSV the user can still
/// match columns to fields and switch the format (the "matcher").
class ImporterMapping extends ImporterState {
  final ImportFile file;
  final BookImporter importer;

  /// Source columns with their assignment; empty for formats without columns.
  final List<ImportColumn> columns;

  /// Formats the user may switch to; empty when the format is fixed.
  final List<BookImporter> alternatives;

  /// Whether the import can start: a column-based format needs a title column
  /// (a book without a title is skipped).
  bool get canImport =>
      columns.isEmpty || columns.any((c) => c.field == 'title');

  const ImporterMapping(
    this.file,
    this.importer, {
    this.columns = const [],
    this.alternatives = const [],
  });
}

class ImporterImporting extends ImporterState {
  final int processed;
  const ImporterImporting(this.processed);
}

class ImporterDone extends ImporterState {
  final ImportResult result;
  const ImporterDone(this.result);
}

class ImporterError extends ImporterState {
  final String message;
  const ImporterError(this.message);
}

/// Drives the import lifecycle (`selecting | mapping | importing | done`,
/// spec §6.4).
class ImporterCubit extends Cubit<ImporterState> {
  final ImportService _importService;
  final List<BookImporter> _importers;

  ImporterCubit(this._importService, this._importers)
    : super(const ImporterSelecting());

  BookImporter? detect(ImportFile file) {
    for (final importer in _importers) {
      if (importer.supportedType == file.type && importer.canParse(file)) {
        return importer;
      }
    }
    return null;
  }

  void selectFile(ImportFile file) {
    final importer = detect(file);
    if (importer == null) {
      emit(const ImporterError('Unsupported file format'));
      return;
    }
    emit(_mappingFor(file, importer));
  }

  /// Starts the matcher for [importer]: CSV formats get their columns with the
  /// format's default assignment as suggestion.
  ImporterMapping _mappingFor(ImportFile file, BookImporter importer) {
    if (importer is! CsvImporter) return ImporterMapping(file, importer);
    return ImporterMapping(
      file,
      importer,
      columns: [
        for (final (i, c) in importer.columns(file).indexed)
          ImportColumn(
            index: i,
            header: c.header,
            sample: c.sample,
            field: importer.columnMapper.fieldForHeader(c.header),
          ),
      ],
      alternatives: _importers.whereType<CsvImporter>().toList(),
    );
  }

  /// Switches the format and re-suggests the column assignment.
  void changeImporter(BookImporter importer) {
    final current = state;
    if (current is! ImporterMapping) return;
    emit(_mappingFor(current.file, importer));
  }

  /// Assigns the column at [index] to [field]; `null` leaves it out.
  void assign(int index, String? field) {
    final current = state;
    if (current is! ImporterMapping) return;
    emit(
      ImporterMapping(
        current.file,
        current.importer,
        alternatives: current.alternatives,
        columns: [
          for (final c in current.columns)
            c.index == index ? c.withField(field) : c,
        ],
      ),
    );
  }

  Future<void> runImport() async {
    final current = state;
    if (current is! ImporterMapping || !current.canImport) return;

    emit(const ImporterImporting(0));
    final importer = current.importer;
    final rows = importer is CsvImporter
        ? importer.parse(
            current.file,
            columnFields: {
              for (final c in current.columns)
                if (c.field != null) c.index: c.field!,
            },
          )
        : importer.parse(current.file);
    try {
      emit(ImporterDone(await _importService.import(rows)));
    } catch (e) {
      emit(ImporterError(e.toString()));
    }
  }
}
