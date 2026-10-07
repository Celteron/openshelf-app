import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// What the library list is ordered by.
enum LibrarySortField { title, author, rating, added, progress }

/// A sort field plus direction. Pure and stable, so it can be unit-tested
/// without a database (Constitution Article IV.2). Ties fall back to the title
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
          next == LibrarySortField.title || next == LibrarySortField.author,
    );
  }

  List<Book> apply(Iterable<Book> books) {
    final sorted = books.toList();
    sorted.sort((a, b) {
      var result = _compare(a, b);
      if (!ascending) result = -result;
      if (result != 0) return result;
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
    });
    return sorted;
  }

  int _compare(Book a, Book b) => switch (field) {
    LibrarySortField.title => a.title.toLowerCase().compareTo(
      b.title.toLowerCase(),
    ),
    LibrarySortField.author => authorSortKey(a).compareTo(authorSortKey(b)),
    LibrarySortField.rating => a.rating.compareTo(b.rating),
    LibrarySortField.added => a.createdAt.compareTo(b.createdAt),
    LibrarySortField.progress => readingProgress(
      a,
    ).compareTo(readingProgress(b)),
  };

  @override
  bool operator ==(Object other) =>
      other is LibrarySort &&
      other.field == field &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(field, ascending);
}

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
