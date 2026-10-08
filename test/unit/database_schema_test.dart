import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('creates all tables on open', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(
      names,
      containsAll([
        'books',
        'locations',
        'series',
        'lending',
        'reading_sessions',
        'book_notes',
        'tags',
        'book_tags',
        'reading_goals',
      ]),
    );
  });

  test('schema version is 5', () {
    expect(db.schemaVersion, 5);
  });

  test('inserts and reads a book with 0.5-step rating', () async {
    final id = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Der Vorleser',
            isbn13: const Value('9783036950006'),
            authors: const ['Bernhard Schlink'],
            editedFields: const [],
            rating: const Value(3.5),
          ),
        );

    final book = await (db.select(
      db.books,
    )..where((t) => t.id.equals(id))).getSingle();

    expect(book.title, 'Der Vorleser');
    expect(book.authors, ['Bernhard Schlink']);
    expect(book.rating, 3.5);
    expect(book.status, BookStatus.unread);
  });

  test('enforces foreign keys on book.locationId', () async {
    // A book referencing a non-existent location must be rejected.
    expect(
      () => db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              title: 'Orphan',
              authors: const [],
              editedFields: const [],
              locationId: const Value(9999),
            ),
          ),
      throwsA(anything),
    );
  });

  test('cascades delete from book to lending rows', () async {
    final bookId = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'To Lend',
            authors: const ['A'],
            editedFields: const [],
          ),
        );
    await db
        .into(db.lending)
        .insert(
          LendingCompanion.insert(
            bookId: bookId,
            borrowerName: 'Anna',
            lentAt: DateTime(2026, 1, 1),
          ),
        );

    await (db.delete(db.books)..where((t) => t.id.equals(bookId))).go();

    final lending = await db.select(db.lending).get();
    expect(lending, isEmpty);
  });

  test('sets locationId to NULL when location is deleted', () async {
    final locId = await db
        .into(db.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Wohnzimmer',
            type: LocationType.room,
          ),
        );
    final bookId = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Placed',
            authors: const ['A'],
            editedFields: const [],
            locationId: Value(locId),
          ),
        );

    await (db.delete(db.locations)..where((t) => t.id.equals(locId))).go();

    final book = await (db.select(
      db.books,
    )..where((t) => t.id.equals(bookId))).getSingle();
    expect(book.locationId, isNull);
  });

  test('series name is unique', () async {
    await db
        .into(db.seriesTable)
        .insert(SeriesTableCompanion.insert(name: 'Die Sicht'));
    expect(
      () => db
          .into(db.seriesTable)
          .insert(SeriesTableCompanion.insert(name: 'Die Sicht')),
      throwsA(anything),
    );
  });
}
