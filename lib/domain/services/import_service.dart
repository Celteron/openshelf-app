import 'package:drift/drift.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

/// Persists a parsed import stream in chunked transactions, collects per-row
/// errors, and rolls back the current transaction on a critical failure
/// (Constitution Article III/IV, spec FR-012).
///
/// Re-importing is safe: a row that matches an existing book (ISBN-13, ISBN-10
/// or identical title and authors) never creates a copy. If the row has data
/// the book lacks (fields, tags, notes, reading sessions) the book is
/// *updated*; if not, the row is a skipped *duplicate*. Existing data is never
/// overwritten.
class ImportService {
  // Also the progress step: the bar moves once a batch is written. Small
  // enough for a smooth bar, large enough to keep transactions few.
  static const _batchSize = 100;

  final BookRepository _repository;

  /// Stores cover images that ship with an import (legacy backups).
  final CoverCacheService? _covers;

  ImportService(this._repository, {CoverCacheService? coverCache})
    : _covers = coverCache;

  /// [onProgress] gets the number of rows handled so far, skipped ones
  /// included, each time a batch is written and once at the end, so a caller
  /// that knows the row count can show a progress bar that matches the writes.
  Future<ImportResult> import(
    Stream<ImportRow> rows, {
    void Function(int handled)? onProgress,
  }) async {
    final tally = _Tally();
    final pending = <ImportedBook>[];
    final extraLocations = <List<LocationRef>>[];
    final extraGoals = <GoalImport>[];
    final extraTags = <String>[];
    final extraTiles = <StatTileImport>[];

    var handled = 0;
    await for (final row in rows) {
      handled++;
      // Backup rows that are not books: standalone locations and yearly goals.
      if (row.goal != null) {
        extraGoals.add(row.goal!);
        continue;
      }
      if (row.location != null) {
        extraLocations.add(row.location!);
        continue;
      }
      if (row.tag != null) {
        extraTags.add(row.tag!);
        continue;
      }
      if (row.tile != null) {
        extraTiles.add(row.tile!);
        continue;
      }
      if (row.error != null) {
        tally.skipped++;
        tally.errors.add(
          RowError(rowNumber: row.rowNumber, reason: row.error!),
        );
        continue;
      }

      final book = row.book!;
      if (book.title == null || book.title!.trim().isEmpty) {
        tally.skipped++;
        tally.errors.add(
          RowError(rowNumber: row.rowNumber, reason: 'Missing title'),
        );
        continue;
      }

      pending.add(await _toImported(book, row.rowNumber));

      if (pending.length >= _batchSize) {
        final ok = await _flush(pending, tally);
        if (!ok) return tally.result();
        pending.clear();
        // Reported after the write, so the bar never runs ahead of it.
        onProgress?.call(handled);
      }
    }

    if (pending.isNotEmpty) await _flush(pending, tally);
    final extras = ImportExtras(
      locationPaths: extraLocations,
      goals: extraGoals,
      tags: extraTags,
      tiles: extraTiles,
    );
    if (!extras.isEmpty) {
      try {
        await _repository.importExtras(extras);
      } catch (e) {
        tally.errors.add(
          RowError(
            rowNumber: 0,
            reason: 'Could not restore goals/locations: $e',
          ),
        );
      }
    }
    onProgress?.call(handled);
    return tally.result();
  }

  /// Returns `false` when the batch failed (and was rolled back).
  Future<bool> _flush(List<ImportedBook> batch, _Tally tally) async {
    try {
      final outcome = await _repository.importBatch(
        batch,
        knownIds: tally.keyedIds,
      );
      tally.imported += outcome.inserted;
      tally.updated += outcome.updated;
      tally.duplicates += outcome.unchanged;
      tally.skipped += outcome.unchanged;
      tally.keyedIds.addAll(outcome.keyedIds);
      for (final row in outcome.orphanRows) {
        tally.errors.add(
          RowError(
            rowNumber: row,
            reason: 'Slipcase not found; imported as a single book',
          ),
        );
      }
      return true;
    } catch (e) {
      // The transaction has rolled back; no partial books from this batch.
      tally.skipped += batch.length;
      tally.errors.add(RowError(rowNumber: 0, reason: 'Critical failure: $e'));
      return false;
    }
  }

