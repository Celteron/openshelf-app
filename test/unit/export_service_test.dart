import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/domain/models/enums.dart';

void main() {
  late AppDatabase db;
  late ExportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ExportService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('exports books, locations, series, and lending as JSON', () async {
    final locId = await db
        .into(db.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Wohnzimmer',
            type: LocationType.room,
          ),
        );
    final seriesId = await db
        .into(db.seriesTable)
        .insert(SeriesTableCompanion.insert(name: 'Die Reihe'));
    final bookId = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Der Vorleser',
            authors: const ['Schlink'],
            editedFields: const [],
            locationId: Value(locId),
            seriesId: Value(seriesId),
            rating: const Value(3.5),
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

    final json = jsonDecode(await service.exportJson()) as Map<String, dynamic>;

    expect(json['books'], hasLength(1));
    expect(json['locations'], hasLength(1));
    expect(json['series'], hasLength(1));
    expect(json['lending'], hasLength(1));

    final book = (json['books'] as List).single as Map<String, dynamic>;
    expect(book['title'], 'Der Vorleser');
    expect(book['status'], 'unread');
    expect(book['rating'], 3.5);
  });

  test('exports books as CSV', () async {
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Der Vorleser',
            authors: const ['Schlink'],
            editedFields: const [],
            isbn13: const Value('9783442719255'),
          ),
        );

    final csv = await service.exportBooksCsv();
    expect(csv, contains('Der Vorleser'));
    expect(csv, contains('9783442719255'));
  });
}
