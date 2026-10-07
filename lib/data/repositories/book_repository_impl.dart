import 'package:drift/drift.dart';
import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
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
  Future<void> updateStatus(int id, BookStatus status) =>
      _dao.update(id, BooksCompanion(status: Value(status)));

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
      seriesVolume: Value(draft.seriesVolume),
      status: Value(draft.status),
      rating: Value(draft.rating),
      metadataSource: Value(draft.metadataSource),
      locationId: Value(draft.locationId),
      seriesId: Value(draft.seriesId),
    );
  }

  @override
  Future<int> insertAll(List<BooksCompanion> books) => _dao.insertAll(books);

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
