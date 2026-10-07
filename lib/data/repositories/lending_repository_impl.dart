import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/lending_dao.dart';
import 'package:openreads/domain/repositories/lending_repository.dart';

class LendingRepositoryImpl implements LendingRepository {
  final LendingDao _dao;

  LendingRepositoryImpl(this._dao);

  @override
  Future<int> lend(
    int bookId, {
    required String borrowerName,
    DateTime? expectedReturn,
  }) => _dao.insert(
    LendingCompanion.insert(
      bookId: bookId,
      borrowerName: borrowerName,
      lentAt: DateTime.now(),
      expectedReturn: Value(expectedReturn),
    ),
  );

  @override
  Future<void> markReturned(int lendingId, DateTime returnedAt) =>
      _dao.update(lendingId, LendingCompanion(returnedAt: Value(returnedAt)));

  @override
  Stream<LendingData?> watchActiveLending(int bookId) =>
      _dao.watchActiveLending(bookId);
}
