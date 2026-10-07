import 'package:openreads/domain/models/import.dart';

/// Strategy interface for importing a collection from a third-party format.
///
/// Implementations parse an [ImportFile] lazily into a [Stream] of [ImportRow]
/// so large files are not loaded into memory all at once.
abstract class BookImporter {
  String get formatName;

  ImportFileType get supportedType;

  /// Format detection: whether this importer can handle the given file based
  /// on its header/shape.
  bool canParse(ImportFile file);

  /// Emits one [ImportRow] per source row. Malformed rows emit a row with an
  /// [ImportRow.error] instead of aborting the import.
  Stream<ImportRow> parse(ImportFile file);
}
