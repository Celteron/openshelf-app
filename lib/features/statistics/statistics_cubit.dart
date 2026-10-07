import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/statistics.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';

sealed class StatisticsState {
  const StatisticsState();
}

class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

class StatisticsLoaded extends StatisticsState {
  final BookStatistics statistics;
  const StatisticsLoaded(this.statistics);
}

class StatisticsError extends StatisticsState {
  const StatisticsError();
}

/// Computes collection metrics reactively: every book change recomputes the
/// aggregate (spec §6.5).
class StatisticsCubit extends Cubit<StatisticsState> {
  final BookRepository _bookRepository;
  final LocationRepository _locationRepository;
  StreamSubscription<StatisticsState>? _subscription;

  StatisticsCubit(this._bookRepository, this._locationRepository)
    : super(const StatisticsLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _bookRepository
        .watchBooks()
        .asyncMap((books) async {
          try {
            final locations = await _locationRepository.getLocations();
            return StatisticsLoaded(BookStatistics.compute(books, locations));
          } catch (_) {
            return const StatisticsError();
          }
        })
        .listen(emit, onError: (_) => emit(const StatisticsError()));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
