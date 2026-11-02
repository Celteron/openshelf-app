import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/models/shelf_partition.dart';

/// How big a spine is drawn. The width follows the page count between a lower
/// bound that is also the tap target (Constitution V.3) and an upper bound.
class SpineMetrics {
  static const minWidth = 48.0;
  static const maxWidth = 96.0;

  /// Used when the page count is unknown.
  static const defaultWidth = 60.0;
  static const gap = 4.0;
  static const minHeight = 170.0;
  static const maxHeight = 210.0;
  static const defaultHeight = 190.0;

  /// A book of this many pages (or fewer) is drawn at [minWidth] ...
  static const _thinPages = 100;

  /// ... and one of this many (or more) at [maxWidth].
  static const _thickPages = 800;

  static double widthFor(int? pages) {
    if (pages == null || pages <= 0) return defaultWidth;
    final t = ((pages - _thinPages) / (_thickPages - _thinPages)).clamp(
      0.0,
      1.0,
    );
    return minWidth + t * (maxWidth - minWidth);
  }

  static double heightFor(int? pages) {
    if (pages == null || pages <= 0) return defaultHeight;
    final t = (pages / 600).clamp(0.0, 1.0);
    return minHeight + t * (maxHeight - minHeight);
  }
}

/// One spine on the wall: a single book, or a slipcase with its [volumes].
class Spine {
  final Book book;
  final List<Book> volumes;
  final double width;
  final double height;

  /// Title, subtitle and authors of the book and its volumes, folded once
  /// for the search (case and umlauts), so a keystroke does not fold the
  /// whole shelf again.
  final String searchText;

  const Spine({
    required this.book,
    required this.volumes,
    required this.width,
    required this.height,
    this.searchText = '',
  });
}

/// One compartment (or shelf, room, "no location") with its spines.
class ShelfRow {
  /// `null` for the row of books without a location.
  final int? locationId;
  final String pathLabel;
  final List<Spine> spines;

  const ShelfRow({
    required this.locationId,
    required this.pathLabel,
    required this.spines,
  });
}

/// The shelf as a picture: rows of spines, computed from the locations and
/// books alone. Pure, so layout, order and search are testable without UI.
class ShelfWall {
  final List<ShelfRow> rows;
  const ShelfWall(this.rows);

  /// Builds the wall. A row exists for every location that holds books
  /// directly or has nothing below it (an empty compartment shows as such),
  /// in the order of the tree; books without a location come last.
  factory ShelfWall.build(List<Location> locations, List<Book> books) {
    final partition = ShelfPartition.of(books);
    // Wishlist books are not on the shelf.
    final onShelf = [
      for (final b in partition.physical)
        if (b.status != BookStatus.wishlist) b,
    ];

    final byParent = <int?, List<Location>>{};
    for (final l in locations) {
      (byParent[l.parentId] ??= []).add(l);
    }
    for (final list in byParent.values) {
      list.sort(
        (a, b) => a.sortOrder != b.sortOrder
            ? a.sortOrder.compareTo(b.sortOrder)
            : textSortKey(a.name).compareTo(textSortKey(b.name)),
      );
    }
    final booksAt = <int?, List<Book>>{};
    for (final b in onShelf) {
      (booksAt[b.locationId] ??= []).add(b);
    }

    final rows = <ShelfRow>[];
    final known = {for (final l in locations) l.id};
    void walk(Location location, List<String> path) {
      final names = [...path, location.name];
      final children = byParent[location.id] ?? const [];
      final own = booksAt[location.id] ?? const [];
      if (own.isNotEmpty || children.isEmpty) {
        rows.add(_row(location.id, names.join(' › '), own, partition));
      }
      for (final child in children) {
        walk(child, names);
      }
    }

    for (final root in byParent[null] ?? const <Location>[]) {
      walk(root, const []);
    }
    // A location whose parent is gone would otherwise lose its books.
    final orphans = [
      for (final l in locations)
        if (l.parentId != null && !known.contains(l.parentId)) l,
    ];
    for (final l in orphans) {
      walk(l, const []);
    }

    final unassigned = [
      ...?booksAt[null],
      for (final entry in booksAt.entries)
        if (entry.key != null && !known.contains(entry.key)) ...entry.value,
    ];
    if (unassigned.isNotEmpty) {
      rows.add(_row(null, '', unassigned, partition));
    }
    return ShelfWall(rows);
  }

  static ShelfRow _row(
    int? locationId,
    String label,
    List<Book> books,
    ShelfPartition partition,
  ) {
    // The sort keys are folded once per book, not once per comparison: the
    // "no location" row can hold the whole library.
    final keyed = [
      for (final b in books)
        (book: b, author: authorSortKey(b), title: textSortKey(b.title)),
    ]..sort(_bySpineOrder);
    return ShelfRow(
      locationId: locationId,
      pathLabel: label,
      spines: [
        for (final k in keyed) _spine(k.book, partition.volumesOf(k.book.id)),
      ],
    );
  }

  static Spine _spine(Book book, List<Book> volumes) {
    final searchText = textSortKey(
      [
        for (final b in [book, ...volumes]) ...[
          b.title,
          ?b.subtitle,
          ...b.authors,
        ],
      ].join(' '),
    );
    if (volumes.isEmpty) {
      return Spine(
        book: book,
        volumes: const [],
        width: SpineMetrics.widthFor(book.pageCount),
        height: SpineMetrics.heightFor(book.pageCount),
        searchText: searchText,
      );
    }
    var width = 0.0;
    var height = SpineMetrics.minHeight;
    for (final v in volumes) {
      width += SpineMetrics.widthFor(v.pageCount);
      final h = SpineMetrics.heightFor(v.pageCount);
      if (h > height) height = h;
    }
    return Spine(
      book: book,
      volumes: volumes,
      width: width.clamp(SpineMetrics.minWidth, SpineMetrics.maxWidth * 3),
      height: height,
      searchText: searchText,
    );
  }

  /// Author, then the volume within a series, then title: the order of a
  /// tidy shelf. All derived; nothing is stored.
  static int _bySpineOrder(
    ({Book book, String author, String title}) a,
    ({Book book, String author, String title}) b,
  ) {
    final byAuthor = a.author.compareTo(b.author);
    if (byAuthor != 0) return byAuthor;
    if (a.book.seriesId != null && a.book.seriesId == b.book.seriesId) {
      final byVolume = (a.book.seriesVolume ?? double.infinity).compareTo(
        b.book.seriesVolume ?? double.infinity,
      );
      if (byVolume != 0) return byVolume;
    }
    final byTitle = a.title.compareTo(b.title);
    return byTitle != 0 ? byTitle : a.book.id.compareTo(b.book.id);
  }

  /// Whether [bookId] stands on the wall as a slipcase with volumes.
  bool isSlipcase(int bookId) => rows.any(
    (row) => row.spines.any((s) => s.book.id == bookId && s.volumes.isNotEmpty),
  );

  /// Where the book stands: its row and spine; a volume stands at its
  /// slipcase. `null` when it is not on the wall.
  ({int row, int spine})? positionOf(int bookId) {
    for (final (r, row) in rows.indexed) {
      for (final (s, spine) in row.spines.indexed) {
        if (spine.book.id == bookId ||
            spine.volumes.any((v) => v.id == bookId)) {
          return (row: r, spine: s);
        }
      }
    }
    return null;
  }
}
