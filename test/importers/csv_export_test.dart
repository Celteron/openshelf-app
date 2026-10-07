import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// The full CSV export: every field, in the Openreads column layout, and
/// importable again.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
  });
  tearDown(() => db.close());

  Future<List<Map<String, String>>> exported() async {
    final csv = await ExportService(db).exportBooksCsv();
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csv);
    final header = rows.first.cast<String>();
    return [
      for (final row in rows.skip(1))
        {for (var i = 0; i < header.length; i++) header[i]: '${row[i]}'},
    ];
  }

  Future<int> addBook(
    String title, {
    List<String> authors = const ['A'],
    BookStatus status = BookStatus.unread,
    int? location,
    int? series,
    DateTime? deletedAt,
    String? isbn13,
  }) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          title: title,
          authors: authors,
          editedFields: const [],
          status: Value(status),
          locationId: Value(location),
          seriesId: Value(series),
          deletedAt: Value(deletedAt),
          isbn13: Value(isbn13),
        ),
      );

  test('the header has the Openreads columns first, then the extras', () async {
    final csv = await ExportService(db).exportBooksCsv();
    final header = csv.split('\n').first.split(',');

    expect(header.take(19), [
      'title',
      'subtitle',
      'author',
      'description',
      'status',
      'favourite',
      'deleted',
      'rating',
      'pages',
      'publication_year',
      'isbn',
      'olid',
      'tags',
      'my_review',
      'notes',
      'book_format',
      'readings',
      'date_added',
      'date_modified',
    ]);
    expect(
      header.skip(19),
      containsAll([
        'isbn13',
        'isbn10',
        'publisher',
        'language',
        'current_page',
        'finished_at',
        'series',
        'series_volume',
        'location',
        'lending_status',
        'borrower',
        'lent_at',
        'expected_return',
        'quotes',
        'cover_url',
      ]),
    );
  });

  test('exports every field of a fully filled book', () async {
    final room = await db
        .into(db.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Wohnzimmer',
            type: LocationType.room,
          ),
        );
    final shelf = await db
        .into(db.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Regal 1',
            type: LocationType.shelf,
            parentId: Value(room),
          ),
        );
    final series = await db
        .into(db.seriesTable)
        .insert(SeriesTableCompanion.insert(name: 'Die Reihe'));
    final id = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Der Vorleser',
            subtitle: const Value('Roman'),
            authors: const ['Bernhard Schlink', 'Zweite Autorin'],
            editedFields: const [],
            isbn13: const Value('9783257229530'),
            isbn10: const Value('3257229534'),
            publisher: const Value('Diogenes'),
            publishedYear: const Value(1995),
            pageCount: const Value(207),
            format: const Value(BookFormat.hardcover),
            language: const Value('de'),
            status: const Value(BookStatus.read),
            rating: const Value(4.5),
            locationId: Value(shelf),
            seriesId: Value(series),
            seriesVolume: const Value(2),
            description: const Value('Beschreibung, mit Komma'),
            coverUrl: const Value('https://x/c.jpg'),
            currentPage: const Value(207),
            finishedAt: Value(DateTime(2025, 3, 14)),
            isFavorite: const Value(true),
            review: const Value('Stark; "bewegend"'),
            olid: const Value('OL1M'),
            createdAt: Value(DateTime(2024, 1, 2)),
            updatedAt: Value(DateTime(2025, 6, 7)),
          ),
        );
    final crime = await db
        .into(db.tags)
        .insert(TagsCompanion.insert(name: 'Krimi'));
    final other = await db
        .into(db.tags)
        .insert(TagsCompanion.insert(name: 'Klassiker'));
    for (final t in [crime, other]) {
      await db
          .into(db.bookTags)
          .insert(BookTagsCompanion.insert(bookId: id, tagId: t));
    }
    await db
        .into(db.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: id,
            kind: NoteKind.note,
            content: 'Notiz 1',
          ),
        );
    await db
        .into(db.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: id,
            kind: NoteKind.note,
            content: 'Notiz 2',
          ),
        );
    await db
        .into(db.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: id,
            kind: NoteKind.quote,
            content: 'Ein Zitat',
            pageNumber: const Value(42),
          ),
        );
    await db
        .into(db.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            bookId: id,
            startedAt: DateTime(2025, 3, 10, 20),
            endedAt: Value(DateTime(2025, 3, 14, 18)),
            durationSeconds: const Value(7200),
          ),
        );
    await db
        .into(db.lending)
        .insert(
          LendingCompanion.insert(
            bookId: id,
            borrowerName: 'Anna',
            lentAt: DateTime(2026, 1, 5),
            expectedReturn: Value(DateTime(2026, 2, 1)),
          ),
        );

    final row = (await exported()).single;

    expect(row['title'], 'Der Vorleser');
    expect(row['subtitle'], 'Roman');
    expect(row['author'], 'Bernhard Schlink, Zweite Autorin');
    expect(row['description'], 'Beschreibung, mit Komma');
    expect(row['status'], 'finished');
    expect(row['favourite'], 'true');
    expect(row['deleted'], 'false');
    expect(row['rating'], '4.5');
    expect(row['pages'], '207');
    expect(row['publication_year'], '1995');
    expect(row['isbn'], '9783257229530');
    expect(row['isbn13'], '9783257229530');
    expect(row['isbn10'], '3257229534');
    expect(row['olid'], 'OL1M');
    expect(row['tags'].toString().split('|||||').toSet(), {
      'Krimi',
      'Klassiker',
    });
    expect(row['my_review'], 'Stark; "bewegend"');
    expect(row['notes'], 'Notiz 1${ExportService.noteSeparator}Notiz 2');
    expect(row['quotes'], 'Ein Zitat');
    expect(row['book_format'], 'hardcover');
    expect(
      row['readings'],
      '2025-03-10T20:00:00.000|2025-03-14T18:00:00.000|7200000',
    );
    expect(row['date_added'], '2024-01-02T00:00:00.000');
    expect(row['date_modified'], '2025-06-07T00:00:00.000');
    expect(row['publisher'], 'Diogenes');
    expect(row['language'], 'de');
    expect(row['current_page'], '207');
    expect(row['finished_at'], '2025-03-14T00:00:00.000');
    expect(row['series'], 'Die Reihe');
    expect(row['series_volume'], '2.0');
    expect(row['location'], 'Wohnzimmer > Regal 1');
    expect(row['lending_status'], 'lent');
    expect(row['borrower'], 'Anna');
    expect(row['lent_at'], '2026-01-05T00:00:00.000');
    expect(row['expected_return'], '2026-02-01T00:00:00.000');
    expect(row['cover_url'], 'https://x/c.jpg');
  });

  test('a returned book is "available" again', () async {
    final id = await addBook('Zurück');
    await db
        .into(db.lending)
        .insert(
          LendingCompanion.insert(
            bookId: id,
            borrowerName: 'Anna',
            lentAt: DateTime(2026, 1, 5),
            returnedAt: Value(DateTime(2026, 1, 9)),
          ),
        );

    final row = (await exported()).single;

    expect(row['lending_status'], 'available');
    expect(row['borrower'], '');
  });

  test('statuses use the Openreads vocabulary where there is one', () async {
    for (final s in BookStatus.values) {
      await addBook(s.name, status: s);
    }
    final byTitle = {
      for (final r in await exported()) r['title']!: r['status'],
    };

    expect(byTitle, {
      'read': 'finished',
      'reading': 'in_progress',
      'wishlist': 'planned',
      'dnf': 'abandoned',
      'unread': 'unread',
      'reReading': 're_reading',
    });
  });

  test('trashed books are exported and flagged as deleted', () async {
    await addBook('Sichtbar');
    await addBook('Weg', deletedAt: DateTime(2026, 4, 1));

    final deleted = {
      for (final r in await exported()) r['title']!: r['deleted'],
    };

    expect(deleted, {'Sichtbar': 'false', 'Weg': 'true'});
  });

  test('commas, quotes and line breaks survive CSV quoting', () async {
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Titel, mit "Zitat"\nund Zeilenumbruch',
            authors: const ['A'],
            editedFields: const [],
          ),
        );
    expect(
      (await exported()).single['title'],
      'Titel, mit "Zitat"\nund Zeilenumbruch',
    );
  });

  test('an empty library exports just the header', () async {
    final csv = await ExportService(db).exportBooksCsv();
    expect(csv.trim().split('\n'), hasLength(1));
  });

  group('re-import', () {
    test('an exported CSV imports back without loss', () async {
      final room = await db
          .into(db.locations)
          .insert(
            LocationsCompanion.insert(
              name: 'Wohnzimmer',
              type: LocationType.room,
            ),
          );
      final shelf = await db
          .into(db.locations)
          .insert(
            LocationsCompanion.insert(
              name: 'Regal 1',
              type: LocationType.shelf,
              parentId: Value(room),
            ),
          );
      final id = await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              title: 'Der Vorleser',
              authors: const ['Bernhard Schlink'],
              editedFields: const [],
              isbn13: const Value('9783257229530'),
              publisher: const Value('Diogenes'),
              pageCount: const Value(207),
              status: const Value(BookStatus.read),
              rating: const Value(4.5),
              locationId: Value(shelf),
              currentPage: const Value(207),
              finishedAt: Value(DateTime(2025, 3, 14)),
              isFavorite: const Value(true),
              review: const Value('Stark'),
              olid: const Value('OL1M'),
              createdAt: Value(DateTime(2024, 1, 2)),
            ),
          );
      final tag = await db
          .into(db.tags)
          .insert(TagsCompanion.insert(name: 'Krimi'));
      await db
          .into(db.bookTags)
          .insert(BookTagsCompanion.insert(bookId: id, tagId: tag));
      await db
          .into(db.bookNotes)
          .insert(
            BookNotesCompanion.insert(
              bookId: id,
              kind: NoteKind.note,
              content: 'Notiz',
            ),
          );
      await db
          .into(db.bookNotes)
          .insert(
            BookNotesCompanion.insert(
              bookId: id,
              kind: NoteKind.quote,
              content: 'Zitat',
            ),
          );
      await db
          .into(db.readingSessions)
          .insert(
            ReadingSessionsCompanion.insert(
              bookId: id,
              startedAt: DateTime(2025, 3, 10),
              endedAt: Value(DateTime(2025, 3, 14)),
              durationSeconds: const Value(3600),
            ),
          );
      await db
          .into(db.lending)
          .insert(
            LendingCompanion.insert(
              bookId: id,
              borrowerName: 'Anna',
              lentAt: DateTime(2026, 1, 5),
            ),
          );
      final csv = await ExportService(db).exportBooksCsv();

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      await fresh.customSelect('select 1').get();
      final file = ImportFile(
        name: 'e.csv',
        content: csv,
        type: ImportFileType.csv,
      );
      expect(OpenreadsCsvImporter().canParse(file), isTrue);
      final result = await ImportService(
        BookRepositoryImpl(BooksDao(fresh)),
      ).import(OpenreadsCsvImporter().parse(file));

      expect(result.errors, isEmpty);
      expect(result.imported, 1);
      final book = await fresh.select(fresh.books).getSingle();
      expect(book.title, 'Der Vorleser');
      expect(book.authors, ['Bernhard Schlink']);
      expect(book.isbn13, '9783257229530');
      expect(book.publisher, 'Diogenes');
      expect(book.status, BookStatus.read);
      expect(book.rating, 4.5);
      expect(book.isFavorite, isTrue);
      expect(book.review, 'Stark');
      expect(book.olid, 'OL1M');
      expect(book.currentPage, 207);
      expect(book.finishedAt, DateTime(2025, 3, 14));
      expect(book.createdAt, DateTime(2024, 1, 2));
      expect((await fresh.select(fresh.tags).getSingle()).name, 'Krimi');
      final notes = await fresh.select(fresh.bookNotes).get();
      expect(
        {for (final n in notes) n.content: n.kind},
        {'Notiz': NoteKind.note, 'Zitat': NoteKind.quote},
      );
      final session = await fresh.select(fresh.readingSessions).getSingle();
      expect(session.durationSeconds, 3600);
      expect(session.endedAt, DateTime(2025, 3, 14));
      final location = await (fresh.select(
        fresh.locations,
      )..where((t) => t.parentId.isNotNull())).getSingle();
      expect(location.name, 'Regal 1');
      expect(location.type, LocationType.shelf);
      expect(book.locationId, location.id);
      expect(
        (await fresh.select(fresh.lending).getSingle()).borrowerName,
        'Anna',
      );
    });

    test('re-importing the CSV into the same library is a no-op', () async {
      await addBook('Buch', isbn13: '9783257229530');
      final csv = await ExportService(db).exportBooksCsv();

      final result = await ImportService(BookRepositoryImpl(BooksDao(db)))
          .import(
            OpenreadsCsvImporter().parse(
              ImportFile(name: 'e.csv', content: csv, type: ImportFileType.csv),
            ),
          );

      expect((result.imported, result.updated, result.duplicates), (0, 0, 1));
    });

    test('trashed rows are not resurrected by a re-import', () async {
      await addBook('Weg', deletedAt: DateTime(2026, 4, 1));
      final csv = await ExportService(db).exportBooksCsv();
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);

      final result = await ImportService(BookRepositoryImpl(BooksDao(fresh)))
          .import(
            OpenreadsCsvImporter().parse(
              ImportFile(name: 'e.csv', content: csv, type: ImportFileType.csv),
            ),
          );

      expect(result.imported, 0);
      expect(result.errors.single.reason, 'Deleted in source');
    });
  });
}
