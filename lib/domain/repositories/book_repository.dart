import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

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

  /// Imports books with their tags, notes and reading sessions atomically.
  ///
  /// A row matching an existing book (ISBN-13, ISBN-10, or identical title and
  /// authors) is merged into it instead of duplicated: only missing data is
  /// added, nothing the user entered is overwritten.
  Future<ImportBatchOutcome> importBatch(List<ImportedBook> books);

  /// Deletes the book; its sessions, notes, tag links and lending records go
  /// with it (foreign-key cascade).
  Future<void> deleteBook(int id);

  Future<void> updateFavorite(int id, bool isFavorite);

  /// Sets the review text; blank text clears it.
  Future<void> updateReview(int id, String? review);

  Future<void> updateBook(int id, BooksCompanion book);

  Future<void> updateBookDraft(int id, BookDraft draft);

  Future<void> updateRating(int id, double rating);

  Future<void> updateStatus(int id, BookStatus status);

  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId);

  Future<bool> isbnExists(String isbn13);
}
