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
  }) async {
    final name = borrowerName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(
        borrowerName,
        'borrowerName',
        'must not be blank',
      );
    }
    if (await _dao.activeLending(bookId) != null) {
      throw StateError('Book $bookId is already lent out');
    }
    return _dao.insert(
      LendingCompanion.insert(
        bookId: bookId,
        borrowerName: name,
        lentAt: DateTime.now(),
        expectedReturn: Value(expectedReturn),
      ),
    );
  }

  @override
  Future<void> markReturned(int lendingId, DateTime returnedAt) =>
      _dao.markReturned(lendingId, returnedAt);

  @override
  Stream<List<LendingData>> watchHistory(int bookId) =>
      _dao.watchHistory(bookId);

  @override
  Future<LendingData?> getActiveLending(int bookId) =>
      _dao.activeLending(bookId);

  @override
  Stream<LendingData?> watchActiveLending(int bookId) =>
      _dao.watchActiveLending(bookId);
}
