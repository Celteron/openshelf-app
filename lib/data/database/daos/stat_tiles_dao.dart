import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class StatTilesDao {
  final AppDatabase db;
  StatTilesDao(this.db);

  Stream<List<StatTileRow>> watchAll() => (db.select(
    db.statTiles,
  )..orderBy([(t) => OrderingTerm(expression: t.position)])).watch();

  /// Appends a tile after the last one.
  Future<int> add(String title, String definition) => db.transaction(() async {
    final max = db.statTiles.position.max();
    final last = await (db.selectOnly(
      db.statTiles,
    )..addColumns([max])).map((r) => r.read(max)).getSingle();
    return db
        .into(db.statTiles)
        .insert(
          StatTilesCompanion.insert(
            position: (last ?? -1) + 1,
            title: title,
            definition: definition,
            createdAt: DateTime.now(),
          ),
        );
  });

  Future<void> update(int id, {String? title, String? definition}) =>
      (db.update(db.statTiles)..where((t) => t.id.equals(id))).write(
        StatTilesCompanion(
          title: title == null ? const Value.absent() : Value(title),
          definition: definition == null
              ? const Value.absent()
              : Value(definition),
        ),
      );

  Future<void> delete(int id) =>
      (db.delete(db.statTiles)..where((t) => t.id.equals(id))).go();

  /// Gives the tiles [ids] the positions 0, 1, 2, … in that order.
  Future<void> reorder(List<int> ids) => db.batch((batch) {
    for (final (i, id) in ids.indexed) {
      batch.update(
        db.statTiles,
        StatTilesCompanion(position: Value(i)),
        where: (t) => t.id.equals(id),
      );
    }
  });

  /// Pins [id] unless [limit] tiles accepted by [counts] are pinned already;
  /// atomic, so two quick taps cannot exceed the limit.
  Future<bool> pin(
    int id, {
    required int limit,
    required bool Function(StatTileRow row) counts,
  }) => db.transaction(() async {
    final pinned = await (db.select(
      db.statTiles,
    )..where((t) => t.pinned.equals(true) & t.id.equals(id).not())).get();
    if (pinned.where(counts).length >= limit) return false;
    await _setPinned(id, true);
    return true;
  });

  Future<void> unpin(int id) => _setPinned(id, false);

  Future<void> _setPinned(int id, bool pinned) =>
      (db.update(db.statTiles)..where((t) => t.id.equals(id))).write(
        StatTilesCompanion(pinned: Value(pinned)),
      );
}
