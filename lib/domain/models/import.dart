import 'package:openreads/data/database/app_database.dart';
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

/// A note or quote carried over from a legacy export (schema v2 `book_notes`).
class NoteImport {
  final NoteKind kind;
  final String content;
  final int? pageNumber;
  final DateTime? createdAt;

  const NoteImport({
    this.kind = NoteKind.note,
    required this.content,
    this.pageNumber,
    this.createdAt,
  });
}

/// One legacy "reading" of a book: when it was started/finished and an
/// optional manually entered reading time (schema v2 `reading_sessions`).
class ReadingImport {
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final Duration? duration;

  const ReadingImport({this.startedAt, this.finishedAt, this.duration});

  bool get isEmpty =>
      startedAt == null &&
      finishedAt == null &&
      (duration == null || duration == Duration.zero);
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
  final bool isFavorite;
  final String? review;
  final List<String> tags;
  final List<NoteImport> notes;
  final List<ReadingImport> readings;

  /// When the book entered the source library (becomes `created_at`).
  final DateTime? addedAt;

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
    this.isFavorite = false,
    this.review,
    this.tags = const [],
    this.notes = const [],
    this.readings = const [],
    this.addedAt,
  });

  bool get isEmpty =>
      (title == null || title!.isEmpty) && authors.isEmpty && isbn13 == null;
}

/// A book ready to be persisted together with its Schema v2 satellites
/// (tags, notes, reading sessions), written in one transaction.
class ImportedBook {
  final BooksCompanion book;
  final List<String> tags;
  final List<NoteImport> notes;
  final List<ReadingImport> readings;

  const ImportedBook({
    required this.book,
    this.tags = const [],
    this.notes = const [],
    this.readings = const [],
  });
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
