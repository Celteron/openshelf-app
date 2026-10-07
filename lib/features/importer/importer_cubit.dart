import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

sealed class ImporterState {
  const ImporterState();
}

class ImporterSelecting extends ImporterState {
  const ImporterSelecting();
}

class ImporterMapping extends ImporterState {
  final ImportFile file;
  final BookImporter importer;
  const ImporterMapping(this.file, this.importer);
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
    emit(ImporterMapping(file, importer));
  }

  Future<void> runImport() async {
    final current = state;
    if (current is! ImporterMapping) return;

    final result = await _importService.import(
      current.importer.parse(current.file),
    );
    emit(ImporterDone(result));
  }
}
