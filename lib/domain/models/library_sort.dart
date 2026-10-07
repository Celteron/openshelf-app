import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// What the library list is ordered by.
///
/// The union of the Phase 2 criteria and every Openreads `SortType`
/// (title, author, rating, pages, start date, finish date, publication year,
/// date added, date modified).
enum LibrarySortField {
  title,
  author,
  rating,
  added,
  modified,
  progress,
  pages,
  publicationYear,
  status,
  lastRead,
  startDate,
  finishDate,
}

/// First start and last end of a book's reading sessions.
class ReadingSpan {
  final DateTime? firstStart;
  final DateTime? lastEnd;
  const ReadingSpan({this.firstStart, this.lastEnd});
}

/// Groups sessions per book into [ReadingSpan]s. Running sessions count with
/// their start only.
Map<int, ReadingSpan> readingSpans(Iterable<ReadingSession> sessions) {
  final starts = <int, DateTime>{};
  final ends = <int, DateTime>{};
  for (final s in sessions) {
    final start = starts[s.bookId];
    if (start == null || s.startedAt.isBefore(start)) {
      starts[s.bookId] = s.startedAt;
    }
    final end = s.endedAt ?? s.startedAt;
    final lastEnd = ends[s.bookId];
    if (lastEnd == null || end.isAfter(lastEnd)) ends[s.bookId] = end;
  }
  return {
    for (final id in starts.keys)
      id: ReadingSpan(firstStart: starts[id], lastEnd: ends[id]),
  };
}

/// A sort field plus direction. Pure and stable, so it can be unit-tested
/// without a database (Constitution Article IV.2).
///
/// Books that have no value for the chosen field (no page count, never read,
/// …) always sort last, whatever the direction. Ties fall back to the title
/// and then the id, which keeps the list from jumping around on rebuilds.
class LibrarySort {
  final LibrarySortField field;
  final bool ascending;

  /// Newest additions first: the default for a growing collection.
  const LibrarySort({
    this.field = LibrarySortField.added,
    this.ascending = false,
  });

  /// Selecting the active field flips the direction; a new field starts in its
  /// natural direction (text A→Z, numbers/dates high→low).
  LibrarySort select(LibrarySortField next) {
    if (next == field) return LibrarySort(field: field, ascending: !ascending);
    return LibrarySort(
      field: next,
      ascending:
          next == LibrarySortField.title ||
          next == LibrarySortField.author ||
          next == LibrarySortField.status,
    );
  }

  List<Book> apply(
    Iterable<Book> books, {
    Map<int, ReadingSpan> spans = const {},
  }) {
    final sorted = books.toList();
    sorted.sort((a, b) {
      final ka = _key(a, spans);
      final kb = _key(b, spans);
      if (ka != null && kb != null) {
        final result = Comparable.compare(ka, kb);
        if (result != 0) return ascending ? result : -result;
      } else if (ka == null && kb != null) {
        return 1;
      } else if (ka != null && kb == null) {
        return -1;
      }
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
    });
    return sorted;
  }

  Comparable<dynamic>? _key(Book b, Map<int, ReadingSpan> spans) {
    switch (field) {
      case LibrarySortField.title:
        return b.title.toLowerCase();
      case LibrarySortField.author:
        final key = authorSortKey(b);
        return key.isEmpty ? null : key;
      case LibrarySortField.rating:
        return b.rating;
      case LibrarySortField.added:
        return b.createdAt;
      case LibrarySortField.modified:
        return b.updatedAt;
      case LibrarySortField.progress:
        return readingProgress(b);
      case LibrarySortField.pages:
        final pages = b.pageCount;
        return pages == null || pages <= 0 ? null : pages;
      case LibrarySortField.publicationYear:
        return b.publishedYear;
      case LibrarySortField.status:
        return statusRank(b.status);
      case LibrarySortField.lastRead:
        return lastReadAt(b, spans[b.id]);
      case LibrarySortField.startDate:
        return spans[b.id]?.firstStart;
      case LibrarySortField.finishDate:
        return b.finishedAt ??
            (b.status == BookStatus.read ? spans[b.id]?.lastEnd : null);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LibrarySort &&
      other.field == field &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(field, ascending);
}

/// When the book was last read: the latest of its finish date and its last
/// session; `null` when it never was.
DateTime? lastReadAt(Book book, ReadingSpan? span) {
  final finished = book.finishedAt;
  final lastEnd = span?.lastEnd;
  if (finished == null) return lastEnd;
  if (lastEnd == null) return finished;
  return finished.isAfter(lastEnd) ? finished : lastEnd;
}

/// Order of statuses when sorting by status: what is being read comes first,
/// finished and abandoned books last.
int statusRank(BookStatus status) => switch (status) {
  BookStatus.reading => 0,
  BookStatus.reReading => 1,
  BookStatus.unread => 2,
  BookStatus.wishlist => 3,
  BookStatus.read => 4,
  BookStatus.dnf => 5,
};

/// Reading progress in `0.0–1.0`: finished books are complete; otherwise the
/// current page over the page count (0 when the page count is unknown).
double readingProgress(Book book) {
  if (book.status == BookStatus.read) return 1.0;
  final total = book.pageCount;
  if (total == null || total <= 0) return 0.0;
  return (book.currentPage / total).clamp(0.0, 1.0);
}

/// Sort key of the first author, surname first: both `Günter Grass` and
/// `Grass, Günter` become `grass günter`, so differently written names sort
/// together.
String authorSortKey(Book book) {
  if (book.authors.isEmpty) return '';
  final name = book.authors.first.trim().toLowerCase();
  if (name.contains(',')) {
    return name.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  final parts = name.split(RegExp(r'\s+'));
  if (parts.length < 2) return name;
  return '${parts.last} ${parts.sublist(0, parts.length - 1).join(' ')}';
}
