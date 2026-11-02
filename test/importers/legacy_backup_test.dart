import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/importers/bookwyrm_csv_importer.dart';
import 'package:openreads/data/importers/legacy_backup_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

import '../helpers/test_images.dart';

/// Legacy Openreads backup archives (v4/v5) and the Bookwyrm CSV.
void main() {
  late AppDatabase db;
  late Directory dir;
  late CoverCacheService covers;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    dir = Directory.systemTemp.createTempSync('legacy_backup_test');
    covers = CoverCacheService(baseDirectory: dir);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Map<String, dynamic> legacyBook(
    int id,
    String title, {
    int status = 0,
    int rating = 0,
    bool favourite = false,
    bool deleted = false,
    bool hasCover = false,
    String tags = '',
    String readings = '',
    String? isbn,
    List<int>? inlineCover,
  }) => {
    'id': id,
    'title': title,
    'subtitle': null,
    'author': 'Autor $id',
    'description': null,
    'status': status,
    'rating': rating,
    'favourite': favourite ? 1 : 0,
    'deleted': deleted ? 1 : 0,
    'pages': 300,
    'publication_year': 2000,
    'isbn': isbn,
    'olid': 'OL${id}M',
    'tags': tags,
    'my_review': 'Review $id',
    'notes': 'Notiz $id',
    'cover': inlineCover,
    'blur_hash': null,
    'has_cover': hasCover ? 1 : 0,
    'book_type': 'paperback',
    'readings': readings,
    'date_added': '2023-01-0${id}T10:00:00.000',
    'date_modified': '2023-02-0${id}T10:00:00.000',
  };

  ImportFile archive({
    required List<Map<String, dynamic>> books,
    String? challenges,
    Map<String, List<int>> files = const {},
    String separator = '@@@@@',
    bool withBooks = true,
  }) {
    final zip = Archive();
    void add(String name, List<int> bytes) =>
        zip.addFile(ArchiveFile(name, bytes.length, bytes));
    if (withBooks) {
      add('books.backup', utf8.encode(books.map(jsonEncode).join(separator)));
    }
    if (challenges != null) add('challenges.backup', utf8.encode(challenges));
    add('info.txt', utf8.encode('5\n2.11.0'));
    files.forEach(add);
    return ImportFile(
      name: 'Openreads-5.zip',
      type: ImportFileType.zip,
      bytes: Uint8List.fromList(ZipEncoder().encode(zip)),
    );
  }

  Future<ImportResult> restore(ImportFile file) => ImportService(
    BookRepositoryImpl(BooksDao(db)),
    coverCache: covers,
  ).import(LegacyBackupImporter().parse(file));

  group('legacy backup archive', () {
    test('is recognised by its books.backup entry', () {
      final good = archive(books: [legacyBook(1, 'A')]);
      expect(LegacyBackupImporter().canParse(good), isTrue);
      expect(
        LegacyBackupImporter().canParse(
          archive(books: const [], withBooks: false),
        ),
        isFalse,
      );
      expect(
        LegacyBackupImporter().canParse(
          ImportFile(
            name: 'x.zip',
            type: ImportFileType.zip,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ),
        isFalse,
      );
      expect(
        LegacyBackupImporter().canParse(
          const ImportFile(name: 'x.zip', type: ImportFileType.zip),
        ),
        isFalse,
      );
    });

    test('restores books with every legacy field', () async {
      final file = archive(
        books: [
          legacyBook(
            1,
            'Der Vorleser',
            status: 0,
            rating: 45,
            favourite: true,
            tags: 'Klassiker|||||Drama',
            isbn: '9783257229530',
            readings: '2024-01-02T00:00:00.000|2024-01-09T00:00:00.000|7200000',
          ),
          legacyBook(2, 'Läuft', status: 1),
          legacyBook(3, 'Später', status: 2),
          legacyBook(4, 'Abgebrochen', status: 3),
        ],
      );

      final result = await restore(file);

      expect(result.errors, isEmpty);
      expect(result.imported, 4);
      final books = {
        for (final b in await db.select(db.books).get()) b.title: b,
      };
      final book = books['Der Vorleser']!;
      expect(book.authors, ['Autor 1']);
      expect(book.isbn13, '9783257229530');
      expect(book.rating, 4.5);
      expect(book.isFavorite, isTrue);
      expect(book.review, 'Review 1');
      expect(book.olid, 'OL1M');
      expect(book.pageCount, 300);
      expect(book.format, BookFormat.paperback);
      expect(book.status, BookStatus.read);
      expect(book.finishedAt, DateTime(2024, 1, 9));
      expect(book.createdAt, DateTime(2023, 1, 1, 10));
      expect(book.updatedAt, DateTime(2023, 2, 1, 10));
      expect(books['Läuft']!.status, BookStatus.reading);
      expect(books['Später']!.status, BookStatus.wishlist);
      expect(books['Abgebrochen']!.status, BookStatus.dnf);
      expect(
        {for (final t in await db.select(db.tags).get()) t.name},
        {'Klassiker', 'Drama'},
      );
      expect(
        (await db.select(db.bookNotes).get()).map((n) => n.content).toSet(),
        {'Notiz 1', 'Notiz 2', 'Notiz 3', 'Notiz 4'},
      );
      final session = await (db.select(
        db.readingSessions,
      )..where((t) => t.bookId.equals(book.id))).getSingle();
      expect(session.durationSeconds, 7200);
    });

    test('books in the legacy trash come back in the trash', () async {
      final result = await restore(
        archive(
          books: [
            legacyBook(1, 'Sichtbar'),
            legacyBook(2, 'Gelöscht', deleted: true),
          ],
        ),
      );

      expect(result.imported, 2);
      final trashed = await (db.select(
        db.books,
      )..where((t) => t.deletedAt.isNotNull())).get();
      expect(trashed.map((b) => b.title), ['Gelöscht']);
      expect(trashed.single.deletedAt, DateTime(2023, 2, 2, 10));
    });

    test('v5 covers are stored from <id>.jpg', () async {
      final cover = testPng(seed: 4);
      final file = archive(
        books: [legacyBook(7, 'Mit Cover', hasCover: true)],
        files: {'7.jpg': cover},
      );

      await restore(file);

      final book = await db.select(db.books).getSingle();
      expect(book.coverLocalPath, isNotNull);
      expect(File(book.coverLocalPath!).readAsBytesSync(), cover);
    });

    test('v4 covers are read from the inline byte list', () async {
      final cover = testPng(seed: 8);
      final file = archive(
        books: [legacyBook(1, 'Inline', inlineCover: cover)],
      );

      await restore(file);

      final book = await db.select(db.books).getSingle();
      expect(File(book.coverLocalPath!).readAsBytesSync(), cover);
    });

    test('a book without cover has none', () async {
      await restore(archive(books: [legacyBook(1, 'Ohne')]));
      expect((await db.select(db.books).getSingle()).coverLocalPath, isNull);
    });

    test('early v2 archives separated books with |||||', () async {
      final result = await restore(
        archive(
          books: [legacyBook(1, 'Eins'), legacyBook(2, 'Zwei')],
          separator: '|||||',
        ),
      );
      expect(result.imported, 2);
    });

    test('yearly challenges become reading goals', () async {
      final result = await restore(
        archive(
          books: [legacyBook(1, 'A')],
          challenges: [
            jsonEncode({'year': 2024, 'books': 30, 'pages': 9000}),
            jsonEncode({'year': 2023, 'books': 12, 'pages': null}),
            jsonEncode({'year': 2022, 'books': null, 'pages': 4000}),
            jsonEncode({'year': 2021, 'books': null, 'pages': null}),
          ].join('|||||'),
        ),
      );

      expect(result.errors, isEmpty);
      final goals = {
        for (final g in await db.select(db.readingGoals).get())
          g.year: (g.targetBooks, g.targetPages),
      };
      expect(goals, {
        2024: (30, 9000),
        2023: (12, null),
        2022: (0, 4000), // pages-only: stored with a book target of 0
      });
    });

    test('a broken entry is reported, the rest is restored', () async {
      final file = archive(books: [legacyBook(1, 'Gut')]);
      final broken = ImportFile(
        name: 'x.zip',
        type: ImportFileType.zip,
        bytes: Uint8List.fromList(
          ZipEncoder().encode(
            Archive()..addFile(
              ArchiveFile(
                'books.backup',
                0,
                utf8.encode('${jsonEncode(legacyBook(1, 'Gut'))}@@@@@{kaputt'),
              ),
            ),
          ),
        ),
      );
      expect(LegacyBackupImporter().canParse(file), isTrue);

      final result = await restore(broken);

      expect(result.imported, 1);
      expect(result.errors, hasLength(1));
    });

    test('restoring twice does not duplicate anything', () async {
      final file = archive(
        books: [
          legacyBook(1, 'Eins', isbn: '9783257229530', tags: 'Klassiker'),
        ],
      );
      await restore(file);

      final second = await restore(file);

      expect(second.imported, 0);
      expect(second.duplicates, 1);
      expect(await db.select(db.books).get(), hasLength(1));
      expect(await db.select(db.bookNotes).get(), hasLength(1));
    });
  });

  group('Bookwyrm CSV', () {
    const header =
        'title,author_text,isbn_10,isbn_13,openlibrary_key,rating,'
        'review_content,shelf,start_date,finish_date';

    Future<ImportResult> import(String body) =>
        ImportService(BookRepositoryImpl(BooksDao(db))).import(
          BookwyrmCsvImporter().parse(
            ImportFile(
              name: 'b.csv',
              content: '$header\n$body',
              type: ImportFileType.csv,
            ),
          ),
        );

    test('is recognised by its headers and not as Goodreads', () {
      const file = ImportFile(
        name: 'b.csv',
        content: '$header\n',
        type: ImportFileType.csv,
      );
      expect(BookwyrmCsvImporter().canParse(file), isTrue);
      expect(
        BookwyrmCsvImporter().canParse(
          const ImportFile(
            name: 'g.csv',
            content: 'Title,Author,ISBN\n',
            type: ImportFileType.csv,
          ),
        ),
        isFalse,
      );
    });

    test('maps Openreads\' fields plus shelf and dates', () async {
      final result = await import(
        'Dune,Frank Herbert,0441172717,9780441172719,OL123M,5,Episch,read,'
        '2024-01-01,2024-01-20\n'
        'Neuland,Jane Doe,,9783000000009,OL9M,0,,to-read,,\n'
        'Läuft,Max,,,OL5M,,,reading,2024-05-01,\n'
        'Abbruch,Max,,,,3,,stopped-reading,,\n',
      );

      expect(result.errors, isEmpty);
      expect(result.imported, 4);
      final books = {
        for (final b in await db.select(db.books).get()) b.title: b,
      };
      final dune = books['Dune']!;
      expect(dune.isbn13, '9780441172719');
      expect(dune.isbn10, '0441172717');
      expect(dune.olid, 'OL123M');
      expect(dune.rating, 5.0);
      expect(dune.review, 'Episch');
      expect(dune.status, BookStatus.read);
      expect(dune.finishedAt, DateTime(2024, 1, 20));
      expect(books['Neuland']!.status, BookStatus.wishlist);
      expect(books['Läuft']!.status, BookStatus.reading);
      expect(books['Abbruch']!.status, BookStatus.dnf);
      expect(books['Abbruch']!.rating, 3.0);
      final session = await (db.select(
        db.readingSessions,
      )..where((t) => t.bookId.equals(dune.id))).getSingle();
      expect(session.startedAt, DateTime(2024, 1, 1));
      expect(session.endedAt, DateTime(2024, 1, 20));
    });

    test(
      'without a shelf column every book counts as read, like Openreads',
      () async {
        final result = await ImportService(BookRepositoryImpl(BooksDao(db))).import(
          BookwyrmCsvImporter().parse(
            const ImportFile(
              name: 'b.csv',
              content:
                  'title,author_text,isbn_13,rating\nDune,Frank,9780441172719,4\n',
              type: ImportFileType.csv,
            ),
          ),
        );

        expect(result.imported, 1);
        expect((await db.select(db.books).getSingle()).status, BookStatus.read);
      },
    );

    test('an ISBN-10-only row gets its ISBN-13', () async {
      await import('Alt,Autor,3257229534,,,,,read,,\n');
      final book = await db.select(db.books).getSingle();
      expect(book.isbn13, '9783257229530');
      expect(book.isbn10, '3257229534');
    });
  });
}
