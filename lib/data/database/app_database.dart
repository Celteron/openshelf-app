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
  int get schemaVersion => 2;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
