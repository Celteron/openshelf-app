import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/series_repository.dart';
import 'package:openreads/domain/services/series_gaps.dart';

/// Answers "do I already have this book, and where does it stand?" from the
/// local library alone (Constitution I.1: no network).
class OwnershipChecker {
  final BookRepository _books;
  final LocationRepository _locations;
  final SeriesRepository _series;

  OwnershipChecker(this._books, this._locations, this._series);

  Future<ScanVerdict> check(String isbn13) async {
    final all = await _books.getAllBooks();
    final found = all.where((b) => b.isbn13 == isbn13).firstOrNull;
    if (found == null) {
      // Trashed books keep their (unique) ISBN.
      return await _books.isbnExists(isbn13)
          ? TrashedVerdict(isbn13)
          : NewVerdict(isbn13);
    }

    final standing = await _standing(found, all);
    if (found.status == BookStatus.wishlist) {
      return WishlistVerdict(isbn13, book: found, series: standing);
    }
    return OwnedVerdict(
      isbn13,
      book: found,
      locationPath: await _path(found.locationId),
      series: standing,
    );
  }

  Future<SeriesStanding?> _standing(Book book, List<Book> all) async {
    final id = book.seriesId;
    if (id == null) return null;
    final series = (await _series.getAll())
        .where((s) => s.id == id)
        .firstOrNull;
    return series == null ? null : seriesStanding(series, all);
  }

  /// "Room › Shelf › Compartment" from the root down; `null` without one.
  Future<String?> _path(int? locationId) async {
    if (locationId == null) return null;
    final byId = {for (final l in await _locations.getLocations()) l.id: l};
    final names = <String>[];
    var current = byId[locationId];
    // The depth guard stops a corrupt parent cycle from looping forever.
    for (var i = 0; current != null && i < 10; i++) {
      names.add(current.name);
      current = byId[current.parentId];
    }
    return names.isEmpty ? null : names.reversed.join(' › ');
  }
}
