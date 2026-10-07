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
    if (targetBooks <= 0) {
      throw ArgumentError.value(targetBooks, 'targetBooks', 'must be > 0');
    }
    if (targetPages != null && targetPages <= 0) {
      throw ArgumentError.value(targetPages, 'targetPages', 'must be > 0');
    }
    return _dao.upsert(year, targetBooks, targetPages: targetPages);
  }

  @override
  Future<void> clearGoal(int year) => _dao.delete(year);
}
