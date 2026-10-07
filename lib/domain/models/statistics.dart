import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/reading_stats.dart';

/// Aggregated collection metrics shown on the statistics dashboard.
///
/// Pure data + derivation logic: computing is a pure function over the book
/// and location rows, so it can be unit-tested without a database.
class BookStatistics {
  final int totalBooks;
  final Map<BookStatus, int> statusCounts;
  final int pagesRead;

  /// (name, count) pairs ordered descending by count.
  final List<NameCount> topLocations;
  final List<NameCount> topAuthors;

  /// Progress of the current year's goal; `null` when no goal is set
  /// (Phase 2).
  final GoalProgress? goal;

  /// Reading speed and totals over completed sessions (Phase 2).
  final ReadingStats reading;

  const BookStatistics({
    required this.totalBooks,
    required this.statusCounts,
    required this.pagesRead,
    required this.topLocations,
    required this.topAuthors,
    this.goal,
    this.reading = const ReadingStats.empty(),
  });

  static const _maxEntries = 5;

  factory BookStatistics.compute(
    List<Book> books,
    List<Location> locations, {
    GoalProgress? goal,
    ReadingStats reading = const ReadingStats.empty(),
  }) {
    final statusCounts = <BookStatus, int>{
      for (final status in BookStatus.values) status: 0,
    };
    var pagesRead = 0;

    final locationCounts = <int, int>{};
    final authorCounts = <String, int>{};

    for (final book in books) {
      statusCounts[book.status] = (statusCounts[book.status] ?? 0) + 1;
      if (book.status == BookStatus.read) {
        pagesRead += book.pageCount ?? 0;
      }

      final locationId = book.locationId;
      if (locationId != null) {
        locationCounts[locationId] = (locationCounts[locationId] ?? 0) + 1;
      }

      for (final author in book.authors) {
        final name = author.trim();
        if (name.isEmpty) continue;
        authorCounts[name] = (authorCounts[name] ?? 0) + 1;
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

    return BookStatistics(
      totalBooks: books.length,
      statusCounts: statusCounts,
      pagesRead: pagesRead,
      topLocations: topLocations,
      topAuthors: topAuthors,
      goal: goal,
      reading: reading,
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
