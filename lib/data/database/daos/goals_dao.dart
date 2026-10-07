import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class GoalsDao {
  final AppDatabase db;
  GoalsDao(this.db);

  Stream<ReadingGoal?> watch(int year) => (db.select(
    db.readingGoals,
  )..where((t) => t.year.equals(year))).watchSingleOrNull();

  Future<void> upsert(int year, int targetBooks, {int? targetPages}) => db
      .into(db.readingGoals)
      .insertOnConflictUpdate(
        ReadingGoalsCompanion.insert(
          year: Value(year),
          targetBooks: targetBooks,
          targetPages: Value(targetPages),
        ),
      );

  Future<void> delete(int year) =>
      (db.delete(db.readingGoals)..where((t) => t.year.equals(year))).go();
}
