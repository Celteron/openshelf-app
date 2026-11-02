import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/shelf_partition.dart';
import 'package:openreads/domain/models/statistics.dart';

/// What the home tab shows (FR-R2-19), derived from the whole library.
///
/// Reading numbers count single books and volumes, the "recently added" row
/// the physical objects (ADR-0003).
class HomeSummary {
  final int read;

  /// Reading or re-reading.
  final int reading;
  final int unread;

  /// The three most recently added physical books, newest first.
  final List<Book> recent;
  final List<Book> currentlyReading;
  final List<Book> favourites;

  /// The unread stack at the end of each of the last six months, oldest
  /// first; the last value is the current month.
  final List<int> unreadTrend;

  const HomeSummary({
    required this.read,
    required this.reading,
    required this.unread,
    required this.recent,
    required this.currentlyReading,
    required this.favourites,
    required this.unreadTrend,
  });

  int get total => read + reading + unread;

  factory HomeSummary.of(Iterable<Book> books, {required DateTime now}) {
    final shelf = ShelfPartition.of(books);
    final readable = shelf.readable;
    int count(bool Function(BookStatus) test) =>
        readable.where((b) => test(b.status)).length;
    final recent = [...shelf.physical]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return HomeSummary(
      read: count((s) => s == BookStatus.read),
      reading: count(
        (s) => s == BookStatus.reading || s == BookStatus.reReading,
      ),
      unread: count((s) => s == BookStatus.unread),
      recent: recent.take(3).toList(),
      currentlyReading: [
        for (final b in readable)
          if (b.status == BookStatus.reading ||
              b.status == BookStatus.reReading)
            b,
      ],
      favourites: [
        for (final b in books)
          if (b.isFavorite) b,
      ],
      unreadTrend: [
        for (var back = 5; back >= 0; back--)
          BookStatistics.unreadStackAt(
            readable,
            DateTime(now.year, now.month - back + 1),
          ),
      ],
    );
  }
}
