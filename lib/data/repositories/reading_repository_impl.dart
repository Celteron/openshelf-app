import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  final ReadingDao _dao;

  ReadingRepositoryImpl(this._dao);

  @override
  Stream<List<ReadingSession>> watchSessions(int bookId) =>
      _dao.watchSessions(bookId);

  @override
  Stream<List<ReadingSession>> watchAllSessions() => _dao.watchAll();

  @override
  Stream<ReadingSession?> watchActiveSession(int bookId) =>
      _dao.watchActive(bookId);

  @override
  Future<ReadingSession?> getActiveSession(int bookId) =>
      _dao.getActive(bookId);

  @override
  Future<int> startSession(
    int bookId, {
    required DateTime startedAt,
    required int startPage,
  }) => _dao.start(bookId, startedAt, startPage);

  @override
  Future<void> finishSession(
    int sessionId, {
    required DateTime endedAt,
    required int endPage,
  }) => _dao.finish(sessionId, endedAt, endPage);

  @override
  Future<int> logSession(
    int bookId, {
    required DateTime startedAt,
    required Duration duration,
    required int startPage,
    required int endPage,
    DateTime? endedAt,
  }) => _dao.log(
    ReadingSessionsCompanion.insert(
      bookId: bookId,
      startedAt: startedAt,
      endedAt: Value(endedAt ?? startedAt.add(duration)),
      durationSeconds: Value(duration.inSeconds),
      startPage: Value(startPage),
      endPage: Value(endPage),
    ),
  );

  @override
  Future<void> deleteSession(int sessionId) => _dao.delete(sessionId);

  @override
  Future<void> setCurrentPage(int bookId, int page) =>
      _dao.setCurrentPage(bookId, page);
}
