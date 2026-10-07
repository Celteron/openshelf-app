import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';

abstract class BookRepository {
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  });

  Future<List<Book>> searchLocal(String query);

  Future<List<Book>> getAllBooks();

  Future<Book?> getBook(int id);

  Future<int> insertBook(BooksCompanion book);

  Future<int> addBook(BookDraft draft);

  Future<int> insertAll(List<BooksCompanion> books);

  Future<void> updateBook(int id, BooksCompanion book);

  Future<void> updateBookDraft(int id, BookDraft draft);

  Future<void> updateRating(int id, double rating);

  Future<void> updateStatus(int id, BookStatus status);

  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId);

  Future<bool> isbnExists(String isbn13);
}
