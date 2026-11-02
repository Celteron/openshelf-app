import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/models/shelf_partition.dart';
import 'package:openreads/domain/models/statistics.dart';

/// A reading year in a few numbers, for the year-in-review cards. Pure, so it
/// can be tested without a database or a widget.
class YearReview {
  static const _maxCovers = 12;

  final int year;

  /// Books finished in [year]; volumes count, their slipcase does not.
  final int books;
  final int pages;
  final int readingSeconds;

  /// Days of [year] on which a reading session started or ended; the days
  /// between two sessions of a book do not count, only real events do.
  final int readingDays;

  /// The finished book with the most pages; `null` without page counts.
  final Book? longest;

  /// The best rated finished book (the latest finished wins a tie); `null`
  /// when nothing is rated.
  final Book? best;

  /// The author with the most finished books, as (name, count).
  final (String, int)? topAuthor;

  /// The month (1–12) with the most finished books, as (month, count).
  final (int, int)? bestMonth;

  /// Up to [_maxCovers] finished books, best rated first.
  final List<Book> covers;

  const YearReview({
    required this.year,
    required this.books,
    required this.pages,
    required this.readingSeconds,
    required this.readingDays,
    required this.longest,
    required this.best,
    required this.topAuthor,
    required this.bestMonth,
    required this.covers,
  });

  bool get isEmpty => books == 0;

  factory YearReview.of(
    int year,
    List<Book> allBooks,
    Iterable<ReadingSession> sessions,
  ) {
    final finished = [
      for (final b in ShelfPartition.of(allBooks).readable)
        if (b.status == BookStatus.read &&
            BookStatistics.finishedOn(b).year == year)
          b,
    ];

    final authorCounts = <String, int>{};
    final monthCounts = <int, int>{};
    var pages = 0;
    var manualSeconds = 0;
    for (final b in finished) {
      pages += b.pageCount ?? 0;
      manualSeconds += b.readingSeconds ?? 0;
      for (final a
          in b.authors.map((a) => a.trim()).where((a) => a.isNotEmpty)) {
        authorCounts[a] = (authorCounts[a] ?? 0) + 1;
      }
      final month = BookStatistics.finishedOn(b).month;
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
    }

    final yearSessions = [
      for (final s in sessions)
        if (s.startedAt.year == year) s,
    ];

    Book? pick(bool Function(Book) where, int Function(Book, Book) better) {
      Book? winner;
      for (final b in finished.where(where)) {
        if (winner == null || better(b, winner) > 0) winner = b;
      }
      return winner;
    }

    DateTime when(Book b) => BookStatistics.finishedOn(b);
    DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);

    final covers = [...finished]
      ..sort(
        (a, b) => b.rating != a.rating
            ? b.rating.compareTo(a.rating)
            : when(b).compareTo(when(a)),
      );

    return YearReview(
      year: year,
      books: finished.length,
      pages: pages,
      readingSeconds:
          ReadingStats.compute(yearSessions).totalSeconds + manualSeconds,
      readingDays: {
        for (final s in yearSessions) day(s.startedAt),
        for (final s in yearSessions)
          if (s.endedAt case final end? when end.year == year) day(end),
      }.length,
      longest: pick(
        (b) => (b.pageCount ?? 0) > 0,
        (a, b) => a.pageCount!.compareTo(b.pageCount!),
      ),
      best: pick(
        (b) => b.rating > 0,
        (a, b) => a.rating != b.rating
            ? a.rating.compareTo(b.rating)
            : when(a).compareTo(when(b)),
      ),
      topAuthor: _top(authorCounts, (a, b) => a.compareTo(b)),
      bestMonth: _top(monthCounts, (a, b) => a.compareTo(b)),
      covers: covers.take(_maxCovers).toList(),
    );
  }

  /// The key with the highest count; a tie goes to the smaller key.
  static (K, int)? _top<K>(Map<K, int> counts, int Function(K, K) compare) {
    (K, int)? best;
    for (final e in counts.entries) {
      if (best == null ||
          e.value > best.$2 ||
          (e.value == best.$2 && compare(e.key, best.$1) < 0)) {
        best = (e.key, e.value);
      }
    }
    return best;
  }
}
