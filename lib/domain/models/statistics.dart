import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/models/shelf_partition.dart';

/// Books and pages finished in one calendar month.
class MonthStat {
  /// 1–12.
  final int month;
  final int books;
  final int pages;

  const MonthStat(this.month, this.books, this.pages);
}

/// Aggregated collection metrics shown on the statistics dashboard.
///
/// Pure data + derivation logic: computing is a pure function over the book,
/// location and session rows, so it can be unit-tested without a database.
///
/// With a [year], only books *finished in that year* are counted (the same rule
/// the yearly goal uses: the finish date, or the date the book was added when it
/// has none); without one, the whole library is.
class BookStatistics {
  final int totalBooks;
  final Map<BookStatus, int> statusCounts;
  final int pagesRead;

  /// (name, count) pairs ordered descending by count.
  final List<NameCount> topLocations;
  final List<NameCount> topAuthors;

  /// Progress of the shown year's goal; `null` when no goal is set
  /// (Phase 2).
  final GoalProgress? goal;

  /// Reading speed and totals over completed sessions (Phase 2).
  final ReadingStats reading;

  /// The selected year, or `null` for all years.
  final int? year;

  /// Years in which books were finished, newest first.
  final List<int> years;

  /// Finished books and pages per month, January to December. Twelve entries
  /// (all zero when nothing was finished); empty only for hand-built values.
  final List<MonthStat> monthly;

  /// Average rating of the rated finished books, or `null` when there are none.
  final double? averageRating;

  /// Average page count of the finished books that have one.
  final int? averagePages;

  /// Average reading time of the finished books that have one.
  final Duration? averageReadingTime;

  /// Finished books with the most / fewest pages (`count` = pages).
  final NameCount? longestBook;
  final NameCount? shortestBook;

  /// Finished books read fastest / slowest (`count` = seconds).
  final NameCount? fastestBook;
  final NameCount? slowestBook;

  const BookStatistics({
    required this.totalBooks,
    required this.statusCounts,
    required this.pagesRead,
    required this.topLocations,
    required this.topAuthors,
    this.goal,
    this.reading = const ReadingStats.empty(),
    this.year,
    this.years = const [],
    this.monthly = const [],
    this.averageRating,
    this.averagePages,
    this.averageReadingTime,
    this.longestBook,
    this.shortestBook,
    this.fastestBook,
    this.slowestBook,
  });

  static const _maxEntries = 5;

  /// The day a finished book counts for: its finish date, else when it was
  /// added.
  static DateTime finishedOn(Book book) => book.finishedAt ?? book.createdAt;

