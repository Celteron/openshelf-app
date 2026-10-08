import 'dart:math' as math;

import 'package:openreads/data/database/app_database.dart';

/// Pages covered by one session (never negative; an open session counts 0).
int sessionPages(ReadingSession session) {
  final end = session.endPage;
  if (end == null) return 0;
  return math.max(0, end - session.startPage);
}

/// Aggregated reading metrics over *completed* sessions (FR-P2-02).
///
/// Pure derivation over session rows so it can be unit-tested without a
/// database (Constitution Article IV.2).
class ReadingStats {
  final int sessionCount;
  final int totalSeconds;
  final int totalPages;

  /// Total seconds/pages of the sessions that qualify for the speed metric
  /// (pages > 0 and duration > 0); kept separate so that a session without
  /// page information does not skew pages/hour.
  final int _speedSeconds;
  final int _speedPages;

  const ReadingStats({
    required this.sessionCount,
    required this.totalSeconds,
    required this.totalPages,
    int speedSeconds = 0,
    int speedPages = 0,
  }) : _speedSeconds = speedSeconds,
       _speedPages = speedPages;

  const ReadingStats.empty()
    : sessionCount = 0,
      totalSeconds = 0,
      totalPages = 0,
      _speedSeconds = 0,
      _speedPages = 0;

  /// Average reading speed, or `null` when no session qualifies.
  double? get pagesPerHour =>
      _speedSeconds <= 0 ? null : _speedPages / (_speedSeconds / 3600.0);

  factory ReadingStats.compute(Iterable<ReadingSession> sessions) {
    var count = 0;
    var seconds = 0;
    var pages = 0;
    var speedSeconds = 0;
    var speedPages = 0;

    for (final session in sessions) {
      if (session.endedAt == null) continue;
      count++;
      final sessionSeconds = math.max(0, session.durationSeconds);
      final sessionPageCount = sessionPages(session);
      seconds += sessionSeconds;
      pages += sessionPageCount;
      if (sessionSeconds > 0 && sessionPageCount > 0) {
        speedSeconds += sessionSeconds;
        speedPages += sessionPageCount;
      }
    }

    return ReadingStats(
      sessionCount: count,
      totalSeconds: seconds,
      totalPages: pages,
      speedSeconds: speedSeconds,
      speedPages: speedPages,
    );
  }
}

/// When a book was read and for how long, derived from its sessions: the first
/// start, the last end of a completed session and the summed reading time.
///
/// Pure so it can be tested without a database (Constitution IV.2).
class ReadingSummary {
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// Summed time of the completed sessions; zero when only dates are known
  /// (e.g. imported from a source without reading time).
  final Duration readingTime;

  const ReadingSummary({
    this.startedAt,
    this.finishedAt,
    this.readingTime = Duration.zero,
  });

  bool get isEmpty =>
      startedAt == null && finishedAt == null && readingTime == Duration.zero;

  /// Calendar days from start to end, both days included; `null` unless both
  /// are known.
  int? get spanDays {
    final start = startedAt;
    final end = finishedAt;
    if (start == null || end == null) return null;
    // UTC midnights: local ones are only 23 h apart across a DST change, which
    // would drop a day.
    final from = DateTime.utc(start.year, start.month, start.day);
    final to = DateTime.utc(end.year, end.month, end.day);
    return math.max(0, to.difference(from).inDays) + 1;
  }

  /// [manualSeconds] is reading time entered without a dated session
  /// (`Books.readingSeconds`); it is added to the sessions' time.
  factory ReadingSummary.compute(
    Iterable<ReadingSession> sessions, {
    int manualSeconds = 0,
  }) {
    DateTime? start;
    DateTime? end;
    var seconds = math.max(0, manualSeconds);
    for (final session in sessions) {
      if (start == null || session.startedAt.isBefore(start)) {
        start = session.startedAt;
      }
      final ended = session.endedAt;
      if (ended == null) continue;
      if (end == null || ended.isAfter(end)) end = ended;
      seconds += math.max(0, session.durationSeconds);
    }
    return ReadingSummary(
      startedAt: start,
      finishedAt: end,
      readingTime: Duration(seconds: seconds),
    );
  }
}
