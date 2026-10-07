import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/lending_repository.dart';

sealed class LendingState {
  const LendingState();
}

class LendingIdle extends LendingState {
  const LendingIdle();
}

class LendingActive extends LendingState {
  final LendingData lending;
  const LendingActive(this.lending);
}

class LendingAvailable extends LendingState {
  const LendingAvailable();
}

/// Tracks the active lending state of a book and drives the badge overlay
/// (spec §6.3, US6).
class LendingCubit extends Cubit<LendingState> {
  final LendingRepository _repository;
  StreamSubscription<LendingData?>? _subscription;

  LendingCubit(this._repository) : super(const LendingIdle());

  void watch(int bookId) {
    _subscription?.cancel();
    _subscription = _repository
        .watchActiveLending(bookId)
        .listen(
          (lending) => emit(
            lending == null ? const LendingAvailable() : LendingActive(lending),
          ),
          onError: (_) => emit(const LendingAvailable()),
        );
  }

  /// All lendings of the book, newest first.
  Stream<List<LendingData>> history(int bookId) =>
      _repository.watchHistory(bookId);

  Future<void> lend(
    int bookId, {
    required String borrowerName,
    DateTime? expectedReturn,
  }) async {
    await _repository.lend(
      bookId,
      borrowerName: borrowerName,
      expectedReturn: expectedReturn,
    );
  }

  Future<void> markReturned(int lendingId) async {
    await _repository.markReturned(lendingId, DateTime.now());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
