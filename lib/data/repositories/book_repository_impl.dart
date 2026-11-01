import 'package:drift/drift.dart';
import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  final BooksDao _dao;

  BookRepositoryImpl(this._dao);

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => _dao.watchBooks(query: query, status: status, locationId: locationId);

  @override
  Future<List<Book>> searchLocal(String query) => _dao.search(query);

  @override
  Future<List<Book>> getAllBooks() => _dao.getAll();

  @override
  Future<Book?> getBook(int id) => _dao.getById(id);

  @override
  Future<int> insertBook(BooksCompanion book) => _dao.insert(book);

  @override
  Future<int> addBook(BookDraft draft) => _dao.insert(_draftToCompanion(draft));

  @override
  Future<void> updateRating(int id, double rating) =>
      _dao.update(id, BooksCompanion(rating: Value(rating)));

  @override
  Future<void> updateStatus(int id, BookStatus status) async {
    // Phase 2 (FR-P2-04): record when a book transitions into `read`.
    final current = await _dao.getById(id);
    final becameRead =
        status == BookStatus.read && current?.status != BookStatus.read;
    await _dao.update(
      id,
      BooksCompanion(
        status: Value(status),
        finishedAt: becameRead
            ? Value(DateTime.now())
            : const Value<DateTime?>.absent(),
      ),
    );
  }

  BooksCompanion _draftToCompanion(BookDraft draft) {
    // Normalize ISBNs so the canonical 13-digit form is always stored.
    final isbn13 = normalizeIsbn(draft.isbn13) ?? normalizeIsbn(draft.isbn10);
    final isbn10 = draft.isbn13 == null ? cleanIsbn(draft.isbn10) : null;
    return BooksCompanion.insert(
      title: draft.title,
      authors: draft.authors,
      editedFields: draft.editedFields.toList(),
      isbn13: Value(isbn13),
      isbn10: Value(isbn10),
      subtitle: Value(draft.subtitle),
      publisher: Value(draft.publisher),
      publishedYear: Value(draft.publishedYear),
      pageCount: Value(draft.pageCount),
      format: Value(draft.format),
      language: Value(draft.language),
      description: Value(draft.description),
      coverUrl: Value(draft.coverUrl),
      coverLocalPath: Value(draft.coverLocalPath),
      olid: Value(draft.olid),
      seriesVolume: Value(draft.seriesVolume),
      status: Value(draft.status),
      rating: Value(draft.rating),
      metadataSource: Value(draft.metadataSource),
      locationId: Value(draft.locationId),
      seriesId: Value(draft.seriesId),
      genre: Value(draft.genre),
      priceCents: Value(draft.priceCents),
      receivedAt: Value(draft.receivedAt),
      receivedAs: Value(draft.receivedAs),
      readingSeconds: Value(draft.readingSeconds),
    );
  }

  @override
  Future<int> insertAll(List<BooksCompanion> books) => _dao.insertAll(books);

  @override
  Future<ImportBatchOutcome> importBatch(List<ImportedBook> books) =>
      _dao.importBatch(books);

  @override
  Future<void> importExtras(ImportExtras extras) => _dao.importExtras(extras);

  @override
  Future<void> deleteBook(int id) => _dao.trash([id], DateTime.now());

  @override
  Future<void> deleteBooks(List<int> ids) => _dao.trash(ids, DateTime.now());

  @override
  Stream<List<Book>> watchTrashedBooks() => _dao.watchTrashed();

  @override
  Future<void> restoreBook(int id) => _dao.restore(id);

  @override
  Future<void> purgeBook(int id) async {
    await _dao.purge(id);
  }

  @override
  Future<int> emptyTrash() => _dao.emptyTrash();

  @override
  Future<int> trashAllBooks() => _dao.trashAll(DateTime.now());

  @override
  Future<int> deleteAllBooksPermanently() => _dao.deleteAll();

  @override
  Future<void> bulkSetFormat(List<int> bookIds, BookFormat format) =>
      _dao.bulkSetFormat(bookIds, format);

  @override
  Future<void> bulkSetAuthors(List<int> bookIds, List<String> authors) =>
      _dao.bulkSetAuthors(bookIds, authors);

  @override
  Future<void> updateFavorite(int id, bool isFavorite) =>
      _dao.update(id, BooksCompanion(isFavorite: Value(isFavorite)));

  @override
  Future<void> setCoverLocalPath(int id, String? path) =>
      _dao.update(id, BooksCompanion(coverLocalPath: Value(path)));

  @override
  Future<void> updateReview(int id, String? review) {
    final text = review?.trim();
    return _dao.update(
      id,
      BooksCompanion(review: Value(text == null || text.isEmpty ? null : text)),
    );
  }

  @override
  Future<void> updateBook(int id, BooksCompanion book) => _dao.update(id, book);

  @override
  Future<void> updateBookDraft(int id, BookDraft draft) =>
      _dao.update(id, _draftToCompanion(draft));

  @override
  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId) =>
      _dao.bulkAssignLocation(bookIds, locationId);

  @override
  Future<bool> isbnExists(String isbn13) => _dao.isbnExists(isbn13);
}
