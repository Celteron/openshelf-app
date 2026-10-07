import 'package:openreads/domain/models/enums.dart';

enum ImportFileType { csv, json }

/// A file the user selected for import.
class ImportFile {
  final String name;
  final String content;
  final ImportFileType type;

  const ImportFile({
    required this.name,
    required this.content,
    required this.type,
  });
}

/// One candidate book produced by an importer, including ownership fields
/// (rating/status) that the metadata model does not carry.
class BookImport {
  final String? title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn13;
  final String? isbn10;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final BookFormat? format;
  final String? language;
  final String? description;
  final String? coverUrl;
  final String? seriesName;
  final double? seriesVolume;
  final double? rating;
  final BookStatus? status;

  const BookImport({
    this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn13,
    this.isbn10,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.format,
    this.language,
    this.description,
    this.coverUrl,
    this.seriesName,
    this.seriesVolume,
    this.rating,
    this.status,
  });

  bool get isEmpty =>
      (title == null || title!.isEmpty) && authors.isEmpty && isbn13 == null;
}

/// A single parsed row: either a candidate [book] or an [error] for a skipped
/// row.
class ImportRow {
  final int rowNumber;
  final BookImport? book;
  final String? error;

  const ImportRow({required this.rowNumber, this.book, this.error});
}

class RowError {
  final int rowNumber;
  final String reason;

  const RowError({required this.rowNumber, required this.reason});
}

class ImportResult {
  final int imported;
  final int skipped;
  final List<RowError> errors;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}
