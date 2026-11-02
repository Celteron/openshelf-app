import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/import_merge.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/json_backup_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// Genre, price and received date (schema v4, spec 003 FR-F1-01..03).
void main() {
  late AppDatabase db;
  late BookRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = BookRepositoryImpl(BooksDao(db));
  });

  tearDown(() => db.close());

  group('repository', () {
    test('addBook stores genre, price and received date', () async {
      final id = await repository.addBook(
        BookDraft(
          title: 'Buch',
          authors: const ['A'],
          genre: 'Krimi',
          priceCents: 1290,
          receivedAt: DateTime(2025, 12, 24),
          receivedAs: ReceivedAs.gift,
          readingSeconds: 19800,
        ),
      );
      final book = (await repository.getBook(id))!;
      expect(book.readingSeconds, 19800);
      expect(book.receivedAs, ReceivedAs.gift);
      expect(
        (book.genre, book.priceCents, book.receivedAt),
        ('Krimi', 1290, DateTime(2025, 12, 24)),
      );
    });

    test('updateBookDraft changes and clears the new fields', () async {
      final id = await repository.addBook(
        const BookDraft(
          title: 'Buch',
          authors: ['A'],
          genre: 'Krimi',
          priceCents: 500,
          receivedAs: ReceivedAs.loan,
        ),
      );
      await repository.updateBookDraft(
        id,
        const BookDraft(title: 'Buch', authors: ['A'], genre: 'Thriller'),
      );
      final book = (await repository.getBook(id))!;
      expect(book.genre, 'Thriller');
      expect(book.priceCents, isNull, reason: 'cleared by the user');
      expect(book.receivedAs, isNull, reason: 'cleared by the user');
    });
  });

  group('cover-not-found flag (FR-R2-08)', () {
    Future<int> flagged({String? url, String? isbn}) async {
      final id = await repository.addBook(
        BookDraft(
          title: 'Buch',
          authors: const ['A'],
          coverUrl: url,
          isbn13: isbn,
        ),
      );
      await repository.setCoverNotFound(id);
      expect((await repository.getBook(id))!.coverNotFound, isTrue);
      return id;
    }

    test('a cover chosen online keeps its URL as a user edit', () async {
      final id = await flagged(url: 'https://a/default.jpg');
      await repository.setChosenCover(
        id,
        path: '/covers/online.jpg',
        url: 'https://b/other-edition.jpg',
      );
      final book = (await repository.getBook(id))!;
      expect(book.coverLocalPath, '/covers/online.jpg');
      expect(book.coverUrl, 'https://b/other-edition.jpg');
      expect(book.editedFields, contains('coverUrl'));
      expect(book.coverNotFound, isFalse);
    });

    test('a stored cover clears it', () async {
      final id = await flagged();
      await repository.setCoverLocalPath(id, '/covers/b.jpg');
      expect((await repository.getBook(id))!.coverNotFound, isFalse);
    });

    test('a new cover URL or ISBN clears it, other edits keep it', () async {
      final id = await flagged(url: 'https://a/c.jpg');
      await repository.updateBookDraft(
        id,
        const BookDraft(
          title: 'Neu',
          authors: ['A'],
          coverUrl: 'https://a/c.jpg',
        ),
      );
      expect((await repository.getBook(id))!.coverNotFound, isTrue);

      await repository.updateBookDraft(
        id,
        const BookDraft(
          title: 'Neu',
          authors: ['A'],
          coverUrl: 'https://b/c.jpg',
        ),
      );
      expect((await repository.getBook(id))!.coverNotFound, isFalse);

      final other = await flagged();
      await repository.updateBookDraft(
        other,
        const BookDraft(title: 'Buch', authors: ['A'], isbn13: '9783442719255'),
      );
      expect((await repository.getBook(other))!.coverNotFound, isFalse);
    });
  });

  group('mergeMissingFields', () {
    Book existing({
      String? genre,
      int? priceCents,
      DateTime? receivedAt,
      ReceivedAs? receivedAs,
      int? readingSeconds,
    }) => Book(
      id: 1,
      title: 'T',
      authors: const ['A'],
      genre: genre,
      priceCents: priceCents,
      receivedAt: receivedAt,
      receivedAs: receivedAs,
      readingSeconds: readingSeconds,
      status: BookStatus.unread,
      rating: 0,
      editedFields: const [],
      currentPage: 0,
      isFavorite: false,
      coverNotFound: false,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

    BooksCompanion incoming() => BooksCompanion.insert(
      title: 'T',
      authors: const ['A'],
      editedFields: const [],
      genre: const Value('Fantasy'),
      priceCents: const Value(999),
      receivedAt: Value(DateTime(2024, 5, 1)),
      receivedAs: const Value(ReceivedAs.purchase),
    );

    test('a merged cover URL clears the cover-not-found flag', () {
      final patch = mergeMissingFields(
        existing(),
        BooksCompanion.insert(
          title: 'T',
          authors: const ['A'],
          editedFields: const [],
          coverUrl: const Value('https://x/c.jpg'),
        ),
      )!;
      expect(patch.coverNotFound.value, isFalse);
    });

    test('a merged cover file clears the cover-not-found flag too', () {
      final patch = mergeMissingFields(
        existing(),
        BooksCompanion.insert(
          title: 'T',
          authors: const ['A'],
          editedFields: const [],
          coverLocalPath: const Value('/covers/k.jpg'),
        ),
      )!;
      expect(patch.coverNotFound.value, isFalse);
    });

    test('fills empty genre, price and received date', () {
      final patch = mergeMissingFields(existing(), incoming())!;
      expect(patch.genre.value, 'Fantasy');
      expect(patch.priceCents.value, 999);
      expect(patch.receivedAt.value, DateTime(2024, 5, 1));
      expect(patch.receivedAs.value, ReceivedAs.purchase);
    });

    test('fills an empty reading time but keeps an existing one', () {
      final incomingTime = BooksCompanion.insert(
        title: 'T',
        authors: const ['A'],
        editedFields: const [],
        readingSeconds: const Value(600),
      );
      final filled = mergeMissingFields(existing(), incomingTime)!;
      expect(filled.readingSeconds.value, 600);
      expect(
        mergeMissingFields(existing(readingSeconds: 0), incomingTime),
        isNull,
      );
    });

    test('never overwrites values the user already has', () {
      final patch = mergeMissingFields(
        existing(
          genre: 'Krimi',
          priceCents: 0,
          receivedAt: DateTime(2020, 1, 1),
          receivedAs: ReceivedAs.gift,
        ),
        incoming(),
      );
      expect(patch, isNull, reason: 'a price of 0 is a value, not a gap');
    });
  });

  group('export and restore (Constitution I.3)', () {
    Future<int> seed() => repository.addBook(
      BookDraft(
        title: 'Buch',
        authors: const ['A'],
        isbn13: '9783442719255',
        genre: 'Krimi',
        priceCents: 1290,
        receivedAt: DateTime(2025, 12, 24),
        receivedAs: ReceivedAs.reviewCopy,
        readingSeconds: 19800,
      ),
    );

    test('JSON export contains the fields', () async {
      await seed();
      final json = jsonDecode(await ExportService(db).exportJson()) as Map;
      final book = (json['books'] as List).single as Map;
      expect(book['genre'], 'Krimi');
      expect(book['priceCents'], 1290);
      expect(book['receivedAt'], startsWith('2025-12-24'));
      expect(book['readingSeconds'], 19800);
      expect(book['receivedAs'], 'reviewCopy');
      expect(
        book.containsKey('coverNotFound'),
        isFalse,
        reason: 'device state',
      );
    });

    test('CSV export contains genre, price and received_at', () async {
      await seed();
      final csv = await ExportService(db).exportBooksCsv();
      final header = csv.split('\n').first;
      expect(header, contains('genre'));
      expect(header, contains('price'));
      expect(header, contains('received_at'));
      expect(header, contains('reading_seconds'));
      expect(header, contains('received_as'));
      expect(header, isNot(contains('cover_not_found')));
      expect(csv, contains('reviewCopy'));
      expect(csv, contains('12.90'));
      expect(csv, contains('Krimi'));
    });

    Future<Book> restoreInto(
      AppDatabase target,
      ImportFile file,
      importer,
    ) async {
      await ImportService(
        BookRepositoryImpl(BooksDao(target)),
      ).import(importer.parse(file));
      return (await target.select(target.books).get()).single;
    }

    test('JSON backup round-trips the fields', () async {
      await seed();
      final json = await ExportService(db).exportJson();
      final target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      final book = await restoreInto(
        target,
        ImportFile(name: 'b.json', content: json, type: ImportFileType.json),
        JsonBackupImporter(),
      );
      expect(
        (book.genre, book.priceCents, book.receivedAt, book.readingSeconds),
        ('Krimi', 1290, DateTime(2025, 12, 24), 19800),
      );
      expect(book.receivedAs, ReceivedAs.reviewCopy);
    });

    test('CSV export round-trips the fields', () async {
      await seed();
      final csv = await ExportService(db).exportBooksCsv();
      final target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      final book = await restoreInto(
        target,
        ImportFile(name: 'b.csv', content: csv, type: ImportFileType.csv),
        OpenreadsCsvImporter(),
      );
      expect(
        (book.genre, book.priceCents, book.receivedAt, book.readingSeconds),
        ('Krimi', 1290, DateTime(2025, 12, 24), 19800),
      );
      expect(book.receivedAs, ReceivedAs.reviewCopy);
    });
  });
}
