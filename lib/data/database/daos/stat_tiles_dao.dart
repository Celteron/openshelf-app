import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class StatTilesDao {
  final AppDatabase db;
  StatTilesDao(this.db);

  Stream<List<StatTileRow>> watchAll() =>
      (db.select(db.statTiles)..orderBy([
            (t) => OrderingTerm(expression: t.position),
            // A stable order even if two tiles ever share a position.
            (t) => OrderingTerm(expression: t.id),
          ]))
          .watch();

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

  /// Inserts a deleted tile again, before the first tile that followed it in
  /// [order] (the ids as shown when it was deleted) and still exists, else
  /// at the end; then numbers all positions afresh. Pinned only if fewer
  /// than [limit] tiles are. Returns the new id and whether it is pinned.
  Future<(int, bool)> restore({
    required String title,
    required String definition,
    required bool pinned,
    required int deletedId,
    required List<int> order,
    required int limit,
  }) => db.transaction(() async {
    final rows =
        await (db.select(db.statTiles)..orderBy([
              (t) => OrderingTerm(expression: t.position),
              (t) => OrderingTerm(expression: t.id),
            ]))
            .get();
    final pin = pinned && rows.where((r) => r.pinned).length < limit;
    final id = await db
        .into(db.statTiles)
        .insert(
          StatTilesCompanion.insert(
            position: 0,
            title: title,
            definition: definition,
            pinned: Value(pin),
            createdAt: DateTime.now(),
          ),
        );
    final ids = [for (final r in rows) r.id];
    final followers = order.skip(order.indexOf(deletedId) + 1);
    final next = followers.where(ids.contains).firstOrNull;
    ids.insert(next == null ? ids.length : ids.indexOf(next), id);
    for (final (i, rowId) in ids.indexed) {
      await (db.update(db.statTiles)..where((t) => t.id.equals(rowId))).write(
        StatTilesCompanion(position: Value(i)),
      );
    }
    return (id, pin);
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