  /// Maps a parsed row to a persistable book plus its Schema v2/v3 satellites.
  ///
  /// Reading progress is derived, never invented: a book imported as `read`
  /// is marked as fully read (`currentPage` = page count) and gets the latest
  /// recorded finish date as `finishedAt`, so the yearly goal counts it in the
  /// right year. Imported sessions carry no page range. Explicit values from
  /// the source (`currentPage`, `finishedAt`) win; an `exact` restore (an
  /// OpenShelf backup) takes the row exactly as it is.
  Future<ImportedBook> _toImported(BookImport book, int rowNumber) async {
    final status = book.status ?? BookStatus.unread;
    final pages = book.pageCount;
    final finishDates = book.readings
        .map((r) => r.finishedAt)
        .whereType<DateTime>();
    final isRead = status == BookStatus.read;

    final int currentPage;
    final DateTime? finishedAt;
    if (book.exact) {
      currentPage = book.currentPage ?? 0;
      finishedAt = book.finishedAt;
    } else {
      currentPage =
          book.currentPage ??
          (isRead && pages != null && pages > 0 ? pages : 0);
      finishedAt =
          book.finishedAt ??
          (isRead && finishDates.isNotEmpty
              ? finishDates.reduce((a, b) => a.isAfter(b) ? a : b)
              : null);
    }

    String? coverLocalPath;
    final coverBytes = book.coverBytes;
    if (coverBytes != null && coverBytes.isNotEmpty && _covers != null) {
      try {
        coverLocalPath = await _covers.saveCover(
          'import-${DateTime.now().microsecondsSinceEpoch}-$rowNumber',
          coverBytes,
        );
      } on FormatException {
        // A broken cover in a backup must not cost the book itself.
      }
    }

    final companion = BooksCompanion.insert(
      title: book.title!.trim(),
      authors: book.authors,
      editedFields: book.editedFields,
      isbn13: Value(book.isbn13),
      isbn10: Value(book.isbn10),
      subtitle: Value(book.subtitle),
      publisher: Value(book.publisher),
      publishedYear: Value(book.publishedYear),
      pageCount: Value(book.pageCount),
      format: Value(book.format),
      language: Value(book.language),
      description: Value(book.description),
      coverUrl: Value(book.coverUrl),
      coverLocalPath: Value(coverLocalPath),
      olid: Value(book.olid),
      genre: Value(_blankToNull(book.genre)),
      priceCents: Value(book.priceCents),
      receivedAt: Value(book.receivedAt),
      receivedAs: Value(book.receivedAs),
      readingSeconds: Value(book.readingSeconds),
      metadataSource: Value(book.metadataSource),
      seriesVolume: Value(book.seriesVolume),
      rating: Value(normalizeRating(book.rating)),
      status: Value(status),
      isFavorite: Value(book.isFavorite),
      review: Value(_blankToNull(book.review)),
      currentPage: Value(currentPage),
      finishedAt: Value(finishedAt),
      deletedAt: Value(book.deletedAt),
      createdAt: book.addedAt == null
          ? const Value.absent()
          : Value(book.addedAt!),
      updatedAt: (book.updatedAt ?? book.addedAt) == null
          ? const Value.absent()
          : Value((book.updatedAt ?? book.addedAt)!),
    );

    return ImportedBook(
      book: companion,
      tags: book.tags,
      notes: book.notes,
      readings: book.readings.where((r) => !r.isEmpty).toList(),
      locationPath: book.locationPath,
      seriesName: book.seriesName,
      seriesTotalVolumes: book.seriesTotalVolumes,
      lendings: book.lendings,
      sourceKey: book.sourceKey,
      parentSourceKey: book.parentSourceKey,
      rowNumber: rowNumber,
    );
  }

  String? _blankToNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class _Tally {
  int imported = 0;
  int updated = 0;
  int skipped = 0;
  int duplicates = 0;
  final errors = <RowError>[];

  /// Source key → library id over all batches (slipcase links).
  final keyedIds = <String, int>{};

  ImportResult result() => ImportResult(
    imported: imported,
    skipped: skipped,
    errors: errors,
    updated: updated,
    duplicates: duplicates,
  );
}
