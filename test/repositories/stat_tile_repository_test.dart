import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/stat_tiles_dao.dart';
import 'package:openreads/data/repositories/stat_tile_repository_impl.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';

const _pages = StatDefinition(
  measure: StatMeasure.pagesRead,
  grouping: StatGrouping.month,
  period: StatYear(2026),
  chart: StatChart.bar,
);
const _books = StatDefinition(
  measure: StatMeasure.books,
  period: StatAllTime(),
  chart: StatChart.number,
);

/// Stored tiles of the user-defined statistics (spec 005, T5-03).
void main() {
  late AppDatabase db;
  late StatTileRepositoryImpl tiles;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tiles = StatTileRepositoryImpl(StatTilesDao(db));
  });

  tearDown(() => db.close());

  test('new tiles are appended and come back in order', () async {
    await tiles.addTile('Seiten', _pages);
    await tiles.addTile('Bücher', _books);

    final all = await tiles.watchTiles().first;
    expect([for (final t in all) t.title], ['Seiten', 'Bücher']);
    expect(all.first.definition, _pages);
    expect(all.first.pinned, isFalse);
  });

  test('update changes title and definition', () async {
    final id = await tiles.addTile('Seiten', _pages);
    await tiles.updateTile(id, title: 'Alle Bücher', definition: _books);

    final tile = (await tiles.watchTiles().first).single;
    expect(tile.title, 'Alle Bücher');
    expect(tile.definition, _books);
  });

  test('reorder stores the new order', () async {
    final a = await tiles.addTile('A', _books);
    final b = await tiles.addTile('B', _books);
    final c = await tiles.addTile('C', _books);

    await tiles.reorder([c, a, b]);

    expect([for (final t in await tiles.watchTiles().first) t.id], [c, a, b]);
  });

  test('delete removes a tile', () async {
    final a = await tiles.addTile('A', _books);
    await tiles.addTile('B', _books);
    await tiles.deleteTile(a);

    expect([for (final t in await tiles.watchTiles().first) t.title], ['B']);
  });

  test('at most three tiles are pinned to the home tab', () async {
    final ids = [for (var i = 0; i < 4; i++) await tiles.addTile('$i', _books)];
    for (final id in ids.take(3)) {
      expect(await tiles.setPinned(id, pinned: true), isTrue);
    }

    expect(await tiles.setPinned(ids[3], pinned: true), isFalse);
    expect(await tiles.setPinned(ids[0], pinned: false), isTrue);
    expect(await tiles.setPinned(ids[3], pinned: true), isTrue);

    final pinned = [
      for (final t in await tiles.watchTiles().first)
        if (t.pinned) t.id,
    ];
    expect(pinned, [ids[1], ids[2], ids[3]]);
  });

  test(
    'a stored definition the app cannot read is skipped, not fatal',
    () async {
      await db
          .into(db.statTiles)
          .insert(
            StatTilesCompanion.insert(
              position: 0,
              title: 'Kaputt',
              definition: '{"measure":"nope"',
              createdAt: DateTime(2026),
            ),
          );
      await db
          .into(db.statTiles)
          .insert(
            StatTilesCompanion.insert(
              position: 1,
              title: 'Unbekannt',
              definition: '{"measure":"future_measure","period":"all"}',
              createdAt: DateTime(2026),
              pinned: const Value(true),
            ),
          );
      await tiles.addTile('Gut', _books);

      expect(
        [for (final t in await tiles.watchTiles().first) t.title],
        ['Gut'],
      );
    },
  );

  group('restoring a deleted tile (undo)', () {
    Future<List<String>> titles() async => [
      for (final t in await tiles.watchTiles().first) t.title,
    ];

    test('comes back at its place with its pin', () async {
      final a = await tiles.addTile('A', _books);
      final b = await tiles.addTile('B', _books);
      final c = await tiles.addTile('C', _books);
      await tiles.deleteTile(b);

      final pinned = await tiles.restoreTile(
        StatTile(id: b, title: 'B', definition: _books, pinned: true),
        [a, b, c],
      );

      expect(pinned, isTrue);
      expect(await titles(), ['A', 'B', 'C']);
      expect((await tiles.watchTiles().first)[1].pinned, isTrue);
    });

    test('two undos after two deletes give a full, stable order', () async {
      final a = await tiles.addTile('A', _books);
      final b = await tiles.addTile('B', _books);
      final c = await tiles.addTile('C', _books);
      await tiles.deleteTile(a);
      await tiles.deleteTile(b);

      // The first delete's snapshot still names b, which is gone by now.
      await tiles.restoreTile(StatTile(id: a, title: 'A', definition: _books), [
        a,
        b,
        c,
      ]);
      await tiles.restoreTile(StatTile(id: b, title: 'B', definition: _books), [
        b,
        c,
      ]);

      expect(await titles(), ['A', 'B', 'C']);
    });

    test('says so when the home tab has no room for its pin', () async {
      for (var i = 0; i < 3; i++) {
        await tiles.setPinned(await tiles.addTile('$i', _books), pinned: true);
      }

      final pinned = await tiles.restoreTile(
        const StatTile(id: 99, title: 'X', definition: _books, pinned: true),
        const [99],
      );

      expect(pinned, isFalse);
      expect((await tiles.watchTiles().first).last.title, 'X');
    });
  });
}
