import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// Progress towards a yearly "books read" goal (FR-P2-08).
class GoalProgress {
  final int year;
  final int target;
  final int completed;

  /// Optional page goal (Openreads `YearlyChallenge.pages`); `null` = none.
  final int? targetPages;

  /// Pages of the books counted for the year (books without a page count add
  /// nothing).
  final int pagesRead;

  /// How many books *should* be finished by now for an even reading pace.
  final double expected;

  const GoalProgress({
    required this.year,
    required this.target,
    required this.completed,
    required this.expected,
    this.targetPages,
    this.pagesRead = 0,
  });

  /// `false` for a pages-only goal (stored with a book target of 0).
  bool get hasBookGoal => target > 0;

  bool get hasPageGoal => targetPages != null && targetPages! > 0;

  /// Page-goal completion in `0.0–1.0`.
  double get pagesFraction =>
      hasPageGoal ? (pagesRead / targetPages!).clamp(0.0, 1.0) : 0.0;

  /// Completion in `0.0–1.0` for progress indicators.
  double get fraction =>
      target <= 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);

  int get remaining => target - completed > 0 ? target - completed : 0;

  bool get reached => hasBookGoal
      ? completed >= target
      : hasPageGoal && pagesRead >= targetPages!;

  /// Positive when ahead of an even pace, negative when behind.
  double get paceDelta => completed - expected;

  /// A book counts for the year in which it was finished; books without a
  /// recorded finish date (e.g. imported ones) fall back to their creation
  /// date so the number stays stable.
  static bool countsForYear(Book book, int year) {
    if (book.status != BookStatus.read) return false;
    return (book.finishedAt ?? book.createdAt).year == year;
  }

  factory GoalProgress.compute({
    required int year,
    required int target,
    required Iterable<Book> books,
    required DateTime now,
    int? targetPages,
  }) {
    final counted = books.where((b) => countsForYear(b, year)).toList();
    final completed = counted.length;
    final pagesRead = counted.fold<int>(
      0,
      (sum, b) => sum + (b.pageCount ?? 0),
    );

    final double elapsed;
    if (year < now.year) {
      elapsed = 1.0;
    } else if (year > now.year) {
      elapsed = 0.0;
    } else {
      final start = DateTime(year);
      final end = DateTime(year + 1);
      elapsed =
          now.difference(start).inMilliseconds /
          end.difference(start).inMilliseconds;
    }

    return GoalProgress(
      year: year,
      target: target,
      completed: completed,
      expected: target * elapsed,
      targetPages: targetPages,
      pagesRead: pagesRead,
    );
  }
}
