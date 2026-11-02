import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_metadata.dart';

/// Where a series stands in the library: which volumes are still missing.
class SeriesStanding {
  final int id;
  final String name;

  /// Planned number of volumes; `null` when the user never set one.
  final int? total;

  /// Whole volume numbers up to [total] that no owned book has. Empty without
  /// a [total]: with no known end there is no gap to report.
  final List<int> missing;

  const SeriesStanding({
    required this.id,
    required this.name,
    this.total,
    this.missing = const [],
  });
}

/// The answer to "do I already have this?" for one scanned ISBN.
sealed class ScanVerdict {
  final String isbn13;
  const ScanVerdict(this.isbn13);
}

/// Not in the library: scanning it would add a new book.
class NewVerdict extends ScanVerdict {
  /// What the online lookup found; `null` until it answers or when nothing
  /// was found.
  final BookMetadata? metadata;
  const NewVerdict(super.isbn13, {this.metadata});
}

/// In the library and owned.
class OwnedVerdict extends ScanVerdict {
  final Book book;

  /// "Room › Shelf › Compartment", `null` when the book has no location.
  final String? locationPath;
  final SeriesStanding? series;

  const OwnedVerdict(
    super.isbn13, {
    required this.book,
    this.locationPath,
    this.series,
  });
}

/// On the wishlist, so wanted but not owned yet.
class WishlistVerdict extends ScanVerdict {
  final Book book;
  final SeriesStanding? series;
  const WishlistVerdict(super.isbn13, {required this.book, this.series});
}

/// In the trash: the ISBN is taken until the book is restored or purged.
class TrashedVerdict extends ScanVerdict {
  const TrashedVerdict(super.isbn13);
}
