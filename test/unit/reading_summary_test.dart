import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/reading_stats.dart';

ReadingSession session(
  DateTime start,
  DateTime? end, {
  int seconds = 0,
  int id = 1,
}) => ReadingSession(
  id: id,
  bookId: 1,
  startedAt: start,
  endedAt: end,
  durationSeconds: seconds,
  startPage: 0,
);

void main() {
  test('is empty without sessions', () {
    final summary = ReadingSummary.compute(const []);
    expect(summary.isEmpty, isTrue);
    expect(summary.startedAt, isNull);
    expect(summary.finishedAt, isNull);
    expect(summary.readingTime, Duration.zero);
    expect(summary.spanDays, isNull);
  });

  test('start is the earliest start, end the latest end', () {
    final summary = ReadingSummary.compute([
      session(DateTime(2026, 3, 5), DateTime(2026, 3, 6), id: 1),
      session(DateTime(2026, 3, 1), DateTime(2026, 3, 2), id: 2),
      session(DateTime(2026, 3, 9), DateTime(2026, 3, 10), id: 3),
    ]);
    expect(summary.startedAt, DateTime(2026, 3, 1));
    expect(summary.finishedAt, DateTime(2026, 3, 10));
    expect(summary.spanDays, 10, reason: 'inclusive of both days');
  });

  test('reading time sums completed sessions only', () {
    final summary = ReadingSummary.compute([
      session(DateTime(2026, 3, 1), DateTime(2026, 3, 1, 1), seconds: 3600),
      session(DateTime(2026, 3, 2), DateTime(2026, 3, 2, 1), seconds: 1800),
      session(DateTime(2026, 3, 3), null, seconds: 99999),
    ]);
    expect(summary.readingTime, const Duration(minutes: 90));
  });

  test('a running session gives a start but no end', () {
    final summary = ReadingSummary.compute([
      session(DateTime(2026, 3, 3), null),
    ]);
    expect(summary.startedAt, DateTime(2026, 3, 3));
    expect(summary.finishedAt, isNull);
    expect(summary.spanDays, isNull);
  });

  test('start and end on one day span one day', () {
    final summary = ReadingSummary.compute([
      session(DateTime(2026, 3, 3, 20), DateTime(2026, 3, 3, 22)),
    ]);
    expect(summary.spanDays, 1);
  });

  test('counts calendar days across a daylight-saving change', () {
    // Local midnights around the spring change are only 23 h apart.
    for (final (start, end) in [
      (DateTime(2025, 3, 29), DateTime(2025, 3, 31)),
      (DateTime(2025, 10, 25), DateTime(2025, 10, 27)),
    ]) {
      final summary = ReadingSummary.compute([session(start, end)]);
      expect(summary.spanDays, 3, reason: '$start → $end');
    }
  });

  test('manually entered time is added to the sessions time', () {
    final summary = ReadingSummary.compute([
      session(DateTime(2026, 3, 1), DateTime(2026, 3, 1, 1), seconds: 3600),
    ], manualSeconds: 1800);
    expect(summary.readingTime, const Duration(minutes: 90));
  });

  test('manual time alone is a reading time without dates', () {
    final summary = ReadingSummary.compute(const [], manualSeconds: 19800);
    expect(summary.isEmpty, isFalse);
    expect(summary.readingTime, const Duration(hours: 5, minutes: 30));
    expect(summary.startedAt, isNull);
    expect(summary.spanDays, isNull);
  });
}
