import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/bookstats_csv_importer.dart';
import 'package:openreads/data/importers/bookstats_json_importer.dart';
import 'package:openreads/data/importers/goodreads_csv_importer.dart';
import 'package:openreads/data/importers/import_decoding.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/importers/storygraph_csv_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// The real export holds personal data, so it is gitignored and only exists
/// locally; without it the tests that need it are skipped.
final _realExportMissing = File('test/Test_Export_BookStats.csv').existsSync()
    ? null
    : 'local-only fixture test/Test_Export_BookStats.csv is missing';

/// End-to-end import of the real Bookstats export (`;`-delimited, ISO-8859-1,
/// German headers) into the Schema v2 tables.
///
/// The expected numbers were derived independently of the Dart parser from the
/// fixture itself (773 data rows).
void main() {
  const fixture = 'test/Test_Export_BookStats.csv';

  late AppDatabase db;
  late ImportService service;
  late ImportFile file;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ImportService(BookRepositoryImpl(BooksDao(db)));
    if (_realExportMissing != null) return;
    file = ImportFile(
      name: 'Test_Export_BookStats.csv',
      content: decodeImportBytes(File(fixture).readAsBytesSync()),
      type: ImportFileType.csv,
    );
  });

  tearDown(() => db.close());

  Future<ImportResult> runImport() =>
      service.import(BookstatsCsvImporter().parse(file));

  test(
    'is detected as Bookstats and not as another format',
    skip: _realExportMissing,
    () {
      final importers = <BookImporter>[
        OpenreadsCsvImporter(),
        OpenreadsJsonImporter(),
        GoodreadsCsvImporter(),
        StoryGraphCsvImporter(),
        BookstatsCsvImporter(),
        BookstatsJsonImporter(),
      ];
      final detected = importers.firstWhere(
        (i) => i.supportedType == file.type && i.canParse(file),
      );
      expect(detected, isA<BookstatsCsvImporter>());
    },
  );

  test(
    'decodes the ISO-8859-1 file without mojibake',
    skip: _realExportMissing,
    () {
      expect(file.content, contains('Wenn Donner und Licht sich berühren'));
      expect(file.content, isNot(contains('�')));
    },
  );

  test(
    'imports all 773 books without a single error',
    skip: _realExportMissing,
    () async {
      final result = await runImport();

      expect(result.errors, isEmpty);
      expect(result.skipped, 0);
      expect(result.imported, 773);
      expect((await db.select(db.books).get()), hasLength(773));
    },
  );

  test(
    'maps book fields: title, authors, ISBN, pages, format, rating',
    skip: _realExportMissing,
    () async {
      await runImport();
      final books = await db.select(db.books).get();
      Book byTitle(String title) => books.firstWhere((b) => b.title == title);

      final first = byTitle('Whitestone Hospital - High Hopes');
      expect(first.authors, ['Ava Reed'], reason: '"Last, First" is flipped');
      expect(first.isbn13, '9783736315471');
      expect(first.pageCount, 416);
      expect(first.publishedYear, 2022);
      expect(first.format, BookFormat.paperback);
      expect(first.status, BookStatus.read);
      expect(first.createdAt, DateTime(2022, 3, 24), reason: 'Erhalten am');

      final coAuthored = books.firstWhere(
        (b) => b.authors.length == 2 && b.authors.contains('Vi Keeland'),
      );
      expect(coAuthored.authors, ['Vi Keeland', 'Penelope Ward']);

      expect(
        books.where((b) => b.format == BookFormat.paperback),
        hasLength(605),
      );
      expect(
        books.where((b) => b.format == BookFormat.hardcover),
        hasLength(160),
      );
      expect(books.where((b) => b.format == BookFormat.ebook), hasLength(8));
      expect(books.where((b) => b.rating > 0), hasLength(132));
      expect(books.where((b) => b.isbn13 == null), hasLength(11));
    },
  );

  test('maps the reading status', skip: _realExportMissing, () async {
    await runImport();
    final books = await db.select(db.books).get();

    expect(books.where((b) => b.status == BookStatus.read), hasLength(291));
    expect(books.where((b) => b.status == BookStatus.unread), hasLength(476));
    expect(books.where((b) => b.status == BookStatus.reading), hasLength(6));
  });

  test(
    'imports reading progress: pages, finish dates and sessions',
    skip: _realExportMissing,
    () async {
      await runImport();
      final books = await db.select(db.books).get();
      final read = books.where((b) => b.status == BookStatus.read).toList();

      // Finished books are fully read; the sum matches the fixture's page counts.
      final withPages = read.where((b) => (b.pageCount ?? 0) > 0).toList();
      expect(withPages, hasLength(289));
      expect(withPages.every((b) => b.currentPage == b.pageCount), isTrue);
      expect(withPages.fold<int>(0, (s, b) => s + b.currentPage), 122848);
      // Nothing is invented for books that are not finished.
      expect(
        books
            .where((b) => b.status != BookStatus.read)
            .every((b) => b.currentPage == 0),
        isTrue,
      );

      // 104 finished books carry a Leseende, distributed over the years.
      final finished = read.where((b) => b.finishedAt != null).toList();
      expect(finished, hasLength(104));
      int inYear(int y) =>
          finished.where((b) => b.finishedAt!.year == y).length;
      expect([2022, 2023, 2024, 2025, 2026].map(inYear), [24, 12, 8, 33, 27]);

      // Every Lesebeginn/Leseende pair became exactly one completed session.
      final sessions = await db.select(db.readingSessions).get();
      expect(sessions, hasLength(110));
      expect(
        sessions.every((s) => s.endedAt != null),
        isTrue,
        reason: 'no session may look like a running timer',
      );
      expect(
        sessions.every((s) => s.endPage == null && s.durationSeconds == 0),
        isTrue,
        reason: 'no pages or durations are made up',
      );

      final book = books.firstWhere(
        (b) => b.title.startsWith('Wie die Ruhe vor dem Stur'),
      );
      final session = sessions.singleWhere((s) => s.bookId == book.id);
      expect(session.startedAt, DateTime(2022, 11, 14));
      expect(session.endedAt, DateTime(2022, 11, 15));
      expect(book.finishedAt, DateTime(2022, 11, 15));
    },
  );

  test(
    'the imported finish dates drive the yearly goal',
    skip: _realExportMissing,
    () async {
      await runImport();
      final books = await db.select(db.books).get();
      GoalProgress goalFor(int year) => GoalProgress.compute(
        year: year,
        target: 50,
        books: books,
        now: DateTime(2026, 10, 7),
      );

      // Books with a Leseende count in that year; read books without one fall
      // back to when they were received (GoalProgress.countsForYear): in 2022
      // that is 24 dated + 168 undated books.
      final y2022 = goalFor(2022);
      expect(y2022.completed, 192);
      expect(y2022.pagesRead, 81241);

      final y2026 = goalFor(2026);
      expect(y2026.completed, 29);
      expect(y2026.pagesRead, 13864);
    },
  );

  test(
    'imports genre as tags and drops opaque category ids',
    skip: _realExportMissing,
    () async {
      await runImport();
      final tags = await db.select(db.tags).get();
      final links = await db.select(db.bookTags).get();

      expect(tags, hasLength(83));
      expect(links, hasLength(726));
      expect(
        tags.any((t) => RegExp(r'^[0-9a-f]{8}-').hasMatch(t.name)),
        isFalse,
        reason: 'UUID genres are noise',
      );

      final newAdult = tags.singleWhere((t) => t.name == 'New Adult');
      expect(links.where((l) => l.tagId == newAdult.id), hasLength(149));
    },
  );

  test(
    'the fixture has no notes; a Notizen column is imported as notes',
    skip: _realExportMissing,
    () async {
      await runImport();
      expect(await db.select(db.bookNotes).get(), isEmpty);

      const csv =
          '"Titel";"Autor(en)";"ISBN";"Lesestatus";"Notizen";"Erhalten am"\n'
          '"Mit Notiz";"Doe, Jane";"9783736315471";"Gelesen";"Starkes Ende; unbedingt nochmal lesen";"24.03.2022"\n';
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final result = await ImportService(BookRepositoryImpl(BooksDao(fresh)))
          .import(
            BookstatsCsvImporter().parse(
              const ImportFile(
                name: 'n.csv',
                content: csv,
                type: ImportFileType.csv,
              ),
            ),
          );

      expect(result.imported, 1);
      final note = (await fresh.select(fresh.bookNotes).get()).single;
      expect(note.kind, NoteKind.note);
      expect(note.content, 'Starkes Ende; unbedingt nochmal lesen');
      expect(note.createdAt, DateTime(2022, 3, 24));
    },
  );
  group('genre, price, received date and reading time (spec 003)', () {
    test(
      'maps Genre, Preis and Erhalten am of the real export',
      skip: _realExportMissing,
      () async {
        await runImport();
        final books = await db.select(db.books).get();
        final first = books.firstWhere(
          (b) => b.title == 'Whitestone Hospital - High Hopes',
        );

        expect(first.genre, 'New Adult');
        expect(first.priceCents, 1290);
        expect(first.receivedAt, DateTime(2022, 3, 24));
        expect(
          books.where((b) => b.genre != null),
          hasLength(greaterThan(700)),
        );
        expect(books.where((b) => b.priceCents != null), hasLength(773));
        expect(books.where((b) => b.receivedAt != null), hasLength(773));
      },
    );

    test(
      'maps Erhalten als of the real export',
      skip: _realExportMissing,
      () async {
        await runImport();
        final books = await db.select(db.books).get();
        final byKind = <ReceivedAs?, int>{};
        for (final b in books) {
          byKind[b.receivedAs] = (byKind[b.receivedAs] ?? 0) + 1;
        }
        expect(byKind, {ReceivedAs.purchase: 769, ReceivedAs.reviewCopy: 4});
      },
    );

    test(
      'drops opaque ids in the genre column',
      skip: _realExportMissing,
      () async {
        await runImport();
        final genres = (await db.select(db.books).get()).map((b) => b.genre);
        expect(
          genres.any((g) => g != null && RegExp(r'^[0-9a-f]{8}-').hasMatch(g)),
          isFalse,
        );
      },
    );

    test('Dauer (Stunden/Minuten) becomes the reading session time', () async {
      const csv =
          '"Titel";"Autor(en)";"ISBN";"Genre";"Preis";"Lesestatus";'
          '"Lesebeginn";"Leseende";"Dauer (Stunden)";"Dauer (Minuten)";'
          '"Erhalten am";"Erhalten als"\n'
          '"Lang";"Doe, Jane";"9783736315471";"Krimi";"9,99 €";"Gelesen";'
          '"01.02.2020";"15.02.2020";"5";"30";"20.01.2020";"Geschenk"\n';
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      await ImportService(BookRepositoryImpl(BooksDao(fresh))).import(
        BookstatsCsvImporter().parse(
          const ImportFile(
            name: 'd.csv',
            content: csv,
            type: ImportFileType.csv,
          ),
        ),
      );

      final book = await fresh.select(fresh.books).getSingle();
      expect((book.genre, book.priceCents), ('Krimi', 999));
      expect(book.receivedAs, ReceivedAs.gift);
      final session = await fresh.select(fresh.readingSessions).getSingle();
      expect(session.durationSeconds, 5 * 3600 + 30 * 60);
    });
  });

  test('Bookstats JSON maps genre, price and received date', () async {
    const json =
        '[{"titel":"A","autor":"B","isbn":"9783446172580","genre":"Krimi",'
        '"preis":12.9,"erhalten am":"20.01.2020","erhalten als":"Leihe"},'
        '{"titel":"C","autor":"D","isbn":"9783442719255","preis":"9,99 €",'
        '"hinzugefuegt":"05.05.2021"}]';
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await ImportService(BookRepositoryImpl(BooksDao(fresh))).import(
      BookstatsJsonImporter().parse(
        const ImportFile(
          name: 'b.json',
          content: json,
          type: ImportFileType.json,
        ),
      ),
    );

    final books = await fresh.select(fresh.books).get();
    final a = books.firstWhere((b) => b.title == 'A');
    expect(
      (a.genre, a.priceCents, a.receivedAt),
      ('Krimi', 1290, DateTime(2020, 1, 20)),
    );
    expect(a.receivedAs, ReceivedAs.loan);
    final c = books.firstWhere((b) => b.title == 'C');
    expect(c.priceCents, 999);
    expect(
      c.receivedAt,
      isNull,
      reason: 'only "added" is known, not "received"',
    );
  });

  test('Dauer without any reading date is kept as the reading time', () async {
    const csv =
        '"Titel";"Autor(en)";"ISBN";"Lesestatus";"Dauer (Stunden)";'
        '"Dauer (Minuten)"\n'
        '"Ohne Datum";"Doe, Jane";"9783736315471";"Gelesen";"5";"30"\n';
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await ImportService(BookRepositoryImpl(BooksDao(fresh))).import(
      BookstatsCsvImporter().parse(
        const ImportFile(name: 'd.csv', content: csv, type: ImportFileType.csv),
      ),
    );

    final book = await fresh.select(fresh.books).getSingle();
    expect(book.readingSeconds, 5 * 3600 + 30 * 60);
    expect(await fresh.select(fresh.readingSessions).get(), isEmpty);
  });
}
