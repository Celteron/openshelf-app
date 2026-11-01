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

  /// See `ReadingRepository.setReadingDates`. A moved edge never leaves a
  /// session ending before it starts.
  Future<void> setDates(int bookId, {DateTime? start, DateTime? end}) =>
      db.transaction(() async {
        if (start == null && end == null) return;
        Future<List<ReadingSession>> sessions() => (db.select(
          db.readingSessions,
        )..where((t) => t.bookId.equals(bookId))).get();

        final existing = await sessions();
        if (existing.isEmpty) {
          await log(
            ReadingSessionsCompanion.insert(
              bookId: bookId,
              startedAt: (start ?? end)!,
              endedAt: Value(end ?? start),
            ),
          );
        } else {
          if (start != null) {
            final first = existing.reduce(
              (a, b) => b.startedAt.isBefore(a.startedAt) ? b : a,
            );
            final ended = first.endedAt;
            await _move(
              first.id,
              startedAt: start,
              endedAt: ended != null && ended.isBefore(start) ? start : ended,
            );
          }
          final finished = [
            for (final s in await sessions())
              if (s.endedAt != null) s,
          ];
          if (end != null && finished.isNotEmpty) {
            final last = finished.reduce(
              (a, b) => b.endedAt!.isAfter(a.endedAt!) ? b : a,
            );
            await _move(
              last.id,
              startedAt: last.startedAt.isAfter(end) ? end : last.startedAt,
              endedAt: end,
            );
          }
        }
        if (end != null) {
          await (db.update(db.books)..where((t) => t.id.equals(bookId))).write(
            BooksCompanion(finishedAt: Value(end)),
          );
        }
      });

  Future<void> _move(
    int id, {
    required DateTime startedAt,
    required DateTime? endedAt,
  }) => (db.update(db.readingSessions)..where((t) => t.id.equals(id))).write(
    ReadingSessionsCompanion(
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
    ),
  );

  Future<void> setCurrentPage(int bookId, int page) =>
      (db.update(db.books)..where((t) => t.id.equals(bookId))).write(
        BooksCompanion(currentPage: Value(page < 0 ? 0 : page)),
      );
}
