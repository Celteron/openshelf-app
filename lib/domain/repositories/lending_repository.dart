import 'package:openreads/data/database/app_database.dart';

abstract class LendingRepository {
  /// Lends a book. A book can be lent to one person at a time: throws
  /// [StateError] when it already has an active lending.
  Future<int> lend(
    int bookId, {
    required String borrowerName,
    DateTime? expectedReturn,
  });

  /// Marks a lending as returned. Returning twice keeps the first date;
  /// an unknown id is ignored.
  Future<void> markReturned(int lendingId, DateTime returnedAt);

  /// Every lending of the book, newest first (active and returned).
  Stream<List<LendingData>> watchHistory(int bookId);

  /// The book's active lending, if any.
  Future<LendingData?> getActiveLending(int bookId);

  Stream<LendingData?> watchActiveLending(int bookId);
}
