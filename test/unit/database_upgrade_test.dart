import 'package:drift_dev/api/migrations_native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

import '../generated_migrations/schema.dart';

/// Upgrades to the current schema (v6) from every earlier version, checked
/// against the committed schema dumps in `drift_schemas/` with drift's
/// `SchemaVerifier` (Constitution Article II.3 / IV.2).
///
/// v1 → v2 added reading progress, notes, tags, goals, favourite and review;
/// v2 → v3 added the Open Library id and the trash (`deleted_at`);
/// v3 → v4 added genre, price (cents) and the received date;
/// v4 → v5 added the manually entered reading time (`reading_seconds`);
/// v5 → v6 added "received as", the cover-search flag and the slipcase link
/// (`received_as`, `cover_not_found`, `parent_id`).
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the current schema version is 7', () {
    expect(AppDatabase(NativeDatabase.memory()).schemaVersion, 7);
  });

  group('v6 → v7', () {
    test('produces exactly the v7 schema', () async {
      final schema = await verifier.schemaAt(6);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);
    });

    test('keeps every book; the statistic tiles start empty', () async {
      final schema = await verifier.schemaAt(6);
      schema.rawDatabase.execute('''
        INSERT INTO books
          (id, title, authors, status, rating, edited_fields, current_page,
           is_favorite, cover_not_found, created_at, updated_at)
        VALUES
          (1, 'Buch', '["A"]', 'read', 4.5, '[]', 0, 0, 0,
           1700000000, 1700000000);
      ''');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);

      final books = await db.select(db.books).get();
      expect(books.single.title, 'Buch');
      expect(await db.select(db.statTiles).get(), isEmpty);
    });
  });

  group('v1 → v6', () {
    test('produces exactly the v6 schema', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);
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
      await verifier.migrateAndValidate(db, 7);

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
      // v4 columns
      expect(book.genre, isNull);
      expect(book.priceCents, isNull);
      expect(book.receivedAt, isNull);

      expect((await db.select(db.locations).get()).single.name, 'Wohnzimmer');
      expect((await db.select(db.lending).get()).single.borrowerName, 'Anna');
      expect(await db.select(db.readingSessions).get(), isEmpty);
      expect(await db.select(db.bookNotes).get(), isEmpty);
      expect(await db.select(db.tags).get(), isEmpty);
    });
  });

  group('v2 → v6', () {
    test('produces exactly the v6 schema', () async {
      final schema = await verifier.schemaAt(2);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);
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
        await verifier.migrateAndValidate(db, 7);

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
      await verifier.migrateAndValidate(db, 7);

      await (db.update(
        db.books,
      )).write(BooksCompanion(deletedAt: Value(DateTime(2026))));

      expect((await db.select(db.books).getSingle()).deletedAt, DateTime(2026));
    });
  });
  group('v3 → v6', () {
    test('produces exactly the v6 schema', () async {
      final schema = await verifier.schemaAt(3);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);
    });

    test('keeps every book and leaves genre, price and date empty', () async {
      final schema = await verifier.schemaAt(3);
      schema.rawDatabase.execute('''
        INSERT INTO books
          (id, isbn13, title, authors, status, rating, edited_fields,
           current_page, is_favorite, olid, created_at, updated_at)
        VALUES
          (1, '9783442719255', 'Der Vorleser', '["Bernhard Schlink"]', 'read',
           4.5, '["title"]', 200, 1, 'OL1M', 1700000000, 1700000000);
      ''');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);

      final book = await db.select(db.books).getSingle();
      expect(book.title, 'Der Vorleser');
      expect(book.olid, 'OL1M');
      expect(book.editedFields, ['title']);
      expect(book.genre, isNull);
      expect(book.priceCents, isNull);
      expect(book.receivedAt, isNull);
    });

    test(
      'the migrated database stores genre, price and received date',
      () async {
        final schema = await verifier.schemaAt(3);
        schema.rawDatabase.execute('''
        INSERT INTO books (id, title, authors, status, rating, edited_fields,
                           current_page, is_favorite, created_at, updated_at)
        VALUES (1, 'Buch', '[]', 'unread', 0, '[]', 0, 0, 1700000000, 1700000000);
      ''');
        final db = AppDatabase(schema.newConnection());
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, 7);

        await (db.update(db.books)).write(
          BooksCompanion(
            genre: const Value('Krimi'),
            priceCents: const Value(1299),
            receivedAt: Value(DateTime(2025, 12, 24)),
          ),
        );

        final book = await db.select(db.books).getSingle();
        expect(
          (book.genre, book.priceCents, book.receivedAt),
          ('Krimi', 1299, DateTime(2025, 12, 24)),
        );
      },
    );
  });

  group('v4 → v6', () {
    test('produces exactly the v6 schema', () async {
      final schema = await verifier.schemaAt(4);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);
    });

    test('keeps genre, price and date; reading time starts empty', () async {
      final schema = await verifier.schemaAt(4);
      schema.rawDatabase.execute('''
        INSERT INTO books
          (id, title, authors, status, rating, edited_fields, current_page,
           is_favorite, genre, price_cents, received_at, created_at, updated_at)
        VALUES
          (1, 'Buch', '[]', 'read', 0, '[]', 0, 0, 'Krimi', 1290, 1700000000,
           1700000000, 1700000000);
      ''');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);

      final book = await db.select(db.books).getSingle();
      expect((book.genre, book.priceCents), ('Krimi', 1290));
      expect(book.receivedAt, isNotNull);
      expect(book.readingSeconds, isNull);

      await (db.update(
        db.books,
      )).write(const BooksCompanion(readingSeconds: Value(19800)));
      expect((await db.select(db.books).getSingle()).readingSeconds, 19800);
    });
  });

  group('v5 → v6', () {
    test('produces exactly the v6 schema', () async {
      final schema = await verifier.schemaAt(5);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);
    });

    test('keeps every v5 value; the new columns start empty', () async {
      final schema = await verifier.schemaAt(5);
      schema.rawDatabase.execute('''
        INSERT INTO books
          (id, title, authors, status, rating, edited_fields, current_page,
           is_favorite, genre, price_cents, received_at, reading_seconds,
           created_at, updated_at)
        VALUES
          (1, 'Buch', '["A"]', 'read', 4.5, '[]', 120, 1, 'Krimi', 1290,
           1700000000, 19800, 1700000000, 1700000000);
      ''');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 7);

      final book = await db.select(db.books).getSingle();
      expect(
        (book.title, book.rating, book.currentPage, book.isFavorite),
        ('Buch', 4.5, 120, true),
      );
      expect(
        (book.genre, book.priceCents, book.readingSeconds),
        ('Krimi', 1290, 19800),
      );
      expect(book.receivedAs, isNull);
      expect(book.coverNotFound, isFalse);
      expect(book.parentId, isNull);
    });

    test('stores "received as" as its pinned code', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final value in ReceivedAs.values) {
        await db.delete(db.books).go();
        await db
            .into(db.books)
            .insert(
              BooksCompanion.insert(
                title: 'B',
                authors: const [],
                editedFields: const [],
                receivedAs: Value(value),
              ),
            );
        final raw = await db
            .customSelect('SELECT received_as FROM books')
            .getSingle();
        expect(raw.read<int>('received_as'), value.code);
        expect((await db.select(db.books).getSingle()).receivedAs, value);
      }
    });

    test(
      'a volume needs an existing slipcase and survives its deletion',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        Future<int> add(String title, {int? parent}) => db
            .into(db.books)
            .insert(
              BooksCompanion.insert(
                title: title,
                authors: const [],
                editedFields: const [],
                parentId: Value(parent),
              ),
            );

        await expectLater(add('Waise', parent: 999), throwsA(anything));

        final box = await add('Schuber');
        await add('Band 1', parent: box);
        await add('Band 2', parent: box);
        await (db.delete(db.books)..where((b) => b.id.equals(box))).go();

        final volumes = await db.select(db.books).get();
        expect(volumes.map((b) => b.title), ['Band 1', 'Band 2']);
        expect(volumes.map((b) => b.parentId), [null, null]);
      },
    );

    test('volumes without an ISBN do not collide', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final title in ['Band 1', 'Band 2']) {
        await db
            .into(db.books)
            .insert(
              BooksCompanion.insert(
                title: title,
                authors: const [],
                editedFields: const [],
              ),
            );
      }
      expect(await db.select(db.books).get(), hasLength(2));
    });
  });
}
