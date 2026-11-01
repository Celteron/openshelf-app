import 'package:drift/drift.dart';
import 'package:openreads/data/database/tables.dart';
import 'package:openreads/domain/models/enums.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Books,
    Locations,
    SeriesTable,
    Lending,
    ReadingSessions,
    BookNotes,
    Tags,
    BookTags,
    ReadingGoals,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Stepwise, backward-compatible migrations ONLY. No destructive ops.
      if (from < 2) {
        // v2 (Phase 2): reading progress, notes/quotes, tags, yearly goal.
        await m.addColumn(books, books.currentPage);
        await m.addColumn(books, books.finishedAt);
        await m.addColumn(books, books.isFavorite);
        await m.addColumn(books, books.review);
        await m.createTable(readingSessions);
        await m.createTable(bookNotes);
        await m.createTable(tags);
        await m.createTable(bookTags);
        await m.createTable(readingGoals);
        await m.createIndex(idxReadingSessionsBook);
        await m.createIndex(idxBookNotesBook);
      }
      if (from < 3) {
        // v3 (legacy parity): Open Library id and soft delete (trash).
        await m.addColumn(books, books.olid);
        await m.addColumn(books, books.deletedAt);
      }
      if (from < 4) {
        // v4 (feedback round 1): genre, purchase price, received date.
        await m.addColumn(books, books.genre);
        await m.addColumn(books, books.priceCents);
        await m.addColumn(books, books.receivedAt);
      }
      if (from < 5) {
        // v5: reading time entered without a dated session.
        await m.addColumn(books, books.readingSeconds);
      }
      if (from < 6) {
        // v6 (feedback round 2): received as, cover-search flag, slipcases.
        await m.addColumn(books, books.receivedAs);
        await m.addColumn(books, books.coverNotFound);
        await m.addColumn(books, books.parentId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
