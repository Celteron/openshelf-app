import 'dart:math' as math;

import 'package:openreads/data/database/app_database.dart';

/// One calendar day of the reading calendar.
class ReadingDay {
  /// Reading time of the sessions that started on this day.
  final int seconds;

  /// Books that were "in progress" on this day: between their first start and
  /// their last end, whether or not a session was logged that day.
  final int booksInProgress;

  const ReadingDay({this.seconds = 0, this.booksInProgress = 0});

  /// 0 = nothing, 1 = a book was in progress, 2..5 = time actually read
  /// (under 15, 45, 90 minutes, and more).
  int get level {
    if (seconds > 0) {
      final minutes = seconds / 60;
      if (minutes < 15) return 2;
      if (minutes < 45) return 3;
      if (minutes < 90) return 4;
      return 5;
    }
    return booksInProgress > 0 ? 1 : 0;
  }
}

/// When the user read, from the dated reading sessions alone.
///
/// Two layers, because the data comes in two kinds: logged reading time
/// (strong) and plain start/end dates, e.g. from an import, which only say a
/// book was in progress (weak). A session counts for the day it started.
class ReadingCalendar {
  static const _empty = ReadingDay();

  final Map<DateTime, ReadingDay> _days;

  const ReadingCalendar._(this._days);

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  factory ReadingCalendar.of(Iterable<ReadingSession> sessions) {
    final seconds = <DateTime, int>{};
    final progress = <DateTime, int>{};
    final byBook = <int, List<ReadingSession>>{};
    for (final s in sessions) {
      (byBook[s.bookId] ??= []).add(s);
      final day = _day(s.startedAt);
      seconds[day] = (seconds[day] ?? 0) + math.max(0, s.durationSeconds);
    }
    for (final list in byBook.values) {
      var first = _day(list.first.startedAt);
      var last = first;
      for (final s in list) {
        final start = _day(s.startedAt);
        if (start.isBefore(first)) first = start;
        final ended = s.endedAt;
        final end = ended == null ? start : _day(ended);
        // An end before the start is bad data: it never shrinks the span.
        final upper = end.isAfter(start) ? end : start;
        if (upper.isAfter(last)) last = upper;
      }
      // Calendar arithmetic, not Duration: a DST change makes a day 23 h.
      for (
        var day = first;
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        progress[day] = (progress[day] ?? 0) + 1;
      }
    }
    return ReadingCalendar._({
      for (final day in {...seconds.keys, ...progress.keys})
        day: ReadingDay(
          seconds: seconds[day] ?? 0,
          booksInProgress: progress[day] ?? 0,
        ),
    });
  }

  ReadingDay dayOf(DateTime date) => _days[_day(date)] ?? _empty;

  /// Years with any reading, newest first.
  List<int> get years =>
      ({for (final d in _days.keys) d.year}.toList()..sort((a, b) => b - a));

  /// Days of [year] on which time was actually logged.
  int daysWithTime(int year) => _days.entries
      .where((e) => e.key.year == year && e.value.seconds > 0)
      .length;

  /// Days of [year] on which at least one book was in progress.
  int daysInProgress(int year) => _days.entries
      .where((e) => e.key.year == year && e.value.level > 0)
      .length;
}
