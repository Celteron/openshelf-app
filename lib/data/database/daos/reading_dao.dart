import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class ReadingDao {
  final AppDatabase db;
  ReadingDao(this.db);

  Stream<List<ReadingSession>> watchSessions(int bookId) =>
      (db.select(db.readingSessions)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.startedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  Stream<List<ReadingSession>> watchAll() =>
      db.select(db.readingSessions).watch();

  SimpleSelectStatement<$ReadingSessionsTable, ReadingSession> _active(
    int bookId,
  ) => db.select(db.readingSessions)
    ..where((t) => t.bookId.equals(bookId) & t.endedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
    ..limit(1);

  Stream<ReadingSession?> watchActive(int bookId) =>
      _active(bookId).watchSingleOrNull();

  Future<ReadingSession?> getActive(int bookId) =>
      _active(bookId).getSingleOrNull();

  Future<ReadingSession?> getById(int id) => (db.select(
    db.readingSessions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> start(int bookId, DateTime startedAt, int startPage) {
    return db.transaction(() async {
      if (await getActive(bookId) != null) {
        throw StateError('Book $bookId already has a running session');
      }
      return db
          .into(db.readingSessions)
          .insert(
            ReadingSessionsCompanion.insert(
              bookId: bookId,
              startedAt: startedAt,
              startPage: Value(startPage),
            ),
          );
    });
  }

  Future<void> finish(int id, DateTime endedAt, int endPage) async {
    final session = await getById(id);
    if (session == null) return;
    final seconds = endedAt.difference(session.startedAt).inSeconds;
    await (db.update(db.readingSessions)..where((t) => t.id.equals(id))).write(
      ReadingSessionsCompanion(
        endedAt: Value(endedAt),
        durationSeconds: Value(seconds < 0 ? 0 : seconds),
        endPage: Value(endPage),
      ),
    );
  }

  Future<int> log(ReadingSessionsCompanion session) =>
      db.into(db.readingSessions).insert(session);

  Future<void> delete(int id) =>
      (db.delete(db.readingSessions)..where((t) => t.id.equals(id))).go();

  Future<void> setCurrentPage(int bookId, int page) =>
      (db.update(db.books)..where((t) => t.id.equals(bookId))).write(
        BooksCompanion(currentPage: Value(page < 0 ? 0 : page)),
      );
}
