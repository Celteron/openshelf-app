import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/import_merge.dart';
import 'package:openreads/data/importers/bookstats_csv_importer.dart';
import 'package:openreads/data/importers/import_decoding.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// The real Bookstats export holds personal data, so it is gitignored and only
/// exists locally; without it these tests are skipped.
final _realExportMissing = File('test/Test_Export_BookStats.csv').existsSync()
    ? null
    : 'local-only fixture test/Test_Export_BookStats.csv is missing';

/// Re-import behaviour: a row that matches an existing book is merged into it
/// (only gaps are filled) or skipped as an identical duplicate; it never
/// creates a second copy and never overwrites what the user already has.
void main() {
  late AppDatabase db;
  late ImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ImportService(BookRepositoryImpl(BooksDao(db)));
  });

  tearDown(() => db.close());

  Stream<ImportRow> rows(List<BookImport> books) => Stream.fromIterable([
    for (var i = 0; i < books.length; i++)
      ImportRow(rowNumber: i + 1, book: books[i]),
  ]);

  Future<ImportResult> import(List<BookImport> books) =>
      service.import(rows(books));

  Future<Book> only() async => (await db.select(db.books).get()).single;

  Future<Set<String>> tagNames() async => {
    for (final t in await db.select(db.tags).get()) t.name,
  };

  group('re-importing the real Bookstats export', skip: _realExportMissing, () {
    late ImportFile file;

    setUp(() {
      file = ImportFile(
        name: 'Test_Export_BookStats.csv',
        content: decodeImportBytes(
          File('test/Test_Export_BookStats.csv').readAsBytesSync(),
        ),
        type: ImportFileType.csv,
      );
    });

    test('a second import adds nothing and reports 773 duplicates', () async {
      final first = await service.import(BookstatsCsvImporter().parse(file));
      expect(first.imported, 773);
      expect(first.updated, 0);
      expect(first.duplicates, 0);

      final second = await service.import(BookstatsCsvImporter().parse(file));
      expect(second.imported, 0);
      expect(second.updated, 0);
      expect(second.duplicates, 773, reason: 'incl. the 11 books w/o ISBN');
      expect(second.skipped, 773);
      expect(second.errors, isEmpty);

      expect(await db.select(db.books).get(), hasLength(773));
      expect(await db.select(db.tags).get(), hasLength(83));
      expect(await db.select(db.bookTags).get(), hasLength(726));
      expect(await db.select(db.readingSessions).get(), hasLength(110));
    });

    test('a third import is still a no-op', () async {
      await service.import(BookstatsCsvImporter().parse(file));
      await service.import(BookstatsCsvImporter().parse(file));
      final third = await service.import(BookstatsCsvImporter().parse(file));
      expect(third.duplicates, 773);
      expect(await db.select(db.books).get(), hasLength(773));
    });
  });

  group('matching', () {
    test('matches by ISBN-13 even when title and authors differ', () async {
      await import([
        const BookImport(
          title: 'Original',
          authors: ['A'],
          isbn13: '9783000000001',
        ),
      ]);
      final result = await import([
        const BookImport(
          title: 'Anderer Titel',
          authors: ['B'],
          isbn13: '9783000000001',
        ),
      ]);

      expect(result.imported, 0);
      expect(result.duplicates, 1);
      expect((await only()).title, 'Original', reason: 'existing data wins');
    });

    test('matches an ISBN-10-only row against a stored ISBN-10', () async {
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              title: 'Alt',
              authors: const ['A'],
              editedFields: const [],
              isbn10: const Value('3442719259'),
            ),
          );
      final result = await import([
        const BookImport(
          title: 'Alt (Neuimport)',
          authors: ['A'],
          isbn10: '3442719259',
          publisher: 'Goldmann',
        ),
      ]);

      expect(result.updated, 1);
      expect(await db.select(db.books).get(), hasLength(1));
      expect((await only()).publisher, 'Goldmann');
    });

    test(
      'books without ISBN match on title + authors, ignoring case',
      () async {
        await import([
          const BookImport(title: 'Dark Summer Night', authors: ['Anna  Test']),
        ]);
        final result = await import([
          const BookImport(title: 'dark summer night', authors: ['anna test']),
        ]);

        expect(result.imported, 0);
        expect(result.duplicates, 1);
        expect(await db.select(db.books).get(), hasLength(1));
      },
    );

    test('same title but different authors are different books', () async {
      await import([
        const BookImport(title: 'Gleich', authors: ['A']),
      ]);
      final result = await import([
        const BookImport(title: 'Gleich', authors: ['B']),
      ]);

      expect(result.imported, 1);
      expect(await db.select(db.books).get(), hasLength(2));
    });

    test(
      'two different ISBN-13s with the same title stay two editions',
      () async {
        await import([
          const BookImport(
            title: 'Edition',
            authors: ['A'],
            isbn13: '9783000000001',
          ),
        ]);
        final result = await import([
          const BookImport(
            title: 'Edition',
            authors: ['A'],
            isbn13: '9783000000002',
          ),
        ]);

        expect(result.imported, 1);
        expect(await db.select(db.books).get(), hasLength(2));
      },
    );

    test('an ISBN-less library book gains the ISBN from the import', () async {
      await import([
        const BookImport(title: 'Ohne', authors: ['A']),
      ]);
      final result = await import([
        const BookImport(
          title: 'Ohne',
          authors: ['A'],
          isbn13: '9783000000009',
        ),
      ]);

      expect(result.updated, 1);
      expect((await only()).isbn13, '9783000000009');
    });

    test('duplicates inside one file collapse and merge their tags', () async {
      final result = await import([
        const BookImport(
          title: 'Doppelt',
          authors: ['A'],
          isbn13: '9783000000001',
          tags: ['Eins'],
        ),
        const BookImport(
          title: 'Doppelt',
          authors: ['A'],
          isbn13: '9783000000001',
          tags: ['Eins', 'Zwei'],
        ),
        const BookImport(
          title: 'Doppelt',
          authors: ['A'],
          isbn13: '9783000000001',
          tags: ['Zwei'],
        ),
      ]);

      expect(result.imported, 1);
      expect(result.updated, 1, reason: 'row 2 brought "Zwei"');
      expect(result.duplicates, 1, reason: 'row 3 brought nothing new');
      expect(await tagNames(), {'Eins', 'Zwei'});
    });
  });

  group('merge strategy', () {
    const isbn = '9783000000001';

    test('fills gaps and adds new tags, notes and sessions', () async {
      await import([
        const BookImport(title: 'Buch', authors: ['A'], isbn13: isbn),
      ]);

      final result = await import([
        BookImport(
          title: 'Buch',
          authors: const ['A'],
          isbn13: isbn,
          publisher: 'Verlag',
          pageCount: 300,
          publishedYear: 2020,
          format: BookFormat.hardcover,
          description: 'Beschreibung',
          rating: 4,
          isFavorite: true,
          review: 'Gut',
          status: BookStatus.read,
          tags: const ['Krimi'],
          notes: const [NoteImport(content: 'Notiz')],
          readings: [
            ReadingImport(
              startedAt: DateTime(2024, 1, 1),
              finishedAt: DateTime(2024, 1, 5),
            ),
          ],
        ),
      ]);

      expect(result.imported, 0);
      expect(result.updated, 1);
      expect(result.duplicates, 0);
      expect(result.skipped, 0);

      final book = await only();
      expect(book.publisher, 'Verlag');
      expect(book.pageCount, 300);
      expect(book.publishedYear, 2020);
      expect(book.format, BookFormat.hardcover);
      expect(book.description, 'Beschreibung');
      expect(book.rating, 4.0);
      expect(book.isFavorite, isTrue);
      expect(book.review, 'Gut');
      expect(book.status, BookStatus.read);
      expect(await tagNames(), {'Krimi'});
      expect((await db.select(db.bookNotes).get()).single.content, 'Notiz');
      expect(await db.select(db.readingSessions).get(), hasLength(1));
    });

    test('never overwrites what the library already has', () async {
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              title: 'Mein Titel',
              authors: const ['Meine Autorin'],
              editedFields: const [],
              isbn13: const Value(isbn),
              publisher: const Value('Mein Verlag'),
              pageCount: const Value(111),
              rating: const Value(5),
              status: const Value(BookStatus.reading),
              review: const Value('Meine Meinung'),
              description: const Value('Meine Beschreibung'),
              currentPage: const Value(40),
              isFavorite: const Value(true),
            ),
          );

      final result = await import([
        const BookImport(
          title: 'Fremder Titel',
          authors: ['Fremde Autorin'],
          isbn13: isbn,
          publisher: 'Fremder Verlag',
          pageCount: 999,
          rating: 1,
          status: BookStatus.dnf,
          review: 'Fremde Meinung',
          description: 'Fremde Beschreibung',
        ),
      ]);

      expect(result.duplicates, 1);
      expect(result.updated, 0);

      final book = await only();
      expect(book.title, 'Mein Titel');
      expect(book.authors, ['Meine Autorin']);
      expect(book.publisher, 'Mein Verlag');
      expect(book.pageCount, 111);
      expect(book.rating, 5.0);
      expect(book.status, BookStatus.reading);
      expect(book.review, 'Meine Meinung');
      expect(book.description, 'Meine Beschreibung');
      expect(book.currentPage, 40);
      expect(book.isFavorite, isTrue);
    });

    test('an unread book adopts the imported reading state', () async {
      await import([
        const BookImport(title: 'Neu', authors: ['A'], isbn13: isbn),
      ]);
      await import([
        BookImport(
          title: 'Neu',
          authors: const ['A'],
          isbn13: isbn,
          status: BookStatus.read,
          pageCount: 200,
          readings: [ReadingImport(finishedAt: DateTime(2023, 6, 1))],
        ),
      ]);

      final book = await only();
      expect(book.status, BookStatus.read);
      expect(book.currentPage, 200);
      expect(book.finishedAt, DateTime(2023, 6, 1));
    });

    test('a finished book without a date gains the finish date', () async {
      await import([
        const BookImport(
          title: 'Fertig',
          authors: ['A'],
          isbn13: isbn,
          status: BookStatus.read,
          pageCount: 100,
        ),
      ]);
      expect((await only()).finishedAt, isNull);

      final result = await import([
        BookImport(
          title: 'Fertig',
          authors: const ['A'],
          isbn13: isbn,
          status: BookStatus.read,
          readings: [ReadingImport(finishedAt: DateTime(2022, 2, 2))],
        ),
      ]);

      expect(result.updated, 1);
      expect((await only()).finishedAt, DateTime(2022, 2, 2));
    });

    test('tags match case-insensitively and are not linked twice', () async {
      await import([
        const BookImport(
          title: 'T',
          authors: ['A'],
          isbn13: isbn,
          tags: ['Übernatürliches'],
        ),
      ]);
      final result = await import([
        const BookImport(
          title: 'T',
          authors: ['A'],
          isbn13: isbn,
          tags: ['übernatürliches', 'Neu'],
        ),
      ]);

      expect(result.updated, 1);
      expect(await db.select(db.tags).get(), hasLength(2));
      expect(await db.select(db.bookTags).get(), hasLength(2));
    });

    test('identical notes and sessions are not added twice', () async {
      final book = BookImport(
        title: 'N',
        authors: const ['A'],
        isbn13: isbn,
        notes: const [NoteImport(content: ' Gleiche Notiz ')],
        readings: [
          ReadingImport(
            startedAt: DateTime(2024, 3, 1),
            finishedAt: DateTime(2024, 3, 9),
          ),
        ],
      );
      await import([book]);
      final again = await import([book]);

      expect(again.duplicates, 1);
      expect(await db.select(db.bookNotes).get(), hasLength(1));
      expect(await db.select(db.readingSessions).get(), hasLength(1));
    });

    test('a new reading of the same book is added as a new session', () async {
      BookImport withReading(DateTime start, DateTime end) => BookImport(
        title: 'Zweimal',
        authors: const ['A'],
        isbn13: isbn,
        readings: [ReadingImport(startedAt: start, finishedAt: end)],
      );
      await import([withReading(DateTime(2020, 1, 1), DateTime(2020, 1, 9))]);
      final result = await import([
        withReading(DateTime(2024, 5, 1), DateTime(2024, 5, 9)),
      ]);

      expect(result.updated, 1);
      expect(await db.select(db.readingSessions).get(), hasLength(2));
    });
  });

  group('through a real CSV importer', () {
    const header =
        'title,subtitle,author,description,status,favourite,deleted,rating,'
        'pages,publication_year,isbn,olid,tags,my_review,notes,book_format,'
        'readings,date_added,date_modified';

    Future<ImportResult> importCsv(String csv) => service.import(
      OpenreadsCsvImporter().parse(
        ImportFile(name: 'o.csv', content: csv, type: ImportFileType.csv),
      ),
    );

    test('re-importing an Openreads CSV is a no-op, an extended one merges', () async {
      const first =
          '$header\n'
          'Dune,,Frank Herbert,,finished,false,false,4.5,412,1965,9780441172719,,SciFi,,,paperback,'
          '2023-05-01T00:00:00.000|2023-05-20T00:00:00.000|,2023-04-30T08:00:00.000,\n';
      const extended =
          '$header\n'
          'Dune,,Frank Herbert,,finished,true,false,4.5,412,1965,9780441172719,,SciFi|||||Klassiker,Meisterwerk,Arrakis,paperback,'
          '2023-05-01T00:00:00.000|2023-05-20T00:00:00.000|;'
          '2024-02-01T00:00:00.000|2024-02-10T00:00:00.000|,2023-04-30T08:00:00.000,\n';

      final a = await importCsv(first);
      expect(a.imported, 1);

      final b = await importCsv(first);
      expect((b.imported, b.updated, b.duplicates), (0, 0, 1));

      final c = await importCsv(extended);
      expect((c.imported, c.updated, c.duplicates), (0, 1, 0));

      final book = await only();
      expect(book.isFavorite, isTrue);
      expect(book.review, 'Meisterwerk');
      expect(await tagNames(), {'SciFi', 'Klassiker'});
      expect(await db.select(db.bookNotes).get(), hasLength(1));
      expect(
        await db.select(db.readingSessions).get(),
        hasLength(2),
        reason: 'the 2023 reading already existed; only 2024 is new',
      );

      final d = await importCsv(extended);
      expect((d.imported, d.updated, d.duplicates), (0, 0, 1));
    });
  });

  group('mergeMissingFields', () {
    Book existing({
      String? publisher,
      double rating = 0,
      BookStatus status = BookStatus.unread,
    }) => Book(
      id: 1,
      title: 'T',
      authors: const ['A'],
      publisher: publisher,
      status: status,
      rating: rating,
      editedFields: const [],
      currentPage: 0,
      isFavorite: false,
      coverNotFound: false,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

    test('returns null when the import offers nothing new', () {
      final patch = mergeMissingFields(
        existing(publisher: 'X', rating: 3),
        BooksCompanion.insert(
          title: 'T',
          authors: const ['A'],
          editedFields: const [],
          publisher: const Value('Y'),
          rating: const Value(1),
        ),
      );
      expect(patch, isNull);
    });

    test('writes only the fields that are actually filled', () {
      final patch = mergeMissingFields(
        existing(publisher: 'X'),
        BooksCompanion.insert(
          title: 'T',
          authors: const ['A'],
          editedFields: const [],
          publisher: const Value('Y'),
          pageCount: const Value(50),
        ),
      )!;
      expect(patch.pageCount.value, 50);
      expect(patch.publisher.present, isFalse, reason: 'publisher was set');
      expect(patch.title.present, isFalse);
      expect(patch.status.present, isFalse);
    });

    test('treats blank text as empty', () {
      final patch = mergeMissingFields(
        existing(publisher: '   '),
        BooksCompanion.insert(
          title: 'T',
          authors: const ['A'],
          editedFields: const [],
          publisher: const Value('Neu'),
        ),
      )!;
      expect(patch.publisher.value, 'Neu');
    });
  });
}
