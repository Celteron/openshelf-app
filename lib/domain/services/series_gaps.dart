import 'dart:math' as math;

import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';

/// The longest series the app plans for. A planned length is typed by hand
/// or imported; without a cap a typo ("999999999") would make every shopping
/// list and every scan build a list that large.
const maxSeriesVolumes = 999;

/// The volume number of [book] when it is a whole one. A volume like 2.5 is
/// an extra and never fills a whole-number slot of a series.
int? wholeVolume(Book book) {
  final volume = book.seriesVolume;
  return volume != null && volume == volume.roundToDouble()
      ? volume.toInt()
      : null;
}

/// The state of series [series] given all [books]. Pure, so the scanner's
/// verdict and the shopping list agree.
SeriesStanding seriesStanding(Series series, Iterable<Book> books) {
  final planned = series.totalPlannedVolumes;
  final total = planned == null ? null : math.min(planned, maxSeriesVolumes);
  if (total == null || total <= 0) {
    return SeriesStanding(id: series.id, name: series.name);
  }
  // A wishlist book is wanted, not owned.
  final owned = <int>{
    for (final b in books)
      if (b.seriesId == series.id && b.status != BookStatus.wishlist)
        ?wholeVolume(b),
  };
  return SeriesStanding(
    id: series.id,
    name: series.name,
    total: total,
    missing: [
      for (var v = 1; v <= total; v++)
        if (!owned.contains(v)) v,
    ],
  );
}
