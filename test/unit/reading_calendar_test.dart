import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/reading_calendar.dart';

ReadingSession session(
  int bookId,
  DateTime start, {
  DateTime? end,
  int seconds = 0,
}) => ReadingSession(
  id: start.microsecondsSinceEpoch,
  bookId: bookId,
  startedAt: start,
  endedAt: end,
  durationSeconds: seconds,
  startPage: 0,
);

void main() {
  DateTime d(int month, int day, [int hour = 12, int minute = 0]) =>
      DateTime(2026, month, day, hour, minute);

  test('reading time lands on the day the session started', () {
    final calendar = ReadingCalendar.of([
      session(1, d(3, 4, 23, 50), end: d(3, 5, 0, 10), seconds: 20 * 60),
    ]);

    expect(calendar.dayOf(d(3, 4)).seconds, 20 * 60);
    expect(calendar.dayOf(d(3, 5)).seconds, 0);
  });

  test('sessions of one day add up and set the level by time read', () {
    final calendar = ReadingCalendar.of([
      session(1, d(3, 4, 8), end: d(3, 4, 8, 10), seconds: 10 * 60),
      session(1, d(3, 4, 20), end: d(3, 4, 21), seconds: 50 * 60),
    ]);

    final day = calendar.dayOf(d(3, 4));
    expect(day.seconds, 60 * 60);
    expect(day.level, 4);
  });

  test('levels step with the minutes read', () {
    int levelFor(int minutes) => ReadingCalendar.of([
      session(1, d(1, 1), end: d(1, 1, 13), seconds: minutes * 60),
    ]).dayOf(d(1, 1)).level;

    expect(
      [levelFor(5), levelFor(14), levelFor(15), levelFor(44)],
      [2, 2, 3, 3],
    );
    expect(
      [levelFor(45), levelFor(89), levelFor(90), levelFor(300)],
      [4, 4, 5, 5],
    );
  });

  test('a day without anything is empty', () {
    final day = ReadingCalendar.of(const []).dayOf(d(5, 5));

    expect((day.level, day.seconds, day.booksInProgress), (0, 0, 0));
  });

  test('start and end dates alone paint every day in between', () {
    // The import of a source without reading times: dates, duration 0.
    final calendar = ReadingCalendar.of([session(1, d(1, 1), end: d(1, 5))]);

    for (var day = 1; day <= 5; day++) {
      final cell = calendar.dayOf(d(1, day));
      expect((cell.level, cell.booksInProgress), (1, 1), reason: 'day $day');
    }
    expect(calendar.dayOf(d(1, 6)).level, 0);
    expect(calendar.dayOf(DateTime(2025, 12, 31)).level, 0);
  });

  test('days between two sessions of a book count as in progress', () {
    final calendar = ReadingCalendar.of([
      session(1, d(1, 1), end: d(1, 1, 13), seconds: 30 * 60),
      session(1, d(1, 10), end: d(1, 10, 13), seconds: 30 * 60),
    ]);

    expect(calendar.dayOf(d(1, 1)).level, 3);
    expect(calendar.dayOf(d(1, 5)).level, 1, reason: 'in progress only');
    expect(calendar.dayOf(d(1, 10)).level, 3);
  });

  test('books read side by side are counted on the days they overlap', () {
    final calendar = ReadingCalendar.of([
      session(1, d(2, 1), end: d(2, 10)),
      session(2, d(2, 5), end: d(2, 15)),
    ]);

    expect(calendar.dayOf(d(2, 3)).booksInProgress, 1);
    expect(calendar.dayOf(d(2, 7)).booksInProgress, 2);
    expect(calendar.dayOf(d(2, 12)).booksInProgress, 1);
  });

  test('a running timer marks its start day only', () {
    final calendar = ReadingCalendar.of([session(1, d(4, 1))]);

    expect(calendar.dayOf(d(4, 1)).level, 1);
    expect(calendar.dayOf(d(4, 2)).level, 0);
  });

  test('an end before the start does not invent days', () {
    final calendar = ReadingCalendar.of([session(1, d(4, 10), end: d(4, 2))]);

    expect(calendar.dayOf(d(4, 10)).level, 1);
    expect(calendar.dayOf(d(4, 5)).level, 0);
  });

  test('years are listed newest first, with their reading days', () {
    final calendar = ReadingCalendar.of([
      session(1, DateTime(2024, 12, 30), end: DateTime(2025, 1, 2)),
      session(
        2,
        DateTime(2025, 6, 1),
        end: DateTime(2025, 6, 1, 13),
        seconds: 600,
      ),
    ]);

    expect(calendar.years, [2025, 2024]);
    expect(calendar.daysWithTime(2025), 1);
    expect(calendar.daysInProgress(2025), 2 + 1, reason: 'Jan 1-2 and Jun 1');
    expect(calendar.daysInProgress(2024), 2);
  });
}
