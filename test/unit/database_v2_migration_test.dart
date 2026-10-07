import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';

import '../generated_migrations/schema.dart';

/// Verifies the v1 → v2 upgrade (Phase 2) against the committed schema dumps
/// in `drift_schemas/` (Constitution Article II.3 / IV.2).
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 → v2 produces exactly the v2 schema', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test(
    'v1 → v2 preserves every Phase 1 row and defaults new columns',
    () async {
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
      await verifier.migrateAndValidate(db, 2);

      final book = await db.select(db.books).getSingle();
      expect(book.title, 'Der Vorleser');
      expect(book.authors, ['Bernhard Schlink']);
      expect(book.rating, 4.5);
      expect(book.locationId, 1);
      expect(book.seriesId, 1);
      expect(book.editedFields, ['title']);
      expect(book.currentPage, 0);
      expect(book.finishedAt, isNull);
      expect(
        book.isFavorite,
        isFalse,
        reason: 'added column defaults to false',
      );
      expect(book.review, isNull);

      expect((await db.select(db.locations).get()).single.name, 'Wohnzimmer');
      expect((await db.select(db.lending).get()).single.borrowerName, 'Anna');
      expect(await db.select(db.readingSessions).get(), isEmpty);
      expect(await db.select(db.bookNotes).get(), isEmpty);
      expect(await db.select(db.tags).get(), isEmpty);
    },
  );
}
