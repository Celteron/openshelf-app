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

  /// Writes the standalone locations and goals of a backup.
  Future<void> importExtras(ImportExtras extras);

  /// Moves the book to the trash (soft delete). It disappears from the library,
  /// statistics and goals but can be restored.
  Future<void> deleteBook(int id);

  /// Moves several books to the trash.
  Future<void> deleteBooks(List<int> ids);

  Stream<List<Book>> watchTrashedBooks();

  Future<void> restoreBook(int id);

  /// Permanently deletes a book; its sessions, notes, tag links and lending
  /// records go with it (foreign-key cascade).
  Future<void> purgeBook(int id);

  /// Permanently deletes everything in the trash; returns the number of books.
  Future<int> emptyTrash();

  /// Moves every active book to the trash; returns how many.
  Future<int> trashAllBooks();

  /// Permanently deletes every book, trashed ones included, with its sessions,
  /// notes, tag links and lending records; returns how many.
  Future<int> deleteAllBooksPermanently();

  /// The active volumes of slipcase [id] in order; empty for other books.
  Future<List<Book>> getVolumes(int id);

  /// Splits slipcase [id] into [volumes] (ADR-0003) in one transaction and
  /// returns the new ids in order. The volumes take over authors, publisher,
  /// language, year, format, genre, series, status, finish date and rating;
  /// reading data (sessions, notes, review, reading time) moves to the first
  /// volume. Throws an [ArgumentError] for fewer than two volumes and a
  /// [StateError] when [id] is a volume, already split, or unknown.
  Future<List<int>> splitIntoVolumes(int id, List<VolumeDraft> volumes);

  Future<void> bulkSetFormat(List<int> bookIds, BookFormat format);

  Future<void> bulkSetAuthors(List<int> bookIds, List<String> authors);

  Future<void> updateFavorite(int id, bool isFavorite);

  /// Remembers (or clears) the locally cached/manual cover file of a book.
  /// Setting a file also clears the "no cover online" flag.
  Future<void> setCoverLocalPath(int id, String? path);

  /// Remembers that every online source answered "no cover" (FR-R2-08).
  Future<void> setCoverNotFound(int id);

  /// Sets the review text; blank text clears it.
  Future<void> updateReview(int id, String? review);

  Future<void> updateBook(int id, BooksCompanion book);

  Future<void> updateBookDraft(int id, BookDraft draft);

  Future<void> updateRating(int id, double rating);

  Future<void> updateStatus(int id, BookStatus status);

  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId);

  Future<bool> isbnExists(String isbn13);
}
