import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:openreads/features/statistics/stat_tile_view.dart';
import 'package:openreads/l10n/app_localizations.dart';

StatDefinition _def(
  StatMeasure measure, {
  StatGrouping? grouping,
  StatChart? chart,
}) => StatDefinition(
  measure: measure,
  grouping: grouping,
  period: const StatYear(2026),
  chart: chart ?? StatDefinition.chartsFor(grouping).first,
);

/// How a user-defined statistic is drawn (spec 005, FR-05-05/07/10).
void main() {
  /// Label and book ids per drill-down, as lists so sets compare by value.
  final opened = <List<Object>>[];

  Future<void> pump(
    WidgetTester tester,
    StatDefinition definition,
    StatResult result, {
    StatLibrary library = const StatLibrary(),
  }) async {
    opened.clear();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatTileView(
              id: 'tile',
              title: 'Meine Statistik',
              definition: definition,
              result: result,
              library: library,
              onBooks: (label, ids) => opened.add([label, ids]),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a single number is formatted for its measure and opens its '
      'books', (tester) async {
    await pump(
      tester,
      _def(StatMeasure.pagesRead),
      const StatSingle(1200, {1, 2}),
    );

    expect(find.text('1.200'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tile-value')));
    expect(opened, [
      [
        'Meine Statistik',
        {1, 2},
      ],
    ]);
  });

  testWidgets('reading time reads as a duration, spending as money', (
    tester,
  ) async {
    await pump(
      tester,
      _def(StatMeasure.readingTime),
      const StatSingle(5400, {1}),
    );
    expect(find.text('1 Std. 30 Min.'), findsOneWidget);

    await pump(tester, _def(StatMeasure.spending), const StatSingle(2550, {1}));
    expect(find.text('25,50 €'), findsOneWidget);
  });

  testWidgets('an average over nothing shows a dash, not 0', (tester) async {
    await pump(
      tester,
      _def(StatMeasure.averageRating),
      const StatSingle(null, {}),
    );
    expect(find.text('–'), findsOneWidget);
  });

  testWidgets('months: a summary for screen readers and a month sheet', (
    tester,
  ) async {
    await pump(
      tester,
      _def(StatMeasure.pagesRead, grouping: StatGrouping.month),
      StatSeries([
        for (var m = 1; m <= 12; m++)
          StatEntry(StatMonth(m), m == 3 ? 320 : 0, m == 3 ? {7} : const {}),
      ]),
    );

    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp(r'^Meine Statistik: Januar 0, .*März 320')),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.tap(find.byKey(const ValueKey('tile-chart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tile-entry-2')));
    await tester.pumpAndSettle();
    expect(opened, [
      [
        'März',
        {7},
      ],
    ]);
  });

  testWidgets('categories are rows; beyond eight a sheet lists them all', (
    tester,
  ) async {
    await pump(
      tester,
      _def(StatMeasure.books, grouping: StatGrouping.author),
      StatSeries([
        for (var i = 0; i < 10; i++)
          StatEntry(StatText('Autor $i'), 10.0 - i, {i}),
      ]),
    );

    expect(find.text('Autor 0'), findsOneWidget);
    expect(find.text('Autor 8'), findsNothing);
    await tester.tap(find.text('Autor 1'));
    expect(opened, [
      [
        'Autor 1',
        {1},
      ],
    ]);

    await tester.tap(find.byKey(const ValueKey('tile-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autor 9'));
    await tester.pumpAndSettle();
    expect(opened.last, [
      'Autor 9',
      {9},
    ]);
  });

  testWidgets('a donut keeps eight slices and groups the rest as Other', (
    tester,
  ) async {
    await pump(
      tester,
      _def(
        StatMeasure.books,
        grouping: StatGrouping.genre,
        chart: StatChart.donut,
      ),
      StatSeries([
        for (var i = 0; i < 10; i++)
          StatEntry(StatText('Genre $i'), 10.0 - i, {i}),
      ]),
    );

    expect(find.text('Genre 6'), findsOneWidget);
    expect(find.text('Genre 7'), findsNothing);
    await tester.tap(find.text('Andere'));
    expect(opened, [
      [
        'Andere',
        {7, 8, 9},
      ],
    ]);
  });

  testWidgets('labels use the names of statuses, tags and locations', (
    tester,
  ) async {
    await pump(
      tester,
      _def(StatMeasure.books, grouping: StatGrouping.tag),
      const StatSeries([
        StatEntry(StatTag(4), 2, {1, 2}),
        StatEntry(StatTag(99), 1, {3}),
      ]),
      library: const StatLibrary(tagNames: {4: 'Krimi'}),
    );

    expect(find.text('Krimi'), findsOneWidget);
    expect(
      find.text('Bücher mit mehreren Tags zählen mehrfach.'),
      findsOneWidget,
    );

    await pump(
      tester,
      _def(StatMeasure.books, grouping: StatGrouping.status),
      const StatSeries([
        StatEntry(StatStatus(BookStatus.unread), 1, {1}),
      ]),
    );
    expect(find.text('Ungelesen'), findsOneWidget);
  });

  testWidgets('nothing to show says so', (tester) async {
    await pump(
      tester,
      _def(StatMeasure.books, grouping: StatGrouping.genre),
      const StatSeries([]),
    );
    expect(find.text('Noch keine Daten.'), findsOneWidget);
  });
}
