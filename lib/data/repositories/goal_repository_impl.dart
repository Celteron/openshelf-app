import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/goals_dao.dart';
import 'package:openreads/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalsDao _dao;

  GoalRepositoryImpl(this._dao);

  @override
  Stream<ReadingGoal?> watchGoal(int year) => _dao.watch(year);

  @override
  Future<void> setGoal(int year, int targetBooks, {int? targetPages}) {
    // Openreads allowed a books goal, a pages goal or both; a pages-only goal
    // is stored with `targetBooks == 0`.
    final pagesOnly = targetBooks == 0 && (targetPages ?? 0) > 0;
    if (targetBooks <= 0 && !pagesOnly) {
      throw ArgumentError.value(
        targetBooks,
        'targetBooks',
        'must be > 0 (or 0 together with a page goal)',
      );
    }
    if (targetPages != null && targetPages <= 0) {
      throw ArgumentError.value(targetPages, 'targetPages', 'must be > 0');
    }
    return _dao.upsert(year, targetBooks, targetPages: targetPages);
  }

  @override
  Future<void> clearGoal(int year) => _dao.delete(year);
}
