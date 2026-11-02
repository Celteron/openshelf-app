import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';

/// The tiles of the user-defined statistics (spec 005, FR-05-06).
abstract class StatTileRepository {
  /// In display order; tiles whose stored definition this app version cannot
  /// read are left out.
  Stream<List<StatTile>> watchTiles();

  /// Appends a tile and returns its id.
  Future<int> addTile(String title, StatDefinition definition);

  Future<void> updateTile(int id, {String? title, StatDefinition? definition});

  Future<void> deleteTile(int id);

  /// Brings a deleted [tile] back at its place in [order] (the ids shown
  /// when it was deleted), in one transaction. `false` when its pin did not
  /// fit any more.
  Future<bool> restoreTile(StatTile tile, List<int> order);

  /// Stores [ids] as the new display order.
  Future<void> reorder(List<int> ids);

  /// `false` when pinning would exceed [StatTile.maxPinned]; nothing changes then.
  Future<bool> setPinned(int id, {required bool pinned});
}
