import 'package:drift_dev/api/migrations_native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

import '../generated_migrations/schema.dart';

/// Upgrades to the current schema (v3) from every earlier version, checked
/// against the committed schema dumps in `drift_schemas/` with drift's
/// `SchemaVerifier` (Constitution Article II.3 / IV.2).
///
/// v1 → v2 added reading progress, notes, tags, goals, favourite and review;
/// v2 → v3 added the Open Library id and the trash (`deleted_at`).
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the current schema version is 3', () {
    expect(AppDatabase(NativeDatabase.memory()).schemaVersion, 3);
  });

  group('v1 → v3', () {
    test('produces exactly the v3 schema', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    });

    test('preserves every Phase 1 row and defaults the new columns', () async {
      final schema = await verifier.schemaAt(1);

      schema.rawDatabase.execute('''
        INSERT INTO locations (id, name, type, sort_order)
        VALUES (1, 'Wohnzimmer', 'room', 0);
      ''');
      schema.rawDatabase.execute('''
        INSERT INTO series (id, name) VALUES (1, 'Reihe');
      ''');
      schema.rawDatabase.execute('''
        INSERT INTO books
          (id, isbn13, title, authors, status, rating, location_id, series_id,
           edited_fields, created_at, updated_at)
        VALUES
          (1, '9783442719255', 'Der Vorleser', '["Bernhard Schlink"]', 'read',
           4.5, 1, 1, '["title"]', 1700000000, 1700000000);
      ''');
      schema.rawDatabase.execute('''
        INSERT INTO lending (id, book_id, borrower_name, lent_at)
        VALUES (1, 1, 'Anna', 1700000000);
      ''');

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      final book = await db.select(db.books).getSingle();
      expect(book.title, 'Der Vorleser');
      expect(book.authors, ['Bernhard Schlink']);
      expect(book.rating, 4.5);
      expect(book.locationId, 1);
      expect(book.seriesId, 1);
      expect(book.editedFields, ['title']);
      // v2 columns
      expect(book.currentPage, 0);
      expect(book.finishedAt, isNull);
      expect(book.isFavorite, isFalse);
      expect(book.review, isNull);
      // v3 columns
      expect(book.olid, isNull);
      expect(book.deletedAt, isNull, reason: 'existing books stay visible');

      expect((await db.select(db.locations).get()).single.name, 'Wohnzimmer');
      expect((await db.select(db.lending).get()).single.borrowerName, 'Anna');
      expect(await db.select(db.readingSessions).get(), isEmpty);
      expect(await db.select(db.bookNotes).get(), isEmpty);
      expect(await db.select(db.tags).get(), isEmpty);
    });
  });

  group('v2 → v3', () {
    test('produces exactly the v3 schema', () async {
      final schema = await verifier.schemaAt(2);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    });

    test(
      'preserves Phase 2 data and adds the trash and Open Library id',
      () async {
        final schema = await verifier.schemaAt(2);

        schema.rawDatabase.execute('''
        INSERT INTO books
          (id, isbn13, title, authors, status, rating, edited_fields,
           current_page, finished_at, is_favorite, review, created_at,
           updated_at)
        VALUES
          (1, '9783442719255', 'Der Vorleser', '["Bernhard Schlink"]', 'read',
           4.5, '[]', 200, 1700000500, 1, 'Stark', 1700000000, 1700000000);
      ''');
        schema.rawDatabase.execute('''
        INSERT INTO reading_sessions
          (id, book_id, started_at, ended_at, duration_seconds, start_page,
           end_page)
        VALUES (1, 1, 1700000000, 1700003600, 3600, 0, 200);
      ''');
        schema.rawDatabase.execute('''
        INSERT INTO book_notes (id, book_id, kind, content, created_at, updated_at)
        VALUES (1, 1, 'quote', 'Zitat', 1700000000, 1700000000);
      ''');
        schema.rawDatabase.execute('''
        INSERT INTO tags (id, name) VALUES (1, 'Klassiker');
      ''');
        schema.rawDatabase.execute('''
        INSERT INTO book_tags (book_id, tag_id) VALUES (1, 1);
      ''');
        schema.rawDatabase.execute('''
        INSERT INTO reading_goals (year, target_books, target_pages)
        VALUES (2026, 24, 8000);
      ''');

        final db = AppDatabase(schema.newConnection());
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, 3);

        final book = await db.select(db.books).getSingle();
        expect(book.title, 'Der Vorleser');
        expect(book.currentPage, 200);
        expect(book.isFavorite, isTrue);
        expect(book.review, 'Stark');
        expect(book.finishedAt, isNotNull);
        expect(book.olid, isNull);
        expect(book.deletedAt, isNull);

        expect(
          (await db.select(db.readingSessions).getSingle()).durationSeconds,
          3600,
        );
        expect(
          (await db.select(db.bookNotes).getSingle()).kind,
          NoteKind.quote,
        );
        expect((await db.select(db.tags).getSingle()).name, 'Klassiker');
        expect(await db.select(db.bookTags).get(), hasLength(1));
        final goal = await db.select(db.readingGoals).getSingle();
        expect((goal.targetBooks, goal.targetPages), (24, 8000));
      },
    );

    test('the migrated database can use the trash', () async {
      final schema = await verifier.schemaAt(2);
      schema.rawDatabase.execute('''
        INSERT INTO books (id, title, authors, status, rating, edited_fields,
                           current_page, is_favorite, created_at, updated_at)
        VALUES (1, 'Buch', '[]', 'unread', 0, '[]', 0, 0, 1700000000, 1700000000);
      ''');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      await (db.update(
        db.books,
      )).write(BooksCompanion(deletedAt: Value(DateTime(2026))));

      expect((await db.select(db.books).getSingle()).deletedAt, DateTime(2026));
    });
  });
}
