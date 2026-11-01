import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/import_context.dart';
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
    // Trashed books (schema v3) are not part of the library.
    final select = db.select(db.books)..where((t) => t.deletedAt.isNull());
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
            t.deletedAt.isNull() &
            (t.title.like('%$q%') |
                t.subtitle.like('%$q%') |
                t.authors.like('%$q%') |
                t.isbn13.like('%$q%') |
                t.isbn10.like('%$q%')),
      );
    return select.get();
  }

  Future<Book?> getById(int id) =>
      (db.select(db.books)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Book>> getAll() =>
      (db.select(db.books)..where((t) => t.deletedAt.isNull())).get();

  /// Books in the trash, most recently deleted first.
  Stream<List<Book>> watchTrashed() =>
      (db.select(db.books)
            ..where((t) => t.deletedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
          .watch();

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
      final context = ImportContext(db);
      await context.load();

      var inserted = 0;
      var updated = 0;
      var unchanged = 0;

      for (final item in batch) {
        // Resolve the lookup tables first so the book row can reference them.
        final locationId = await context.location(item.locationPath);
        final seriesId = await context.series(
          item.seriesName,
          item.seriesTotalVolumes,
        );
        // `copyWith(x: Value.absent())` would overwrite the companion's own
        // value, so unresolved ids are passed as null (= keep).
        final incoming = item.book.copyWith(
          locationId: locationId == null ? null : Value(locationId),
          seriesId: seriesId == null ? null : Value(seriesId),
        );

        final existing = index.find(incoming);
        if (existing == null) {
          final bookId = await db.into(db.books).insert(incoming);
          index.put((await getById(bookId))!);
          await _addSatellites(bookId, item, context);
          inserted++;
          continue;
        }

        var changed = false;
        final patch = mergeMissingFields(existing, incoming);
        if (patch != null) {
          await update(existing.id, patch);
          index.put((await getById(existing.id))!);
          changed = true;
        }
        changed |= await _addSatellites(
          existing.id,
          item,
          context,
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

  /// Writes the locations, tags and goals that come with a backup independent
  /// of any book. An existing goal keeps its book target; a missing page target is
  /// filled in.
  Future<void> importExtras(ImportExtras extras) {
    return db.transaction(() async {
      final context = ImportContext(db);
      await context.load();
      for (final path in extras.locationPaths) {
        await context.location(path);
      }
      for (final name in extras.tags) {
        await context.tag(name);
      }
      for (final goal in extras.goals) {
        final existing = await (db.select(
          db.readingGoals,
        )..where((t) => t.year.equals(goal.year))).getSingleOrNull();
        if (existing == null) {
          await db
              .into(db.readingGoals)
              .insert(
                ReadingGoalsCompanion.insert(
                  year: Value(goal.year),
                  targetBooks: goal.targetBooks,
                  targetPages: Value(goal.targetPages),
                ),
              );
        } else if (existing.targetPages == null && goal.targetPages != null) {
          await (db.update(
            db.readingGoals,
          )..where((t) => t.year.equals(goal.year))).write(
            ReadingGoalsCompanion(targetPages: Value(goal.targetPages)),
          );
        }
      }
    });
  }

  /// Adds the tags, notes and sessions of [item] to [bookId]. When [merging],
  /// entries the book already has are left alone. Returns whether anything
  /// was added.
  Future<bool> _addSatellites(
    int bookId,
    ImportedBook item,
    ImportContext context, {
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
      final tagId = await context.tag(name);
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
              updatedAt: (note.updatedAt ?? note.createdAt) == null
                  ? const Value.absent()
                  : Value((note.updatedAt ?? note.createdAt)!),
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
      // A session always ends, unless an exact restore says it was running:
      // an open one shows up as the book's running timer.
      final endedAt = reading.open ? null : reading.finishedAt ?? startedAt;
      final key = (
        startedAt.millisecondsSinceEpoch ~/ 1000,
        endedAt == null ? null : endedAt.millisecondsSinceEpoch ~/ 1000,
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
              startPage: Value(reading.startPage),
              endPage: Value(reading.endPage),
            ),
          );
      added = true;
    }

    final knownLendings = merging
        ? {
            for (final l in await (db.select(
              db.lending,
            )..where((t) => t.bookId.equals(bookId))).get())
              (l.borrowerName, l.lentAt.millisecondsSinceEpoch ~/ 1000),
          }
        : <(String, int)>{};
    for (final lending in item.lendings) {
      if (!knownLendings.add((
        lending.borrowerName,
        lending.lentAt.millisecondsSinceEpoch ~/ 1000,
      ))) {
        continue;
      }
      await db
          .into(db.lending)
          .insert(
            LendingCompanion.insert(
              bookId: bookId,
              borrowerName: lending.borrowerName,
              lentAt: lending.lentAt,
              expectedReturn: Value(lending.expectedReturn),
              returnedAt: Value(lending.returnedAt),
            ),
          );
      added = true;
    }

    return added;
  }

  /// Moves books to the trash, a slipcase together with its volumes (same
  /// time, so a restore can tell them from volumes trashed earlier).
  /// Idempotent: an already trashed book keeps its original deletion time.
  Future<void> trash(List<int> ids, DateTime at) =>
      (db.update(db.books)..where(
            (t) =>
                (t.id.isIn(ids) | t.parentId.isIn(ids)) & t.deletedAt.isNull(),
          ))
          .write(BooksCompanion(deletedAt: Value(at)));

  /// Restores a book. A volume brings its slipcase back (an active volume
  /// needs an active slipcase); a slipcase brings back the volumes trashed
  /// with it.
  Future<void> restore(int id) => db.transaction(() async {
    final book = await getById(id);
    if (book == null) return;
    final parentId = book.parentId;
    if (parentId != null) await _restoreWithVolumes(parentId);
    await _restoreWithVolumes(id);
  });

  Future<void> _restoreWithVolumes(int id) async {
    final book = await getById(id);
    final at = book?.deletedAt;
    if (at == null) return;
    await (db.update(db.books)..where(
          (t) =>
              t.id.equals(id) |
              (t.parentId.equals(id) & t.deletedAt.equals(at)),
        ))
        .write(const BooksCompanion(deletedAt: Value<DateTime?>(null)));
  }

  /// Permanently deletes a book, a slipcase with its trashed volumes;
  /// sessions, notes, tag links and lending records go with it (foreign-key
  /// cascade).
  Future<int> purge(int id) =>
      (db.delete(db.books)..where(
            (t) =>
                t.id.equals(id) |
                (t.parentId.equals(id) & t.deletedAt.isNotNull()),
          ))
          .go();

  /// Trashes every active book and returns how many.
  Future<int> trashAll(DateTime at) =>
      (db.update(db.books)..where((t) => t.deletedAt.isNull())).write(
        BooksCompanion(deletedAt: Value(at)),
      );

  /// Permanently deletes every book (cascades to its satellites).
  Future<int> deleteAll() => db.delete(db.books).go();

  /// Permanently deletes everything in the trash and returns how many books.
  Future<int> emptyTrash() =>
      (db.delete(db.books)..where((t) => t.deletedAt.isNotNull())).go();

  Future<int> update(int id, BooksCompanion book) =>
      (db.update(db.books)..where((t) => t.id.equals(id))).write(book);

  Future<void> bulkSetFormat(List<int> ids, BookFormat? format) => (db.update(
    db.books,
  )..where((t) => t.id.isIn(ids))).write(BooksCompanion(format: Value(format)));

  Future<void> bulkSetAuthors(List<int> ids, List<String> authors) =>
      (db.update(db.books)..where((t) => t.id.isIn(ids))).write(
        BooksCompanion(authors: Value(authors)),
      );

  Future<void> bulkAssignLocation(List<int> ids, int? locationId) {
    return db.transaction(() async {
      await (db.update(db.books)..where((t) => t.id.isIn(ids))).write(
        BooksCompanion(locationId: Value(locationId)),
      );
    });
  }

  /// Whether a book with this ISBN-13 exists — trashed ones included, because
  /// the ISBN column is unique.
  Future<bool> isbnExists(String isbn13) async {
    final matches = await (db.select(
      db.books,
    )..where((t) => t.isbn13.equals(isbn13))).get();
    return matches.isNotEmpty;
  }
}
