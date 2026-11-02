import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/stat_tile_repository.dart';
import 'package:openreads/features/statistics/custom_stats_cubit.dart';
import 'package:openreads/features/statistics/custom_stats_section.dart';
import 'package:openreads/features/statistics/statistics_books_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';
import 'package:rxdart/rxdart.dart';

/// Tiles kept in memory, with the repository's rules.
class _Tiles implements StatTileRepository {
  final _subject = BehaviorSubject<List<StatTile>>.seeded(const []);
  var _next = 1;

  List<StatTile> get tiles => _subject.value;

  @override
  Stream<List<StatTile>> watchTiles() => _subject.stream;

  @override
  Future<int> addTile(String title, StatDefinition definition) async {
    final id = _next++;
    _subject.add([
      ...tiles,
      StatTile(id: id, title: title, definition: definition),
    ]);
    return id;
  }

  @override
  Future<void> updateTile(
    int id, {
    String? title,
    StatDefinition? definition,
  }) async => _subject.add([
    for (final t in tiles)
      t.id == id
          ? StatTile(
              id: id,
              title: title ?? t.title,
              definition: definition ?? t.definition,
              pinned: t.pinned,
            )
          : t,
  ]);

  @override
  Future<void> deleteTile(int id) async =>
      _subject.add([...tiles.where((t) => t.id != id)]);

  @override
  Future<void> reorder(List<int> ids) async {
    final byId = {for (final t in tiles) t.id: t};
    _subject.add([
      for (final id in ids)
        if (byId[id] case final t?) t,
    ]);
  }

  @override
  Future<bool> restoreTile(StatTile tile, List<int> order) async {
    final id = _next++;
    final ids = [for (final t in tiles) t.id];
    final next = order
        .skip(order.indexOf(tile.id) + 1)
        .where(ids.contains)
        .firstOrNull;
    final at = next == null ? tiles.length : ids.indexOf(next);
    _subject.add([
      ...tiles.take(at),
      StatTile(
        id: id,
        title: tile.title,
        definition: tile.definition,
        pinned: tile.pinned,
      ),
      ...tiles.skip(at),
    ]);
    return true;
  }

  @override
  Future<bool> setPinned(int id, {required bool pinned}) async {
    if (pinned &&
        tiles.where((t) => t.pinned && t.id != id).length >=
            StatTile.maxPinned) {
      return false;
    }
    _subject.add([
      for (final t in tiles)
        t.id == id
            ? StatTile(
                id: id,
                title: t.title,
                definition: t.definition,
                pinned: pinned,
              )
            : t,
    ]);
    return true;
  }
}

class _Books implements BookRepository {
  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => Stream.value([
    for (final (id, genre) in [(1, 'Krimi'), (2, 'Krimi'), (3, 'Fantasy')])
      Book(
        id: id,
        title: 'Buch $id',
        authors: const ['A'],
        status: BookStatus.read,
        rating: 0,
        genre: genre,
        editedFields: const [],
        currentPage: 0,
        isFavorite: false,
        coverNotFound: false,
        createdAt: DateTime(2026, 1, id),
        updatedAt: DateTime(2026),
      ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _count = StatDefinition(
  measure: StatMeasure.books,
  period: StatAllTime(),
  chart: StatChart.number,
);
const _byGenre = StatDefinition(
  measure: StatMeasure.books,
  grouping: StatGrouping.genre,
  period: StatAllTime(),
  chart: StatChart.bar,
);

/// "Eigene Statistiken" on the statistics screen (spec 005, T5-06).
void main() {
  late _Tiles tiles;

  Future<void> pump(WidgetTester tester) async {
    tiles = _Tiles();
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        // Owned by the tree: closing it in a tear-down hangs.
        create: (_) => CustomStatsCubit(tiles: tiles, books: _Books())..load(),
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(children: const [CustomStatsSection()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, int id, String action) async {
    await tester.tap(find.byKey(ValueKey('custom-tile-$id-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('custom-tile-$id-$action')));
    await tester.pumpAndSettle();
  }

  List<String> shownTitles(WidgetTester tester) => [
    for (final t in tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('custom-tiles')),
        matching: find.byKey(const ValueKey('stat-tile-title')),
      ),
    ))
      t.data!,
  ];

  testWidgets('a new statistic from a preset appears in the section', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Eigene Statistiken'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('custom-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-booksByGenre')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('builder-save')));
    await tester.pumpAndSettle();

    expect(tiles.tiles.single.title, 'Bücher nach Genre');
    expect(find.text('Krimi'), findsOneWidget);
  });

  testWidgets('a value opens its books', (tester) async {
    await pump(tester);
    await tiles.addTile('Nach Genre', _byGenre);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Krimi'));
    await tester.pumpAndSettle();

    final screen = tester.widget<StatisticsBooksScreen>(
      find.byType(StatisticsBooksScreen),
    );
    expect(screen.title, 'Krimi');
    expect([for (final b in screen.books) b.id], [1, 2]);
  });

  testWidgets('delete offers undo, which brings the tile back', (tester) async {
    await pump(tester);
    await tiles.addTile('Erste', _count);
    final id = await tiles.addTile('Zweite', _count);
    await tester.pumpAndSettle();

    await menu(tester, id, 'delete');
    expect(shownTitles(tester), ['Erste']);
    await tester.pump(const Duration(milliseconds: 500)); // snack bar in
    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();

    expect(shownTitles(tester), ['Erste', 'Zweite']);
  });

  testWidgets('the menu moves a tile and edits it', (tester) async {
    await pump(tester);
    await tiles.addTile('Erste', _count);
    final id = await tiles.addTile('Zweite', _count);
    await tester.pumpAndSettle();

    await menu(tester, id, 'up');
    expect(shownTitles(tester), ['Zweite', 'Erste']);

    await menu(tester, id, 'edit');
    await tester.enterText(
      find.byKey(const ValueKey('builder-title')),
      'Umbenannt',
    );
    await tester.tap(find.byKey(const ValueKey('builder-save')));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Umbenannt', 'Erste']);
  });

  testWidgets('a fourth pin is refused with a hint', (tester) async {
    await pump(tester);
    final ids = [
      for (var i = 0; i < 4; i++) await tiles.addTile('T$i', _count),
    ];
    for (final id in ids.take(3)) {
      await tiles.setPinned(id, pinned: true);
    }
    await tester.pumpAndSettle();

    await menu(tester, ids[3], 'pin');
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Auf der Startseite sind höchstens 3 Statistiken möglich.'),
      findsOneWidget,
    );
    expect(tiles.tiles.last.pinned, isFalse);
  });
}
