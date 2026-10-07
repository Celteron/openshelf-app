import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/models/statistics.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/goal_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:rxdart/rxdart.dart';

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

/// Computes collection metrics reactively: every book, goal or reading
/// session change recomputes the aggregate (spec §6.5, Phase 2 FR-P2-08).
///
/// The goal and reading repositories are optional so the Phase 1 collection
/// statistics keep working without them.
class StatisticsCubit extends Cubit<StatisticsState> {
  final BookRepository _bookRepository;
  final LocationRepository _locationRepository;
  final GoalRepository? _goalRepository;
  final ReadingRepository? _readingRepository;
  final DateTime Function() _now;
  StreamSubscription<StatisticsState>? _subscription;

  /// The selected year (`null` = all years).
  final _year = BehaviorSubject<int?>.seeded(null);

  StatisticsCubit(
    this._bookRepository,
    this._locationRepository, {
    GoalRepository? goalRepository,
    ReadingRepository? readingRepository,
    DateTime Function()? clock,
  }) : _goalRepository = goalRepository,
       _readingRepository = readingRepository,
       _now = clock ?? DateTime.now,
       super(const StatisticsLoading());

  /// The calendar year the goal card refers to: the selected year, else the
  /// current one.
  int get goalYear => _year.value ?? _now().year;

  /// The selected year, or `null` for all years.
  int? get selectedYear => _year.value;

  /// Shows the statistics of one year (`null` = all years).
  void selectYear(int? year) => _year.add(year);

  void load() {
    _subscription?.cancel();
    final sessions =
        _readingRepository?.watchAllSessions() ??
        Stream.value(const <ReadingSession>[]);

    _subscription = _year
        .distinct()
        .switchMap(
          (year) =>
              Rx.combineLatest3<
                List<Book>,
                ReadingGoal?,
                List<ReadingSession>,
                (int?, List<Book>, ReadingGoal?, List<ReadingSession>)
              >(
                _bookRepository.watchBooks(),
                _goalRepository?.watchGoal(year ?? _now().year) ??
                    Stream.value(null),
                sessions,
                (books, goal, sessions) => (year, books, goal, sessions),
              ),
        )
        .asyncMap(_compute)
        .listen(emit, onError: (_) => emit(const StatisticsError()));
  }

  Future<StatisticsState> _compute(
    (int?, List<Book>, ReadingGoal?, List<ReadingSession>) input,
  ) async {
    try {
      final (year, books, goal, allSessions) = input;
      // Sessions of the books in scope only (all books, or the year's).
      final scopeIds = year == null
          ? null
          : {
              for (final b in books)
                if (b.status == BookStatus.read &&
                    BookStatistics.finishedOn(b).year == year)
                  b.id,
            };
      final sessions = scopeIds == null
          ? allSessions
          : [
              for (final s in allSessions)
                if (scopeIds.contains(s.bookId)) s,
            ];
      final locations = await _locationRepository.getLocations();
      return StatisticsLoaded(
        BookStatistics.compute(
          books,
          locations,
          goal: goal == null
              ? null
              : GoalProgress.compute(
                  year: goal.year,
                  target: goal.targetBooks,
                  targetPages: goal.targetPages,
                  books: books,
                  now: _now(),
                ),
          reading: ReadingStats.compute(sessions),
          year: year,
          sessions: sessions,
        ),
      );
    } catch (_) {
      return const StatisticsError();
    }
  }

  Future<void> setGoal(int targetBooks, {int? targetPages}) =>
      _goalRepository?.setGoal(
        goalYear,
        targetBooks,
        targetPages: targetPages,
      ) ??
      Future.value();

  Future<void> clearGoal() =>
      _goalRepository?.clearGoal(goalYear) ?? Future.value();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _year.close();
    return super.close();
  }
}
