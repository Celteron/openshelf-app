import 'package:openreads/data/database/app_database.dart';

/// Yearly reading goals (Phase 2).
abstract class GoalRepository {
  Stream<ReadingGoal?> watchGoal(int year);

  /// Sets the book goal and, optionally, a page goal for [year].
  Future<void> setGoal(int year, int targetBooks, {int? targetPages});

  Future<void> clearGoal(int year);
}
