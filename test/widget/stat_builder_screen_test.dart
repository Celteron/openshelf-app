import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:openreads/features/statistics/stat_builder_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

Book _book(int id, {String? genre, int? pages}) => Book(
  id: id,
  title: 'B$id',
  authors: const ['A'],
  status: BookStatus.read,
  rating: 0,
  genre: genre,
  pageCount: pages,
  finishedAt: DateTime(2026, 3, 1),
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2026),
);

/// Building a statistic (spec 005, T5-05).
void main() {
  (String, StatDefinition)? saved;

  Future<void> open(WidgetTester tester, {StatTile? tile}) async {
    saved = null;
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StatBuilderScreen(
                    library: StatLibrary(
                      books: [
                        _book(1, genre: 'Krimi', pages: 300),
                        _book(2, genre: 'Fantasy', pages: 200),
                      ],
                    ),
                    tile: tile,
                    now: () => DateTime(2026, 6, 1),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('builder-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('a preset fills everything and the preview shows real data', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('preset-booksByGenre')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('builder-title')))
          .controller
          ?.text,
      'Bücher nach Genre',
    );
    expect(find.text('Krimi'), findsOneWidget, reason: 'live preview');
    await save(tester);
    expect(saved?.$1, 'Bücher nach Genre');
    expect(saved?.$2, StatPreset.booksByGenre.definition(2026));
  });

  testWidgets('a time grouping offers bars and lines, not a donut', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('grouping-month')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chart-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-line')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-donut')), findsNothing);
  });

  testWidgets('built from scratch; without a title one is made up', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('measure-pages_read')));
    await tester.tap(find.byKey(const ValueKey('grouping-genre')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('period-2026')));
    await tester.tap(find.byKey(const ValueKey('filter-status-read')));
    await tester.pumpAndSettle();
    await save(tester);

    expect(saved?.$1, 'Gelesene Seiten nach Genre');
    expect(
      saved?.$2,
      const StatDefinition(
        measure: StatMeasure.pagesRead,
        grouping: StatGrouping.genre,
        period: StatYear(2026),
        chart: StatChart.bar,
        statuses: {BookStatus.read},
      ),
    );
  });

  testWidgets('editing starts from the tile and offers no presets', (
    tester,
  ) async {
    await open(
      tester,
      tile: StatTile(
        id: 1,
        title: 'Meine Seiten',
        definition: StatPreset.pagesPerMonth.definition(2026),
      ),
    );

    expect(find.byKey(const ValueKey('preset-booksByGenre')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chart-line')));
    await tester.pumpAndSettle();
    await save(tester);

    expect(saved?.$1, 'Meine Seiten');
    expect(saved?.$2.chart, StatChart.line);
    expect(saved?.$2.grouping, StatGrouping.month);
  });

  testWidgets('a deleted tag drops out of the filter when edited', (
    tester,
  ) async {
    await open(
      tester,
      tile: StatTile(
        id: 1,
        title: 'Krimis',
        definition: StatPreset.booksByGenre
            .definition(2026)
            .copyWith(tagIds: {99}),
      ),
    );

    await save(tester);

    expect(saved?.$2.tagIds, isEmpty);
  });
}
