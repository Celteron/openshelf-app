import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/models/shelf_wall.dart';

/// The books on the wall that match [query], as the ids of their spines
/// (a volume stands for its slipcase), in the order of the wall.
///
/// Case and umlauts are folded, and every word of the query must appear in
/// the title, subtitle or authors.
List<int> findOnShelf(ShelfWall wall, String query) {
  final words = textSortKey(
    query,
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];

  return [
    for (final row in wall.rows)
      for (final spine in row.spines)
        if (words.every(spine.searchText.contains)) spine.book.id,
  ];
}
