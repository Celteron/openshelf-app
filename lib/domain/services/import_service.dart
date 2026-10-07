import 'package:drift/drift.dart';
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
  static const _batchSize = 500;

  final BookRepository _repository;

  ImportService(this._repository);

  Future<ImportResult> import(Stream<ImportRow> rows) async {
    final tally = _Tally();
    final pending = <ImportedBook>[];

    await for (final row in rows) {
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

      pending.add(_toImported(book));

      if (pending.length >= _batchSize) {
        final ok = await _flush(pending, tally);
        if (!ok) return tally.result();
        pending.clear();
      }
    }

    if (pending.isNotEmpty) await _flush(pending, tally);
    return tally.result();
  }

  /// Returns `false` when the batch failed (and was rolled back).
  Future<bool> _flush(List<ImportedBook> batch, _Tally tally) async {
    try {
      final outcome = await _repository.importBatch(batch);
      tally.imported += outcome.inserted;
      tally.updated += outcome.updated;
      tally.duplicates += outcome.unchanged;
      tally.skipped += outcome.unchanged;
      return true;
    } catch (e) {
      // The transaction has rolled back; no partial books from this batch.
      tally.skipped += batch.length;
      tally.errors.add(RowError(rowNumber: 0, reason: 'Critical failure: $e'));
      return false;
    }
  }

  /// Maps a parsed row to a persistable book plus its Schema v2 satellites.
  ///
  /// Reading progress is derived, never invented: a book imported as `read`
  /// is marked as fully read (`currentPage` = page count) and gets the latest
  /// recorded finish date as `finishedAt`, so the yearly goal counts it in the
  /// right year. Imported sessions carry no page range.
  ImportedBook _toImported(BookImport book) {
    final status = book.status ?? BookStatus.unread;
    final pages = book.pageCount;
    final finishDates = book.readings
        .map((r) => r.finishedAt)
        .whereType<DateTime>();
    final isRead = status == BookStatus.read;

    final companion = BooksCompanion.insert(
      title: book.title!.trim(),
      authors: book.authors,
      editedFields: const [],
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
      rating: Value(normalizeRating(book.rating)),
      status: Value(status),
      isFavorite: Value(book.isFavorite),
      review: Value(_blankToNull(book.review)),
      currentPage: Value(isRead && pages != null && pages > 0 ? pages : 0),
      finishedAt: Value(
        isRead && finishDates.isNotEmpty
            ? finishDates.reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      ),
      createdAt: book.addedAt == null
          ? const Value.absent()
          : Value(book.addedAt!),
      updatedAt: book.addedAt == null
          ? const Value.absent()
          : Value(book.addedAt!),
    );

    return ImportedBook(
      book: companion,
      tags: book.tags,
      notes: book.notes,
      readings: book.readings.where((r) => !r.isEmpty).toList(),
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

  ImportResult result() => ImportResult(
    imported: imported,
    skipped: skipped,
    errors: errors,
    updated: updated,
    duplicates: duplicates,
  );
}
