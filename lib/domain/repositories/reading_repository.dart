import 'package:openreads/data/database/app_database.dart';

/// Persistence of reading sessions and the per-book current page (Phase 2).
abstract class ReadingRepository {
  /// Sessions of one book, newest first.
  Stream<List<ReadingSession>> watchSessions(int bookId);

  Stream<List<ReadingSession>> watchAllSessions();

  /// The running (not yet ended) session of a book, if any.
  Stream<ReadingSession?> watchActiveSession(int bookId);

  Future<ReadingSession?> getActiveSession(int bookId);

  /// Opens a session. Throws [StateError] when the book already has one.
  Future<int> startSession(
    int bookId, {
    required DateTime startedAt,
    required int startPage,
  });

  /// Closes a session and derives its duration from the timestamps.
  Future<void> finishSession(
    int sessionId, {
    required DateTime endedAt,
    required int endPage,
  });

  /// Records an already-completed session (manual entry).
  Future<int> logSession(
    int bookId, {
    required DateTime startedAt,
    required Duration duration,
    required int startPage,
    required int endPage,
  });

  Future<void> deleteSession(int sessionId);

  Future<void> setCurrentPage(int bookId, int page);
}
