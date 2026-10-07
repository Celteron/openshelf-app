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
