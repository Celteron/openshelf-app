import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/home_summary.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final HomeSummary summary;
  const HomeLoaded(this.summary);
}

class HomeError extends HomeState {
  const HomeError();
}

/// Keeps the home tab's [HomeSummary] in step with the library (FR-R2-19).
class HomeCubit extends Cubit<HomeState> {
  final BookRepository _books;
  final DateTime Function() _now;
  StreamSubscription<Object?>? _subscription;

  HomeCubit(this._books, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const HomeLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _books.watchBooks().listen(
      (books) => emit(HomeLoaded(HomeSummary.of(books, now: _now()))),
      onError: (_) => emit(const HomeError()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
