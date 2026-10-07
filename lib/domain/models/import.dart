import 'dart:typed_data';

import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

enum ImportFileType { csv, json, zip }

/// A file the user selected for import. Text formats carry their decoded
/// [content]; archives ([ImportFileType.zip]) carry the raw [bytes].
class ImportFile {
  final String name;
  final String content;
  final ImportFileType type;
  final Uint8List? bytes;

  const ImportFile({
    required this.name,
    this.content = '',
    required this.type,
    this.bytes,
  });
}

/// One level of a physical location path (room → shelf → compartment).
class LocationRef {
  final String name;
  final LocationType type;

  const LocationRef(this.name, this.type);

  /// A location path from plain names, typing the levels room, shelf,
  /// compartment (deeper levels are compartments).
  static List<LocationRef> fromNames(Iterable<String> names) {
    final refs = <LocationRef>[];
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      refs.add(
        LocationRef(
          trimmed,
          refs.isEmpty
              ? LocationType.room
              : refs.length == 1
              ? LocationType.shelf
              : LocationType.compartment,
        ),
      );
    }
    return refs;
  }
}

/// A lending record carried over from a backup.
class LendingImport {
  final String borrowerName;
  final DateTime lentAt;
  final DateTime? expectedReturn;
  final DateTime? returnedAt;

  const LendingImport({
    required this.borrowerName,
    required this.lentAt,
    this.expectedReturn,
    this.returnedAt,
  });
}

/// A yearly reading goal carried over from a backup or a legacy challenge.
class GoalImport {
  final int year;
  final int targetBooks;
  final int? targetPages;

  const GoalImport({
    required this.year,
    required this.targetBooks,
    this.targetPages,
  });
}

/// A note or quote carried over from a legacy export (schema v2 `book_notes`).
class NoteImport {
  final NoteKind kind;
  final String content;
  final int? pageNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NoteImport({
    this.kind = NoteKind.note,
    required this.content,
    this.pageNumber,
    this.createdAt,
    this.updatedAt,
  });
}

/// One legacy "reading" of a book: when it was started/finished and an
/// optional manually entered reading time (schema v2 `reading_sessions`).
class ReadingImport {
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final Duration? duration;

  /// Page range, when the source knows it (OpenShelf backups).
  final int startPage;
  final int? endPage;

  /// A session that is still running. Only exact restores keep it open; every
  /// other import closes sessions so they never look like a running timer.
  final bool open;

  const ReadingImport({
    this.startedAt,
    this.finishedAt,
    this.duration,
    this.startPage = 0,
    this.endPage,
    this.open = false,
  });

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

  /// Open Library id.
  final String? olid;

  /// Where the book stands: names from room down to the innermost level.
  final List<LocationRef> locationPath;
  final int? seriesTotalVolumes;
  final List<LendingImport> lendings;

  final MetadataSource? metadataSource;
  final List<String> editedFields;

  /// Explicit reading state. Honoured when set (`exact` restores and CSV
  /// columns); otherwise derived from [status] and [readings].
  final int? currentPage;
  final DateTime? finishedAt;
  final DateTime? updatedAt;

  /// In the trash in the source.
  final DateTime? deletedAt;

  /// Restore the row as it is: no derived progress, running sessions stay
  /// open (OpenShelf JSON backups).
  final bool exact;

  /// Raw cover image bytes shipped with the source (legacy backups).
  final Uint8List? coverBytes;

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
    this.olid,
    this.locationPath = const [],
    this.seriesTotalVolumes,
    this.lendings = const [],
    this.metadataSource,
    this.editedFields = const [],
    this.currentPage,
    this.finishedAt,
    this.updatedAt,
    this.deletedAt,
    this.exact = false,
    this.coverBytes,
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
  final List<LocationRef> locationPath;
  final String? seriesName;
  final int? seriesTotalVolumes;
  final List<LendingImport> lendings;

  const ImportedBook({
    required this.book,
    this.tags = const [],
    this.notes = const [],
    this.readings = const [],
    this.locationPath = const [],
    this.seriesName,
    this.seriesTotalVolumes,
    this.lendings = const [],
  });
}

/// Locations, tags and goals that come with a backup independent of any book
/// (an empty shelf, an unused tag, a yearly goal).
class ImportExtras {
  final List<List<LocationRef>> locationPaths;
  final List<GoalImport> goals;
  final List<String> tags;

  const ImportExtras({
    this.locationPaths = const [],
    this.goals = const [],
    this.tags = const [],
  });

  bool get isEmpty => locationPaths.isEmpty && goals.isEmpty && tags.isEmpty;
}

/// A single parsed row: either a candidate [book] or an [error] for a skipped
/// row.
class ImportRow {
  final int rowNumber;
  final BookImport? book;
  final String? error;

  /// A yearly goal row (backups only).
  final GoalImport? goal;

  /// A standalone location row (backups only), e.g. an empty shelf.
  final List<LocationRef>? location;

  /// A tag that exists independent of any book (backups only).
  final String? tag;

  const ImportRow({
    required this.rowNumber,
    this.book,
    this.error,
    this.goal,
    this.location,
    this.tag,
  });
}

class RowError {
  final int rowNumber;
  final String reason;

  const RowError({required this.rowNumber, required this.reason});
}

/// What persisting one batch did to the library.
class ImportBatchOutcome {
  /// New books.
  final int inserted;

  /// Existing books that gained missing fields, tags, notes or sessions.
  final int updated;

  /// Existing books that already had everything the import offered.
  final int unchanged;

  const ImportBatchOutcome({
    this.inserted = 0,
    this.updated = 0,
    this.unchanged = 0,
  });
}

class ImportResult {
  /// New books added to the library.
  final int imported;

  /// Rows that were not added and did not change anything: invalid rows plus
  /// [duplicates].
  final int skipped;
  final List<RowError> errors;

  /// Rows that matched an existing book (same ISBN, or same title and
  /// authors) and enriched it with missing data instead of creating a copy.
  final int updated;

  /// Rows that matched an existing book which already had all of their data.
  /// Counted in [skipped] as well; they are not errors.
  final int duplicates;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
    this.updated = 0,
    this.duplicates = 0,
  });
}