  factory BookStatistics.compute(
    List<Book> allBooks,
    List<Location> locations, {
    GoalProgress? goal,
    ReadingStats reading = const ReadingStats.empty(),
    int? year,
    Iterable<ReadingSession> sessions = const [],
  }) {
    // Reading numbers count single books and volumes, locations the physical
    // objects (ADR-0003): a slipcase is neither read nor shelved twice.
    final shelf = ShelfPartition.of(allBooks);
    final years = {
      for (final b in shelf.readable)
        if (b.status == BookStatus.read) finishedOn(b).year,
    }.toList()..sort((a, b) => b.compareTo(a));

    final books = year == null
        ? shelf.readable
        : [
            for (final b in shelf.readable)
              if (b.status == BookStatus.read && finishedOn(b).year == year) b,
          ];
    final shelved = {for (final b in books) shelf.shelvedAs(b)};

    final statusCounts = <BookStatus, int>{
      for (final status in BookStatus.values) status: 0,
    };
    var pagesRead = 0;

    final locationCounts = <int, int>{};
    final authorCounts = <String, int>{};
    final monthBooks = List<int>.filled(12, 0);
    final monthPages = List<int>.filled(12, 0);
    final finished = <Book>[];

    for (final book in books) {
      statusCounts[book.status] = (statusCounts[book.status] ?? 0) + 1;
      if (book.status == BookStatus.read) {
        pagesRead += book.pageCount ?? 0;
        finished.add(book);
        final month = finishedOn(book).month - 1;
        monthBooks[month]++;
        monthPages[month] += book.pageCount ?? 0;
      }

      for (final author in book.authors) {
        final name = author.trim();
        if (name.isEmpty) continue;
        authorCounts[name] = (authorCounts[name] ?? 0) + 1;
      }
    }

    for (final book in shelved) {
      final locationId = book.locationId;
      if (locationId != null) {
        locationCounts[locationId] = (locationCounts[locationId] ?? 0) + 1;
      }
    }

    final locationById = {for (final l in locations) l.id: l.name};
    final topLocations = _top(
      locationCounts.entries.map(
        (e) => NameCount(locationById[e.key] ?? '?', e.value),
      ),
    );
    final topAuthors = _top(
      authorCounts.entries.map((e) => NameCount(e.key, e.value)),
    );

    // Averages and extremes over the finished books.
    final rated = [
      for (final b in finished)
        if (b.rating > 0) b.rating,
    ];
    final withPages = [
      for (final b in finished)
        if ((b.pageCount ?? 0) > 0) b,
    ];
    final sessionList = sessions.toList();
    final spans = readingSpans(sessionList);
    final secondsByBook = <int, int>{};
    for (final s in sessionList) {
      secondsByBook[s.bookId] =
          (secondsByBook[s.bookId] ?? 0) + s.durationSeconds;
    }
    final timed = <(Book, int)>[];
    for (final b in finished) {
      var seconds = secondsByBook[b.id] ?? 0;
      if (seconds <= 0) {
        // No tracked time: fall back to the span between first start and last
        // end (legacy start/finish dates).
        final span = spans[b.id];
        final start = span?.firstStart;
        final end = span?.lastEnd;
        if (start != null && end != null) {
          seconds = end.difference(start).inSeconds;
        }
      }
      if (seconds > 0) timed.add((b, seconds));
    }

    NameCount? pickPages(bool max) {
      Book? best;
      for (final b in withPages) {
        if (best == null ||
            (max
                ? b.pageCount! > best.pageCount!
                : b.pageCount! < best.pageCount!)) {
          best = b;
        }
      }
      return best == null ? null : NameCount(best.title, best.pageCount!);
    }

    NameCount? pickTimed(bool max) {
      (Book, int)? best;
      for (final entry in timed) {
        if (best == null || (max ? entry.$2 > best.$2 : entry.$2 < best.$2)) {
          best = entry;
        }
      }
      return best == null ? null : NameCount(best.$1.title, best.$2);
    }

    return BookStatistics(
      totalBooks: books.length,
      statusCounts: statusCounts,
      pagesRead: pagesRead,
      topLocations: topLocations,
      topAuthors: topAuthors,
      goal: goal,
      reading: reading,
      year: year,
      years: years,
      monthly: [
        for (var m = 0; m < 12; m++)
          MonthStat(m + 1, monthBooks[m], monthPages[m]),
      ],
      averageRating: rated.isEmpty
          ? null
          : rated.reduce((a, b) => a + b) / rated.length,
      averagePages: withPages.isEmpty
          ? null
          : (withPages.fold<int>(0, (s, b) => s + b.pageCount!) /
                    withPages.length)
                .round(),
      averageReadingTime: timed.isEmpty
          ? null
          : Duration(
              seconds: (timed.fold<int>(0, (s, e) => s + e.$2) / timed.length)
                  .round(),
            ),
      longestBook: pickPages(true),
      shortestBook: pickPages(false),
      fastestBook: pickTimed(false),
      slowestBook: pickTimed(true),
    );
  }

  static List<NameCount> _top(Iterable<NameCount> entries) {
    final sorted = entries.toList()..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(_maxEntries).toList();
  }
}

class NameCount {
  final String name;
  final int count;

  const NameCount(this.name, this.count);
}
