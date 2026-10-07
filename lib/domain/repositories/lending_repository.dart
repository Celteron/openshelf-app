import 'package:openreads/data/database/app_database.dart';

abstract class LendingRepository {
  Future<int> lend(
    int bookId, {
    required String borrowerName,
    DateTime? expectedReturn,
  });

  Future<void> markReturned(int lendingId, DateTime returnedAt);

  Stream<LendingData?> watchActiveLending(int bookId);
}
