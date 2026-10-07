import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
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

  /// Persists imported books together with their tags, notes and reading
  /// sessions (schema v2) in ONE transaction: any failure rolls the whole batch
  /// back, so no book is left half-imported.
  Future<int> insertImported(List<ImportedBook> batch) {
    return db.transaction(() async {
      // Tag names are matched case-insensitively in Dart: SQLite's lower()
      // only folds ASCII, so `Übernatürliches` would never match itself.
      final tagIds = <String, int>{
        for (final tag in await db.select(db.tags).get())
          tag.name.toLowerCase(): tag.id,
      };

      for (final item in batch) {
        final bookId = await db.into(db.books).insert(item.book);

        for (final name in item.tags) {
          final key = name.toLowerCase();
          final tagId = tagIds[key] ??= await db
              .into(db.tags)
              .insert(TagsCompanion.insert(name: name));
          await db
              .into(db.bookTags)
              .insert(
                BookTagsCompanion.insert(bookId: bookId, tagId: tagId),
                mode: InsertMode.insertOrIgnore,
              );
        }

        for (final note in item.notes) {
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
        }

        for (final reading in item.readings) {
          final startedAt =
              reading.startedAt ?? reading.finishedAt ?? DateTime.now();
          await db
              .into(db.readingSessions)
              .insert(
                ReadingSessionsCompanion.insert(
                  bookId: bookId,
                  startedAt: startedAt,
                  // A session always ends: an open one would show up as the
                  // book's running timer.
                  endedAt: Value(reading.finishedAt ?? startedAt),
                  durationSeconds: Value(reading.duration?.inSeconds ?? 0),
                ),
              );
        }
      }
      return batch.length;
    });
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
