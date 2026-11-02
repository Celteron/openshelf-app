import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/services/series_gaps.dart';

/// What is still to be bought: the wishlist and the volumes of series that
/// are known to be incomplete.
class ShoppingList {
  final List<Book> wishlist;

  /// Series with a known length and volumes that are neither owned nor on the
  /// wishlist ([SeriesStanding.missing] is already reduced by the wishlist).
  final List<SeriesStanding> gaps;

  /// Series without a planned length: their gaps are unknown until the user
  /// says how many volumes there are.
  final List<SeriesStanding> openSeries;

  const ShoppingList({
    required this.wishlist,
    required this.gaps,
    required this.openSeries,
  });

  bool get isEmpty => wishlist.isEmpty && gaps.isEmpty;
}

ShoppingList buildShoppingList(List<Book> books, List<Series> series) {
  final wishlist = [
    for (final b in books)
      if (b.status == BookStatus.wishlist) b,
  ];
  final gaps = <SeriesStanding>[];
  final open = <SeriesStanding>[];
  for (final s in series) {
    final standing = seriesStanding(s, books);
    if (standing.total == null) {
      // A series nobody owns a book of (e.g. all trashed) is not worth asking.
      if (books.any((b) => b.seriesId == s.id)) open.add(standing);
      continue;
    }
    final wished = {
      for (final b in wishlist)
        if (b.seriesId == s.id) ?wholeVolume(b),
    };
    final missing = [
      for (final v in standing.missing)
        if (!wished.contains(v)) v,
    ];
    if (missing.isNotEmpty) {
      gaps.add(
        SeriesStanding(
          id: standing.id,
          name: standing.name,
          total: standing.total,
          missing: missing,
        ),
      );
    }
  }
  return ShoppingList(wishlist: wishlist, gaps: gaps, openSeries: open);
}
