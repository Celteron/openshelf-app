import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/database/daos/stat_tiles_dao.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/data/repositories/stat_tile_repository_impl.dart';
import 'package:openreads/data/repositories/tag_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/repositories/stat_tile_repository.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:openreads/features/statistics/custom_stats_cubit.dart';

class _BrokenTiles implements StatTileRepository {
  @override
  Stream<List<StatTile>> watchTiles() => Stream.error(StateError('db closed'));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _byTag = StatDefinition(
  measure: StatMeasure.books,
  grouping: StatGrouping.tag,
  period: StatAllTime(),
  chart: StatChart.bar,
);
const _count = StatDefinition(
  measure: StatMeasure.books,
  period: StatAllTime(),
  chart: StatChart.number,
);

/// The tiles of user-defined statistics, evaluated over the live library
/// (spec 005, T5-05/T5-06).
void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late TagRepositoryImpl tags;
  late CustomStatsCubit cubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    tags = TagRepositoryImpl(TagsDao(db));
    cubit = CustomStatsCubit(
      tiles: StatTileRepositoryImpl(StatTilesDao(db)),
      books: books,
      reading: ReadingRepositoryImpl(ReadingDao(db)),
      tags: tags,
      locations: LocationRepositoryImpl(LocationsDao(db)),
    )..load();
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<CustomStatsLoaded> loaded() async {
    final state = await cubit.stream.firstWhere(
      (s) => s is CustomStatsLoaded && s.tiles.isNotEmpty,
    );
    return state as CustomStatsLoaded;
  }

  Future<int> addBook(String title) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
    ),
  );

  test('evaluates every tile over the library, with tag names', () async {
    final krimi = await tags.createTag('Krimi');
    await tags.setBookTags(await addBook('Eins'), {krimi});
    await addBook('Zwei');

    await cubit.addTile('Nach Tag', _byTag);
    await cubit.addTile('Alle', _count);
    final state =
        await cubit.stream.firstWhere(
              (s) => s is CustomStatsLoaded && s.tiles.length == 2,
            )
            as CustomStatsLoaded;

    expect([for (final t in state.tiles) t.tile.title], ['Nach Tag', 'Alle']);
    final series = state.tiles.first.result as StatSeries;
    expect(series.entries.single.key, StatTag(krimi));
    expect(state.library.tagNames[krimi], 'Krimi');
    expect((state.tiles.last.result as StatSingle).value, 2);
  });

  test('a new book updates the tiles', () async {
    await cubit.addTile('Alle', _count);
    expect(((await loaded()).tiles.single.result as StatSingle).value, 0);

    await addBook('Neu');

    final state = await cubit.stream.firstWhere(
      (s) =>
          s is CustomStatsLoaded &&
          (s.tiles.single.result as StatSingle).value == 1,
    );
    expect(state, isA<CustomStatsLoaded>());
  });

  test('the library serves the live preview of the builder', () async {
    await addBook('Eins');
    await cubit.addTile('Alle', _count);
    final library = (await loaded()).library;

    final preview = library.evaluate(
      const StatDefinition(
        measure: StatMeasure.books,
        grouping: StatGrouping.status,
        period: StatAllTime(),
        chart: StatChart.bar,
      ),
    );

    expect(
      (preview as StatSeries).entries.single.key,
      const StatStatus(BookStatus.unread),
    );
  });

  test('a failing source shows the error, not a crash', () async {
    final broken = CustomStatsCubit(tiles: _BrokenTiles(), books: books)
      ..load();
    addTearDown(broken.close);

    expect(
      await broken.stream.firstWhere((s) => s is! CustomStatsLoading),
      isA<CustomStatsError>(),
    );
  });

  group('managing tiles (FR-05-08)', () {
    Future<List<String>> titles() async => [
      for (final t
          in ((await cubit.stream.firstWhere((s) => s is CustomStatsLoaded))
                  as CustomStatsLoaded)
              .tiles)
        t.tile.title,
    ];

    Future<List<EvaluatedTile>> settled(int count) async =>
        ((await cubit.stream.firstWhere(
                  (s) => s is CustomStatsLoaded && s.tiles.length == count,
                ))
                as CustomStatsLoaded)
            .tiles;

    test('moving a tile swaps it with its neighbour', () async {
      await cubit.addTile('A', _count);
      await cubit.addTile('B', _count);
      final b = (await settled(2)).last.tile.id;

      await cubit.moveTile(b, -1);

      expect(await titles(), ['B', 'A']);
    });

    test('a drag stores the order the list reports', () async {
      for (final t in ['A', 'B', 'C']) {
        await cubit.addTile(t, _count);
      }
      await settled(3);

      // ReorderableListView counts the target with the item still in place.
      await cubit.reorderTile(0, 3);

      expect(await titles(), ['B', 'C', 'A']);
    });

    test('a deleted tile comes back where it was, pinned as before', () async {
      await cubit.addTile('A', _count);
      final b = await cubit.addTile('B', _count);
      await cubit.addTile('C', _count);
      expect(await cubit.setPinned(b, pinned: true), isTrue);
      final tile = (await settled(3))[1].tile;

      final undo = await cubit.deleteTile(tile);
      await settled(2);
      await undo();

      final tiles = await settled(3);
      expect([for (final t in tiles) t.tile.title], ['A', 'B', 'C']);
      expect(tiles[1].tile.pinned, isTrue);
    });
  });
}
