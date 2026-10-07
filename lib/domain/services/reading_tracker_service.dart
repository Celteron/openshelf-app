import 'package:drift/drift.dart' show Value;
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';

/// Coordinates reading sessions with the book's status and current page.
///
/// Rules (FR-P2-03):
/// * starting a session promotes `unread|wishlist|dnf` → `reading` and a
///   finished book → `reReading` (restarting at page 0);
/// * reaching the last page (`pageCount`) of a book that is being read marks
///   it `read`.
class ReadingTrackerService {
  final BookRepository _books;
  final ReadingRepository _reading;
  final DateTime Function() _now;

  ReadingTrackerService(
    this._books,
    this._reading, {
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  /// Starts the timer and returns the session id. Idempotent: an already
  /// running session is returned unchanged.
  Future<int> start(int bookId) async {
    final running = await _reading.getActiveSession(bookId);
    if (running != null) return running.id;

    final book = await _requireBook(bookId);
    var startPage = book.currentPage;

    switch (book.status) {
      case BookStatus.unread || BookStatus.wishlist || BookStatus.dnf:
        await _books.updateStatus(bookId, BookStatus.reading);
      case BookStatus.read:
        startPage = 0;
        await _reading.setCurrentPage(bookId, 0);
        await _books.updateStatus(bookId, BookStatus.reReading);
      case BookStatus.reading || BookStatus.reReading:
        break;
    }

    return _reading.startSession(
      bookId,
      startedAt: _now(),
      startPage: startPage,
    );
  }

  /// Stops the running timer, optionally recording the page reached.
  Future<void> stop(int bookId, {int? endPage}) async {
    final running = await _reading.getActiveSession(bookId);
    if (running == null) return;

    final book = await _requireBook(bookId);
    final page = _clampPage(endPage ?? book.currentPage, book.pageCount);

    await _reading.finishSession(running.id, endedAt: _now(), endPage: page);
    await _applyPage(book, page);
  }

  /// Updates the current page without a session (e.g. a quick bookmark).
  Future<void> setCurrentPage(int bookId, int page) async {
    final book = await _requireBook(bookId);
    final clamped = _clampPage(page, book.pageCount);
    await _applyPage(book, clamped);
  }

  /// Adds a finished session by hand (FR-P2-01).
  Future<int> logManual(
    int bookId, {
    required DateTime startedAt,
    required Duration duration,
    required int startPage,
    required int endPage,
    DateTime? endedAt,
  }) async {
    final book = await _requireBook(bookId);
    final end = _clampPage(endPage, book.pageCount);
    final id = await _reading.logSession(
      bookId,
      startedAt: startedAt,
      duration: duration,
      startPage: _clampPage(startPage, book.pageCount),
      endPage: end,
      endedAt: endedAt,
    );
    if (end > book.currentPage) await _applyPage(book, end);

    // A reading logged after the fact finished on its own end date, not today.
    if (endedAt != null && book.status != BookStatus.read) {
      final after = await _books.getBook(bookId);
      if (after != null && after.status == BookStatus.read) {
        await _books.updateBook(
          bookId,
          BooksCompanion(finishedAt: Value(endedAt)),
        );
      }
    }
    return id;
  }

  Future<void> _applyPage(Book book, int page) async {
    await _reading.setCurrentPage(book.id, page);

    final pageCount = book.pageCount;
    final promotable =
        book.status == BookStatus.unread || book.status == BookStatus.wishlist;

    if (pageCount != null && pageCount > 0 && page >= pageCount) {
      if (book.status != BookStatus.read) {
        await _books.updateStatus(book.id, BookStatus.read);
      }
    } else if (page > 0 && promotable) {
      await _books.updateStatus(book.id, BookStatus.reading);
    }
  }

  int _clampPage(int page, int? pageCount) {
    final lower = page < 0 ? 0 : page;
    if (pageCount != null && pageCount > 0 && lower > pageCount) {
      return pageCount;
    }
    return lower;
  }

  Future<Book> _requireBook(int bookId) async {
    final book = await _books.getBook(bookId);
    if (book == null) throw StateError('Book $bookId does not exist');
    return book;
  }
}
