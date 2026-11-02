import 'dart:convert';

import 'package:openreads/data/database/daos/stat_tiles_dao.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/repositories/stat_tile_repository.dart';

class StatTileRepositoryImpl implements StatTileRepository {
  final StatTilesDao _dao;

  StatTileRepositoryImpl(this._dao);

  @override
  Stream<List<StatTile>> watchTiles() => _dao.watchAll().map(
    (rows) => [
      for (final row in rows)
        if (StatDefinition.tryDecode(row.definition) case final definition?)
          StatTile(
            id: row.id,
            title: row.title,
            definition: definition,
            pinned: row.pinned,
          ),
    ],
  );

  @override
  Future<int> addTile(String title, StatDefinition definition) =>
      _dao.add(title, jsonEncode(definition.toJson()));

  @override
  Future<void> updateTile(
    int id, {
    String? title,
    StatDefinition? definition,
  }) => _dao.update(
    id,
    title: title,
    definition: definition == null ? null : jsonEncode(definition.toJson()),
  );

  @override
  Future<void> deleteTile(int id) => _dao.delete(id);

  @override
  Future<void> reorder(List<int> ids) => _dao.reorder(ids);

  @override
  Future<bool> setPinned(int id, {required bool pinned}) async {
    if (!pinned) {
      await _dao.unpin(id);
      return true;
    }
    // A hidden tile must not hold one of the visible home slots.
    return _dao.pin(
      id,
      limit: StatTile.maxPinned,
      counts: (row) => StatDefinition.tryDecode(row.definition) != null,
    );
  }
}
