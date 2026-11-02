import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/services/import_service.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl repository;
  late ImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = BookRepositoryImpl(BooksDao(db));
    service = ImportService(repository);
  });

  tearDown(() async {
    await db.close();
  });

  Stream<ImportRow> rowsOf(List<BookImport> books) async* {
    for (var i = 0; i < books.length; i++) {
      yield ImportRow(rowNumber: i + 1, book: books[i]);
    }
  }

  BookImport book(String title, String isbn) =>
      BookImport(title: title, isbn13: isbn, authors: const ['A']);

  test('reports progress only once the rows are written', () async {
    final progress = <int>[];
    // Book count at each report; drift runs the queries in order, so each
    // one sees the database as it was when the report came.
    final stored = <Future<int>>[];

    await service.import(
      Stream.fromIterable([
        for (var i = 1; i <= 250; i++)
          i == 7
              ? const ImportRow(rowNumber: 7, error: 'broken')
              : ImportRow(
                  rowNumber: i,
                  book: book('Book $i', '978${i.toString().padLeft(10, '0')}'),
                ),
      ]),
      onProgress: (handled) {
        progress.add(handled);
        stored.add(db.select(db.books).get().then((rows) => rows.length));
      },
    );

    expect(progress, [101, 201, 250], reason: 'batches of 100 books');
    expect(await Future.wait(stored), [100, 200, 249]);
  });

  test('imports books and skips duplicates by ISBN', () async {
    await repository.insertBook(
      BooksCompanion.insert(
        title: 'Existing',
        authors: const ['A'],
        editedFields: const [],
        isbn13: const Value('9780000000001'),
      ),
    );

    final result = await service.import(
      rowsOf([
        book('One', '9780000000001'), // duplicate of existing
        book('Two', '9780000000002'),
        book('Three', '9780000000002'), // duplicate within import
        const BookImport(title: '', authors: []), // missing title
      ]),
    );

    expect(result.imported, 1);
    expect(result.duplicates, 2, reason: 'identical duplicates are skipped');
    expect(result.updated, 0);
    expect(result.skipped, 3, reason: '2 duplicates + 1 invalid row');
    expect(
      result.errors,
      hasLength(1),
      reason: 'only the invalid row is an error',
    );
    expect(await db.select(db.books).get(), hasLength(2));
  });

  test('rolls back the current batch on a critical failure', () async {
    // A repository that fails on the first batch insert.
    final failingRepo = _ThrowingRepository();

    final result = await ImportService(failingRepo).import(
      rowsOf([book('One', '9780000000001'), book('Two', '9780000000002')]),
    );

    expect(result.imported, 0);
    expect(result.skipped, 2);
    expect(
      result.errors.any((e) => e.reason.startsWith('Critical failure')),
      isTrue,
    );
  });
}

class _ThrowingRepository implements BookRepository {
  @override
  Future<void> setCoverNotFound(int id) async {}

  @override
  Future<List<int>> splitIntoVolumes(int id, List<VolumeDraft> volumes) =>
      throw UnimplementedError();

  @override
  Future<List<Book>> getVolumes(int id, {bool includeTrashed = false}) async =>
      const [];

  @override
  Future<int> trashAllBooks() async => 0;

  @override
  Future<int> deleteAllBooksPermanently() async => 0;

  @override
  Future<int> addBook(BookDraft draft) async => 0;

  @override
  Future<bool> isbnExists(String isbn13) async => false;

  @override
  Future<int> insertAll(List<BooksCompanion> books) async {
    throw Exception('constraint failed');
  }

  @override
  Future<ImportBatchOutcome> importBatch(
    List<ImportedBook> books, {
    Map<String, int> knownIds = const {},
  }) async {
    throw Exception('constraint failed');
  }

  @override
  Future<void> deleteBook(int id) async {}

  @override
  Future<void> deleteBooks(List<int> ids) async {}

  @override
  Stream<List<Book>> watchTrashedBooks() async* {}

  @override
  Future<void> restoreBook(int id) async {}

  @override
  Future<void> purgeBook(int id) async {}

  @override
  Future<int> emptyTrash() async => 0;

  @override
  Future<void> bulkSetFormat(List<int> bookIds, BookFormat format) async {}

  @override
  Future<void> bulkSetAuthors(List<int> bookIds, List<String> authors) async {}

  @override
  Future<void> importExtras(ImportExtras extras) async {}

  @override
  Future<void> setCoverLocalPath(int id, String? path) async {}

  @override
  Future<void> setChosenCover(
    int id, {
    required String path,
    String? url,
  }) async {}

  @override
  Future<void> updateFavorite(int id, bool isFavorite) async {}

  @override
  Future<void> updateReview(int id, String? review) async {}

  @override
  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId) async {}

  @override
  Future<Book?> getBook(int id) async => null;

  @override
  Future<List<Book>> getAllBooks() async => const [];

  @override
  Future<int> insertBook(BooksCompanion book) async => 0;

  @override
  Future<List<Book>> searchLocal(String query) async => const [];

  @override
  Future<void> updateBook(int id, BooksCompanion book) async {}

  @override
  Future<void> updateBookDraft(int id, BookDraft draft) async {}

  @override
  Future<void> updateRating(int id, double rating) async {}

  @override
  Future<void> updateStatus(int id, BookStatus status) async {}

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) async* {}
}
