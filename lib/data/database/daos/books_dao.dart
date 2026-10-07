import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/import_merge.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

class BooksDao {
  final AppDatabase db;
  BooksDao(this.db);

  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) {
    final select = db.select(db.books);
    if (status != null) {
      select.where((t) => t.status.equalsValue(status));
    }
    if (locationId != null) {
      select.where((t) => t.locationId.equals(locationId));
    }
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      select.where(
        (t) =>
            t.title.like('%$q%') |
            t.subtitle.like('%$q%') |
            t.authors.like('%$q%') |
            t.isbn13.like('%$q%') |
            t.isbn10.like('%$q%'),
      );
    }
    return select.watch();
  }

  Future<List<Book>> search(String query) {
    final q = query.trim();
    final select = db.select(db.books)
      ..where(
        (t) =>
            t.title.like('%$q%') |
            t.subtitle.like('%$q%') |
            t.authors.like('%$q%') |
            t.isbn13.like('%$q%') |
            t.isbn10.like('%$q%'),
      );
    return select.get();
  }

  Future<Book?> getById(int id) =>
      (db.select(db.books)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Book>> getAll() => db.select(db.books).get();

  Future<int> insert(BooksCompanion book) => db.into(db.books).insert(book);

  Future<int> insertAll(List<BooksCompanion> books) async {
    await db.transaction(() async {
      await db.batch((batch) {
        batch.insertAll(db.books, books);
      });
    });
    return books.length;
  }

  /// Persists an import batch in ONE transaction: any failure rolls the whole
  /// batch back, so no book is left half-imported.
  ///
  /// Rows matching an existing book are merged into it ([mergeMissingFields],
  /// plus tags, notes and sessions it does not have yet); the rest is inserted.
  /// Matching also sees books inserted earlier in the same batch, so duplicates
  /// inside one file collapse as well.
  Future<ImportBatchOutcome> importBatch(List<ImportedBook> batch) {
    return db.transaction(() async {
      final index = BookMatchIndex(await db.select(db.books).get());
      // Tag names are matched case-insensitively in Dart: SQLite's lower()
      // only folds ASCII, so `Übernatürliches` would never match itself.
      final tagIds = <String, int>{
        for (final tag in await db.select(db.tags).get())
          tag.name.toLowerCase(): tag.id,
      };

      var inserted = 0;
      var updated = 0;
      var unchanged = 0;

      for (final item in batch) {
        final existing = index.find(item.book);
        if (existing == null) {
          final bookId = await db.into(db.books).insert(item.book);
          index.put((await getById(bookId))!);
          await _addSatellites(bookId, item, tagIds);
          inserted++;
          continue;
        }

        var changed = false;
        final patch = mergeMissingFields(existing, item.book);
        if (patch != null) {
          await update(existing.id, patch);
          index.put((await getById(existing.id))!);
          changed = true;
        }
        changed |= await _addSatellites(
          existing.id,
          item,
          tagIds,
          merging: true,
        );
        changed ? updated++ : unchanged++;
      }

      return ImportBatchOutcome(
        inserted: inserted,
        updated: updated,
        unchanged: unchanged,
      );
    });
  }

  /// Adds the tags, notes and sessions of [item] to [bookId]. When [merging],
  /// entries the book already has are left alone. Returns whether anything
  /// was added.
  Future<bool> _addSatellites(
    int bookId,
    ImportedBook item,
    Map<String, int> tagIds, {
    bool merging = false,
  }) async {
    var added = false;

    final linkedTags = merging
        ? {
            for (final link in await (db.select(
              db.bookTags,
            )..where((t) => t.bookId.equals(bookId))).get())
              link.tagId,
          }
        : <int>{};
    for (final name in item.tags) {
      final tagId = tagIds[name.toLowerCase()] ??= await db
          .into(db.tags)
          .insert(TagsCompanion.insert(name: name));
      if (!linkedTags.add(tagId)) continue;
      await db
          .into(db.bookTags)
          .insert(BookTagsCompanion.insert(bookId: bookId, tagId: tagId));
      added = true;
    }

    final knownNotes = merging
        ? {
            for (final n in await (db.select(
              db.bookNotes,
            )..where((t) => t.bookId.equals(bookId))).get())
              n.content.trim(),
          }
        : <String>{};
    for (final note in item.notes) {
      if (!knownNotes.add(note.content.trim())) continue;
      await db
          .into(db.bookNotes)
          .insert(
            BookNotesCompanion.insert(
              bookId: bookId,
              kind: note.kind,
              content: note.content,
              pageNumber: Value(note.pageNumber),
              createdAt: note.createdAt == null
                  ? const Value.absent()
                  : Value(note.createdAt!),
              updatedAt: note.createdAt == null
                  ? const Value.absent()
                  : Value(note.createdAt!),
            ),
          );
      added = true;
    }

    final knownSessions = merging
        ? {
            for (final s in await (db.select(
              db.readingSessions,
            )..where((t) => t.bookId.equals(bookId))).get())
              (
                s.startedAt.millisecondsSinceEpoch ~/ 1000,
                s.endedAt?.millisecondsSinceEpoch == null
                    ? null
                    : s.endedAt!.millisecondsSinceEpoch ~/ 1000,
              ),
          }
        : <(int, int?)>{};
    for (final reading in item.readings) {
      final startedAt =
          reading.startedAt ?? reading.finishedAt ?? DateTime.now();
      // A session always ends: an open one would show up as the book's
      // running timer.
      final endedAt = reading.finishedAt ?? startedAt;
      final key = (
        startedAt.millisecondsSinceEpoch ~/ 1000,
        endedAt.millisecondsSinceEpoch ~/ 1000,
      );
      if (!knownSessions.add(key)) continue;
      await db
          .into(db.readingSessions)
          .insert(
            ReadingSessionsCompanion.insert(
              bookId: bookId,
              startedAt: startedAt,
              endedAt: Value(endedAt),
              durationSeconds: Value(reading.duration?.inSeconds ?? 0),
            ),
          );
      added = true;
    }

    return added;
  }

  Future<int> delete(int id) =>
      (db.delete(db.books)..where((t) => t.id.equals(id))).go();

  Future<int> update(int id, BooksCompanion book) =>
      (db.update(db.books)..where((t) => t.id.equals(id))).write(book);

  Future<void> bulkAssignLocation(List<int> ids, int? locationId) {
    return db.transaction(() async {
      await (db.update(db.books)..where((t) => t.id.isIn(ids))).write(
        BooksCompanion(locationId: Value(locationId)),
      );
    });
  }

  Future<bool> isbnExists(String isbn13) async {
    final matches = await (db.select(
      db.books,
    )..where((t) => t.isbn13.equals(isbn13))).get();
    return matches.isNotEmpty;
  }
}
