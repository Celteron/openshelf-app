import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// Splits the library into the two sets statistics are built on (ADR-0003).
///
/// A slipcase is a book other books point to with `parentId`; it is the
/// physical object (ISBN, price, location), its volumes are what gets read.
class ShelfPartition {
  /// Single books and volumes: reading statistics, goal, home page.
  final List<Book> readable;

  /// Single books and slipcases: spending, "received as", locations.
  final List<Book> physical;

  final Map<int, List<Book>> _volumes;
  final Map<int, Book> _slipcases;

  const ShelfPartition._(
    this.readable,
    this.physical,
    this._volumes,
    this._slipcases,
  );

  factory ShelfPartition.of(Iterable<Book> books) {
    final ids = {for (final b in books) b.id};
    final volumes = <int, List<Book>>{};
    for (final b in books) {
      final parent = b.parentId;
      if (parent != null && ids.contains(parent)) {
        (volumes[parent] ??= []).add(b);
      }
    }
    // A volume whose slipcase is not listed (e.g. in the trash) stands alone
    // rather than vanishing from both sets.
    bool isVolume(Book b) => volumes.containsKey(b.parentId);
    return ShelfPartition._(
      [
        for (final b in books)
          if (!volumes.containsKey(b.id)) b,
      ],
      [
        for (final b in books)
          if (!isVolume(b)) b,
      ],
      volumes,
      {
        for (final b in books)
          if (volumes.containsKey(b.id)) b.id: b,
      },
    );
  }

  bool isSlipcase(int id) => _volumes.containsKey(id);

  /// The physical object [book] sits on the shelf as: its slipcase for a
  /// volume, else the book itself.
  Book shelvedAs(Book book) => _slipcases[book.parentId] ?? book;

  /// The volumes of slipcase [id] in list order; empty for other books.
  List<Book> volumesOf(int id) => _volumes[id] ?? const [];

  /// The library entries for [matched] (filtered and sorted books): a
  /// slipcase stands once, at the place of its first matching member, and a
  /// matching volume brings its slipcase. With a [status] filter a slipcase
  /// matches when its derived status or any of its volumes does.
  List<Book> entries(Iterable<Book> matched, {BookStatus? status}) {
    final seen = <int>{};
    final result = <Book>[];
    for (final book in matched) {
      final entry = shelvedAs(book);
      if (!seen.add(entry.id)) continue;
      if (status == null || _matches(entry, status)) result.add(entry);
    }
    return result;
  }

  bool _matches(Book entry, BookStatus status) {
    final volumes = _volumes[entry.id];
    if (volumes == null) return entry.status == status;
    final statuses = volumes.map((v) => v.status);
    return slipcaseStatus(statuses) == status || statuses.contains(status);
  }
}

/// A trash entry: a book with the volumes that went to the trash with it.
typedef TrashEntry = ({Book book, List<Book> volumes});

/// Groups the trash like the shelf: volumes trashed together with their
/// slipcase (same deletion time, see `BooksDao.trash`) sit behind it, since
/// restoring or purging the slipcase takes them along. A volume trashed on
/// its own stays an entry.
List<TrashEntry> groupTrash(List<Book> trashed) {
  final byId = {for (final b in trashed) b.id: b};
  bool trashedWithParent(Book b) {
    final parent = byId[b.parentId];
    return parent != null && parent.deletedAt == b.deletedAt;
  }

  final volumes = <int, List<Book>>{};
  for (final b in trashed) {
    if (trashedWithParent(b)) (volumes[b.parentId!] ??= []).add(b);
  }
  return [
    for (final b in trashed)
      if (!trashedWithParent(b)) (book: b, volumes: volumes[b.id] ?? const []),
  ];
}

/// The status a slipcase shows, derived from its volumes' statuses. A mix of
/// read and not yet read volumes counts as reading (the shelf shows "x of n
/// read" next to it).
BookStatus slipcaseStatus(Iterable<BookStatus> volumes) {
  final statuses = volumes.toSet();
  if (statuses.isEmpty) return BookStatus.unread;
  if (statuses.contains(BookStatus.reading) ||
      statuses.contains(BookStatus.reReading)) {
    return BookStatus.reading;
  }
  final anyRead = statuses.contains(BookStatus.read);
  if (anyRead) {
    return statuses.every((s) => s == BookStatus.read || s == BookStatus.dnf)
        ? BookStatus.read
        : BookStatus.reading;
  }
  if (statuses.length == 1) {
    final only = statuses.single;
    if (only == BookStatus.dnf || only == BookStatus.wishlist) return only;
  }
  return BookStatus.unread;
}
