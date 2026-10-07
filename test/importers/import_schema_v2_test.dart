import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/bookstats_json_importer.dart';
import 'package:openreads/data/importers/goodreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/importers/storygraph_csv_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// Every importer writes legacy notes, tags, reading dates and the new
/// favourite/review fields into the Schema v2 tables.
void main() {
  late AppDatabase db;
  late ImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ImportService(BookRepositoryImpl(BooksDao(db)));
  });

  tearDown(() => db.close());

  Future<ImportResult> importFile(
    BookImporter importer,
    String content,
    ImportFileType type,
  ) {
    final file = ImportFile(name: 'f', content: content, type: type);
    expect(importer.canParse(file), isTrue, reason: 'format detection');
    return service.import(importer.parse(file));
  }

  Future<Book> onlyBook() async => (await db.select(db.books).get()).single;

  Future<List<String>> tagNames(int bookId) async {
    final query = db.select(db.tags).join([
      innerJoin(db.bookTags, db.bookTags.tagId.equalsExp(db.tags.id)),
    ])..where(db.bookTags.bookId.equals(bookId));
    return [for (final r in await query.get()) r.readTable(db.tags).name]
      ..sort();
  }

  group('Openreads CSV', () {
    const header =
        'title,subtitle,author,description,status,favourite,deleted,rating,'
        'pages,publication_year,isbn,olid,tags,my_review,notes,book_format,'
        'readings,date_added,date_modified';

    test('imports favourite, review, notes, tags and readings', () async {
      const csv =
          '$header\n'
          'Der Vorleser,,Bernhard Schlink,Ein Klassiker,finished,true,false,4.5,'
          '208,1995,9783257229530,,Klassiker|||||Drama,"Stark, aber traurig",'
          'Seite 50 lesen,paperback,'
          '2024-01-02T00:00:00.000|2024-01-09T00:00:00.000|7200000,'
          '2023-12-24T10:00:00.000,2024-01-09T00:00:00.000\n';

      final result = await importFile(
        OpenreadsCsvImporter(),
        csv,
        ImportFileType.csv,
      );
      expect(result.imported, 1);
      expect(result.errors, isEmpty);

      final book = await onlyBook();
      expect(book.title, 'Der Vorleser');
      expect(book.status, BookStatus.read);
      expect(book.isFavorite, isTrue);
      expect(book.review, 'Stark, aber traurig');
      expect(book.rating, 4.5);
      expect(book.pageCount, 208);
      expect(book.currentPage, 208);
      expect(book.finishedAt, DateTime(2024, 1, 9));
      expect(book.createdAt, DateTime(2023, 12, 24, 10));
      expect(await tagNames(book.id), ['Drama', 'Klassiker']);

      final note = (await db.select(db.bookNotes).get()).single;
      expect(note.content, 'Seite 50 lesen');
      expect(note.kind, NoteKind.note);

      final session = (await db.select(db.readingSessions).get()).single;
      expect(session.startedAt, DateTime(2024, 1, 2));
      expect(session.endedAt, DateTime(2024, 1, 9));
      expect(session.durationSeconds, 7200);
    });

    test('maps every Openreads status and skips deleted books', () async {
      const csv =
          '$header\n'
          'A,,X,,in_progress,false,false,,,2000,,,,,,,,,\n'
          'B,,X,,planned,false,false,,,2000,,,,,,,,,\n'
          'C,,X,,abandoned,false,false,,,2000,,,,,,,,,\n'
          'D,,X,,finished,false,true,,,2000,,,,,,,,,\n';

      final result = await importFile(
        OpenreadsCsvImporter(),
        csv,
        ImportFileType.csv,
      );
      expect(result.imported, 3);
      expect(result.skipped, 1);
      expect(result.errors.single.reason, 'Deleted in source');

      final statuses = {
        for (final b in await db.select(db.books).get()) b.title: b.status,
      };
      expect(statuses, {
        'A': BookStatus.reading,
        'B': BookStatus.wishlist,
        'C': BookStatus.dnf,
      });
    });

    test('is not mistaken for a Goodreads export (and vice versa)', () {
      const openreads = ImportFile(
        name: 'o',
        content: '$header\n',
        type: ImportFileType.csv,
      );
      const goodreads = ImportFile(
        name: 'g',
        content: 'Title,Author,ISBN,My Rating\n',
        type: ImportFileType.csv,
      );
      expect(OpenreadsCsvImporter().canParse(openreads), isTrue);
      expect(OpenreadsCsvImporter().canParse(goodreads), isFalse);
      expect(GoodreadsCsvImporter().canParse(goodreads), isTrue);
    });
  });

  test(
    'Openreads JSON imports favourite, review, notes, tags, readings',
    () async {
      const json =
          '[{"title":"Dune","author":"Frank Herbert","isbn":"9780441172719",'
          '"status":0,"rating":45,"favourite":1,"deleted":0,"pages":412,'
          '"my_review":"Meisterwerk","notes":"Arrakis","tags":"SciFi|||||Klassiker",'
          '"readings":"2023-05-01T00:00:00.000|2023-05-20T00:00:00.000|",'
          '"date_added":"2023-04-30T08:00:00.000"},'
          '{"title":"Gelöscht","author":"X","status":0,"deleted":1}]';

      final result = await importFile(
        OpenreadsJsonImporter(),
        json,
        ImportFileType.json,
      );
      expect(result.imported, 1);
      expect(result.skipped, 1);

      final book = await onlyBook();
      expect(book.rating, 4.5);
      expect(book.isFavorite, isTrue);
      expect(book.review, 'Meisterwerk');
      expect(book.finishedAt, DateTime(2023, 5, 20));
      expect(await tagNames(book.id), ['Klassiker', 'SciFi']);
      expect((await db.select(db.bookNotes).get()).single.content, 'Arrakis');
      final session = (await db.select(db.readingSessions).get()).single;
      expect(session.durationSeconds, 0);
    },
  );

  test('Goodreads CSV imports review, private notes, shelves and dates', () async {
    const csv =
        'Title,Author,Additional Authors,ISBN,ISBN13,My Rating,Publisher,Binding,'
        'Number of Pages,Year Published,Date Read,Date Added,Bookshelves,'
        'Exclusive Shelf,My Review,Private Notes\n'
        'The Hobbit,J.R.R. Tolkien,,"=""0345339681""","=""9780345339683""",5,'
        'Del Rey,Paperback,310,1986,2020/06/15,2020/01/02,"fantasy, favorites, read",'
        'read,Great adventure,Re-read at Christmas\n';

    final result = await importFile(
      GoodreadsCsvImporter(),
      csv,
      ImportFileType.csv,
    );
    expect(result.errors, isEmpty);

    final book = await onlyBook();
    expect(book.isbn13, '9780345339683', reason: '="…" wrapper is removed');
    expect(book.isbn10, '0345339681');
    expect(book.publisher, 'Del Rey');
    expect(book.publishedYear, 1986);
    expect(book.format, BookFormat.paperback);
    expect(book.review, 'Great adventure');
    expect(book.status, BookStatus.read);
    expect(book.finishedAt, DateTime(2020, 6, 15));
    expect(book.createdAt, DateTime(2020, 1, 2));
    expect(
      await tagNames(book.id),
      ['favorites', 'fantasy'].toList()..sort(),
      reason: 'the "read" status shelf is not a tag',
    );
    expect(
      (await db.select(db.bookNotes).get()).single.content,
      'Re-read at Christmas',
    );
  });

  test(
    'StoryGraph CSV imports status, review, tags and last read date',
    () async {
      const csv =
          'Title,Authors,ISBN/UID,Format,Read Status,Date Added,Last Date Read,'
          'Star Rating,Review,Tags\n'
          'Dune,Frank Herbert,9780441172719,Audio,read,2022/01/05,2022/02/10,4.5,'
          'Epic,"scifi, desert"\n';

      final result = await importFile(
        StoryGraphCsvImporter(),
        csv,
        ImportFileType.csv,
      );
      expect(result.errors, isEmpty);

      final book = await onlyBook();
      expect(book.rating, 4.5);
      expect(book.format, BookFormat.audiobook);
      expect(book.status, BookStatus.read);
      expect(book.review, 'Epic');
      expect(book.finishedAt, DateTime(2022, 2, 10));
      expect(book.createdAt, DateTime(2022, 1, 5));
      expect(await tagNames(book.id), ['desert', 'scifi']);
    },
  );

  test('Bookstats JSON imports notes, genre tags and read dates', () async {
    const json =
        '[{"titel":"Die Blechtrommel","autor":"Grass","isbn":"9783446172580",'
        '"lesestatus":"Gelesen","genre":"Klassiker","notizen":"Schule",'
        '"lesebeginn":"01.02.2020","leseende":"15.02.2020",'
        '"erhalten am":"20.01.2020"}]';

    final result = await importFile(
      BookstatsJsonImporter(),
      json,
      ImportFileType.json,
    );
    expect(result.errors, isEmpty);

    final book = await onlyBook();
    expect(book.status, BookStatus.read);
    expect(book.finishedAt, DateTime(2020, 2, 15));
    expect(book.createdAt, DateTime(2020, 1, 20));
    expect(await tagNames(book.id), ['Klassiker']);
    expect((await db.select(db.bookNotes).get()).single.content, 'Schule');
  });

  group('reading progress and sessions', () {
    BookImport book({
      BookStatus? status,
      int? pages,
      List<ReadingImport> readings = const [],
    }) => BookImport(
      title: 'T',
      authors: const ['A'],
      status: status,
      pageCount: pages,
      readings: readings,
    );

    Stream<ImportRow> rows(List<BookImport> books) => Stream.fromIterable([
      for (var i = 0; i < books.length; i++)
        ImportRow(rowNumber: i + 1, book: books[i]),
    ]);

    test('a read book is complete; others start at page 0', () async {
      await service.import(
        rows([
          book(status: BookStatus.read, pages: 300),
          book(status: BookStatus.reading, pages: 300),
          book(status: BookStatus.read), // unknown page count
        ]),
      );
      final pages = [
        for (final b in await db.select(db.books).get()) b.currentPage,
      ];
      expect(pages, [300, 0, 0]);
    });

    test('the latest finish date of several readings wins', () async {
      await service.import(
        rows([
          book(
            status: BookStatus.read,
            readings: [
              ReadingImport(
                startedAt: DateTime(2020, 1, 1),
                finishedAt: DateTime(2020, 1, 5),
              ),
              ReadingImport(
                startedAt: DateTime(2023, 1, 1),
                finishedAt: DateTime(2023, 1, 7),
              ),
            ],
          ),
        ]),
      );
      expect((await onlyBook()).finishedAt, DateTime(2023, 1, 7));
      expect(await db.select(db.readingSessions).get(), hasLength(2));
    });

    test('a start-only reading never creates a running timer', () async {
      await service.import(
        rows([
          book(
            status: BookStatus.reading,
            readings: [ReadingImport(startedAt: DateTime(2026, 4, 23))],
          ),
        ]),
      );
      final session = (await db.select(db.readingSessions).get()).single;
      expect(session.startedAt, DateTime(2026, 4, 23));
      expect(session.endedAt, isNotNull);
      expect((await onlyBook()).finishedAt, isNull);
    });
  });

  group('atomicity', () {
    test(
      'a failing batch rolls back books, tags, notes and sessions',
      () async {
        final batch = [
          ImportedBook(
            book: BooksCompanion.insert(
              title: 'Gut',
              authors: const ['A'],
              editedFields: const [],
              isbn13: const Value('9780000000001'),
            ),
            tags: const ['Neu'],
            notes: const [NoteImport(content: 'n')],
            readings: [ReadingImport(startedAt: DateTime(2024))],
          ),
          // Same ISBN-13 → UNIQUE constraint failure after the first book was
          // already written inside the transaction.
          ImportedBook(
            book: BooksCompanion.insert(
              title: 'Doppelt',
              authors: const ['A'],
              editedFields: const [],
              isbn13: const Value('9780000000001'),
            ),
          ),
        ];

        await expectLater(BooksDao(db).insertImported(batch), throwsException);

        expect(await db.select(db.books).get(), isEmpty);
        expect(await db.select(db.tags).get(), isEmpty);
        expect(await db.select(db.bookTags).get(), isEmpty);
        expect(await db.select(db.bookNotes).get(), isEmpty);
        expect(await db.select(db.readingSessions).get(), isEmpty);
      },
    );

    test('tags are shared case-insensitively, also across batches', () async {
      Stream<ImportRow> one(String title, String tag) => Stream.value(
        ImportRow(
          rowNumber: 1,
          book: BookImport(title: title, authors: const ['A'], tags: [tag]),
        ),
      );

      await service.import(one('Eins', 'Übernatürliches'));
      await service.import(one('Zwei', 'übernatürliches'));
      await service.import(one('Drei', 'Krimi'));

      expect(await db.select(db.tags).get(), hasLength(2));
      expect(await db.select(db.bookTags).get(), hasLength(3));
    });
  });
}
