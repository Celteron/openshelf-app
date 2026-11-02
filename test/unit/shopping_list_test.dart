import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/series_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/series_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/shopping_list.dart';
import 'package:openreads/domain/services/series_gaps.dart';
import 'package:openreads/features/shopping/shopping_list_cubit.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late SeriesRepositoryImpl series;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    series = SeriesRepositoryImpl(SeriesDao(db));
  });

  tearDown(() => db.close());

  Future<int> add(
    String title, {
    BookStatus status = BookStatus.read,
    int? seriesId,
    double? volume,
  }) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
      status: Value(status),
      seriesId: Value(seriesId),
      seriesVolume: Value(volume),
    ),
  );

  Future<ShoppingList> build() async =>
      buildShoppingList(await books.getAllBooks(), await series.getAll());

  test('lists wishlist books and ignores everything else', () async {
    await add('Wunsch', status: BookStatus.wishlist);
    await add('Besitz');

    final list = await build();

    expect(list.wishlist.map((b) => b.title), ['Wunsch']);
    expect(list.isEmpty, isFalse);
  });

  test('nothing to buy is an empty list', () async {
    await add('Besitz');

    expect((await build()).isEmpty, isTrue);
  });

  test(
    'a series lists the volumes that are neither owned nor wished',
    () async {
      final s = await series.findOrCreate('Reihe');
      await series.setTotalVolumes(s.id, 5);
      await add('Band 1', seriesId: s.id, volume: 1);
      await add('Band 2', seriesId: s.id, volume: 2);
      await add(
        'Band 4',
        status: BookStatus.wishlist,
        seriesId: s.id,
        volume: 4,
      );

      final list = await build();

      expect(list.gaps.single.name, 'Reihe');
      expect(list.gaps.single.missing, [3, 5], reason: '4 is on the wishlist');
    },
  );

  test(
    'a complete series has no gap, a series without total is "open"',
    () async {
      final done = await series.findOrCreate('Fertig');
      await series.setTotalVolumes(done.id, 1);
      await add('Band 1', seriesId: done.id, volume: 1);
      final open = await series.findOrCreate('Offen');
      await add('Band 1', seriesId: open.id, volume: 1);

      final list = await build();

      expect(list.gaps, isEmpty);
      expect(list.openSeries.map((s) => s.name), ['Offen']);
    },
  );

  test('the cubit loads and sets a series length', () async {
    final s = await series.findOrCreate('Reihe');
    await add('Band 1', seriesId: s.id, volume: 1);
    final cubit = ShoppingListCubit(books, series);
    addTearDown(cubit.close);

    await cubit.load();
    expect((cubit.state as ShoppingLoaded).list.openSeries, hasLength(1));

    await cubit.setTotalVolumes(s.id, 3);

    final loaded = cubit.state as ShoppingLoaded;
    expect(loaded.list.openSeries, isEmpty);
    expect(loaded.list.gaps.single.missing, [2, 3]);
  });

  test('an absurd planned length cannot freeze the list', () async {
    final s = await series.findOrCreate('Endlos');
    await series.setTotalVolumes(s.id, 1000000000);
    await add('Band 1', seriesId: s.id, volume: 1);

    final list = await build();

    expect(
      list.gaps.single.missing.length,
      lessThanOrEqualTo(maxSeriesVolumes),
    );
    expect(list.gaps.single.total, maxSeriesVolumes);
  });

  test('an in-between volume does not hide a whole missing one', () async {
    final s = await series.findOrCreate('Reihe');
    await series.setTotalVolumes(s.id, 3);
    await add('Band 1', seriesId: s.id, volume: 1);
    await add(
      'Band 2.5',
      status: BookStatus.wishlist,
      seriesId: s.id,
      volume: 2.5,
    );

    final list = await build();

    expect(list.gaps.single.missing, [2, 3]);
  });

  test('closing the cubit while it loads does not throw', () async {
    final cubit = ShoppingListCubit(books, series);

    final loading = cubit.load();
    await cubit.close();

    await loading; // would throw "Cannot emit new states after calling close"
  });
}
