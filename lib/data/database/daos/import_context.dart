import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/import.dart';

/// Per-transaction lookup of the lookup tables an import writes into
/// (locations, series, tags): find the existing row or create it once.
///
/// Names are compared in Dart, case-insensitively: SQLite's `lower()` only
/// folds ASCII, so `Übernatürliches` would never match itself in SQL.
class ImportContext {
  final AppDatabase db;
  final _tags = <String, int>{};
  final _series = <String, int>{};
  final _locations = <String, int>{}; // "parentId|name" -> id
  var _nextLocationOrder = <int?, int>{};

  ImportContext(this.db);

  Future<void> load() async {
    for (final tag in await db.select(db.tags).get()) {
      _tags[tag.name.toLowerCase()] = tag.id;
    }
    for (final s in await db.select(db.seriesTable).get()) {
      _series[s.name.toLowerCase()] = s.id;
    }
    _nextLocationOrder = {};
    for (final l in await db.select(db.locations).get()) {
      _locations[_locationKey(l.parentId, l.name)] = l.id;
      final next = l.sortOrder + 1;
      if (next > (_nextLocationOrder[l.parentId] ?? 0)) {
        _nextLocationOrder[l.parentId] = next;
      }
    }
  }

  static String _locationKey(int? parentId, String name) =>
      '${parentId ?? ''}|${name.trim().toLowerCase()}';

  Future<int> tag(String name) async => _tags[name.toLowerCase()] ??= await db
      .into(db.tags)
      .insert(TagsCompanion.insert(name: name));

  /// The series called [name], created with [totalVolumes] when new.
  Future<int?> series(String? name, int? totalVolumes) async {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final key = trimmed.toLowerCase();
    final known = _series[key];
    if (known != null) return known;
    return _series[key] = await db
        .into(db.seriesTable)
        .insert(
          SeriesTableCompanion.insert(
            name: trimmed,
            totalPlannedVolumes: Value(totalVolumes),
          ),
        );
  }

  /// The innermost location of [path], creating missing levels. `null` for an
  /// empty path.
  Future<int?> location(List<LocationRef> path) async {
    int? parentId;
    for (final ref in path) {
      final key = _locationKey(parentId, ref.name);
      var id = _locations[key];
      if (id == null) {
        final order = _nextLocationOrder[parentId] ?? 0;
        id = await db
            .into(db.locations)
            .insert(
              LocationsCompanion.insert(
                name: ref.name.trim(),
                type: ref.type,
                parentId: Value(parentId),
                sortOrder: Value(order),
              ),
            );
        _locations[key] = id;
        _nextLocationOrder[parentId] = order + 1;
      }
      parentId = id;
    }
    return parentId;
  }
}
