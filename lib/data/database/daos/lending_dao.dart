import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class LendingDao {
  final AppDatabase db;
  LendingDao(this.db);

  Future<int> insert(LendingCompanion lending) =>
      db.into(db.lending).insert(lending);

  Future<int> update(int id, LendingCompanion lending) =>
      (db.update(db.lending)..where((t) => t.id.equals(id))).write(lending);

  Stream<LendingData?> watchActiveLending(int bookId) {
    final query = db.select(db.lending)
      ..where((t) => t.bookId.equals(bookId) & t.returnedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lentAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<LendingData?> activeLending(int bookId) {
    final query = db.select(db.lending)
      ..where((t) => t.bookId.equals(bookId) & t.returnedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lentAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }
}
