import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/reading_stats.dart';

ReadingSession session({
  int seconds = 3600,
  int startPage = 0,
  int? endPage = 30,
  bool ended = true,
}) => ReadingSession(
  id: 1,
  bookId: 1,
  startedAt: DateTime(2026, 1, 1, 20),
  endedAt: ended ? DateTime(2026, 1, 1, 21) : null,
  durationSeconds: seconds,
  startPage: startPage,
  endPage: endPage,
);

Book book({
  BookStatus status = BookStatus.read,
  DateTime? finishedAt,
  DateTime? createdAt,
  int? pages,
}) => Book(
  id: 1,
  title: 'T',
  authors: const ['A'],
  status: status,
  rating: 0,
  pageCount: pages,
  editedFields: const [],
  currentPage: 0,
  finishedAt: finishedAt,
  isFavorite: false,
  createdAt: createdAt ?? DateTime(2020),
  updatedAt: DateTime(2020),
);

void main() {
  group('ReadingStats', () {
    test('computes pages/hour over completed sessions', () {
      final stats = ReadingStats.compute([
        session(seconds: 3600, startPage: 0, endPage: 30),
        session(seconds: 1800, startPage: 30, endPage: 60),
      ]);
      expect(stats.sessionCount, 2);
      expect(stats.totalPages, 60);
      expect(stats.totalSeconds, 5400);
      // 60 pages in 1.5 h.
      expect(stats.pagesPerHour, closeTo(40, 1e-9));
    });

    test('ignores running sessions', () {
      final stats = ReadingStats.compute([
        session(ended: false, endPage: null),
      ]);
      expect(stats.sessionCount, 0);
      expect(stats.pagesPerHour, isNull);
    });

    test('sessions without pages do not skew the speed', () {
      final stats = ReadingStats.compute([
        session(seconds: 3600, startPage: 10, endPage: 10),
        session(seconds: 3600, startPage: 0, endPage: 20),
      ]);
      expect(stats.totalSeconds, 7200);
      expect(stats.pagesPerHour, closeTo(20, 1e-9));
    });

    test('negative page deltas count as zero', () {
      expect(sessionPages(session(startPage: 50, endPage: 10)), 0);
    });

    test('empty input yields no speed', () {
      expect(const ReadingStats.empty().pagesPerHour, isNull);
      expect(ReadingStats.compute(const []).sessionCount, 0);
    });
  });

  group('GoalProgress', () {
    final now = DateTime(2026, 7, 2, 12); // roughly half-way through 2026

    test('counts only books finished in the year', () {
      final p = GoalProgress.compute(
        year: 2026,
        target: 10,
        now: now,
        books: [
          book(finishedAt: DateTime(2026, 2, 1)),
          book(finishedAt: DateTime(2025, 12, 31)),
          book(status: BookStatus.reading, finishedAt: DateTime(2026, 3, 1)),
          // No finish date → falls back to createdAt.
          book(createdAt: DateTime(2026, 5, 5)),
        ],
      );
      expect(p.completed, 2);
      expect(p.remaining, 8);
      expect(p.fraction, closeTo(0.2, 1e-9));
      expect(p.reached, isFalse);
    });

    test('page goal sums the pages of the books counted for the year', () {
      final p = GoalProgress.compute(
        year: 2026,
        target: 10,
        targetPages: 4000,
        now: now,
        books: [
          book(finishedAt: DateTime(2026, 2, 1), pages: 300),
          book(finishedAt: DateTime(2026, 3, 1), pages: 700),
          book(finishedAt: DateTime(2026, 4, 1)), // unknown page count
          book(finishedAt: DateTime(2025, 12, 31), pages: 999), // other year
          book(status: BookStatus.reading, pages: 500), // not finished
        ],
      );
      expect(p.hasPageGoal, isTrue);
      expect(p.pagesRead, 1000);
      expect(p.pagesFraction, closeTo(0.25, 1e-9));
    });

    test('without a page goal there is no page progress', () {
      final p = GoalProgress.compute(
        year: 2026,
        target: 10,
        now: now,
        books: [book(finishedAt: DateTime(2026, 2, 1), pages: 300)],
      );
      expect(p.hasPageGoal, isFalse);
      expect(p.pagesFraction, 0.0);
    });

    test('the page fraction is capped at 1', () {
      final p = GoalProgress.compute(
        year: 2026,
        target: 10,
        targetPages: 100,
        now: now,
        books: [book(finishedAt: DateTime(2026, 2, 1), pages: 300)],
      );
      expect(p.pagesFraction, 1.0);
    });

    test('pace is relative to elapsed year', () {
      final p = GoalProgress.compute(
        year: 2026,
        target: 10,
        now: now,
        books: [
          for (var i = 0; i < 7; i++) book(finishedAt: DateTime(2026, 3)),
        ],
      );
      expect(p.expected, closeTo(5, 0.1));
      expect(p.paceDelta, greaterThan(1.5));
    });

    test('fraction is capped and goal reached', () {
      final p = GoalProgress.compute(
        year: 2026,
        target: 1,
        now: now,
        books: [
          book(finishedAt: DateTime(2026, 1, 5)),
          book(finishedAt: DateTime(2026, 1, 6)),
        ],
      );
      expect(p.fraction, 1.0);
      expect(p.remaining, 0);
      expect(p.reached, isTrue);
    });

    test('past and future years use full / zero elapsed time', () {
      expect(
        GoalProgress.compute(
          year: 2025,
          target: 12,
          now: now,
          books: [],
        ).expected,
        12,
      );
      expect(
        GoalProgress.compute(
          year: 2027,
          target: 12,
          now: now,
          books: [],
        ).expected,
        0,
      );
    });
  });
}
