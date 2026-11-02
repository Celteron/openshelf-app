import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/statistics.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';
import 'package:openreads/features/statistics/statistics_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _Noop implements BookRepository, LocationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeStatsCubit extends StatisticsCubit {
  final selected = <int?>[];
  final goals = <(int, int?)>[];

  FakeStatsCubit(BookStatistics stats) : super(_Noop(), _Noop()) {
    emit(StatisticsLoaded(stats));
  }

  @override
  void load() {}

  @override
  void selectYear(int? year) => selected.add(year);

  @override
  Future<void> setGoal(int targetBooks, {int? targetPages}) async =>
      goals.add((targetBooks, targetPages));
}

BookStatistics stats({
  List<int> years = const [2026, 2024],
  int? year,
  List<MonthStat>? monthly,
  GoalProgress? goal,
  double? averageRating,
  int? averagePages,
  Duration? averageReadingTime,
  NameCount? longest,
  NameCount? shortest,
  NameCount? fastest,
  NameCount? slowest,
}) => BookStatistics(
  totalBooks: 3,
  statusCounts: {for (final s in BookStatus.values) s: 0},
  pagesRead: 600,
  topLocations: const [],
  topAuthors: const [],
  years: years,
  year: year,
  monthly:
      monthly ??
      [
        for (var m = 1; m <= 12; m++)
          MonthStat(m, m == 1 ? 2 : 0, m == 1 ? 300 : 0),
      ],
  goal: goal,
  averageRating: averageRating,
  averagePages: averagePages,
  averageReadingTime: averageReadingTime,
  longestBook: longest,
  shortestBook: shortest,
  fastestBook: fastest,
  slowestBook: slowest,
);

Future<FakeStatsCubit> pump(WidgetTester tester, BookStatistics s) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final cubit = FakeStatsCubit(s);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<StatisticsCubit>.value(
        value: cubit,
        child: const StatisticsScreen(),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  group('year selector', () {
    testWidgets('lists all years and reports the selection', (tester) async {
      final cubit = await pump(tester, stats());
      expect(find.byKey(const ValueKey('stats-year')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('stats-year')));
      await tester.pumpAndSettle();
      expect(find.text('Alle Jahre'), findsWidgets);
      expect(find.text('2026'), findsWidgets);

      await tester.tap(find.text('2024').last);
      await tester.pumpAndSettle();
      expect(cubit.selected, [2024]);
    });

    testWidgets('can go back to all years', (tester) async {
      final cubit = await pump(tester, stats(year: 2024));

      await tester.tap(find.byKey(const ValueKey('stats-year')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alle Jahre').last);
      await tester.pumpAndSettle();

      expect(cubit.selected, [null]);
    });

    testWidgets('is hidden when no year has finished books', (tester) async {
      await pump(tester, stats(years: const []));
      expect(find.byKey(const ValueKey('stats-year')), findsNothing);
    });
  });

  group('monthly charts', () {
    testWidgets('show books and pages per month', (tester) async {
      await pump(tester, stats());

      expect(find.byKey(const ValueKey('chart-books')), findsOneWidget);
      expect(find.byKey(const ValueKey('chart-pages')), findsOneWidget);
      expect(
        find.byType(BarChart),
        findsNWidgets(3),
      ); // finished books, pages, added
      expect(find.text('Gelesene Bücher pro Monat'), findsOneWidget);
      expect(find.text('Gelesene Seiten pro Monat'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label ==
                  'Gelesene Bücher pro Monat: 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0',
        ),
        findsOneWidget,
        reason: 'screen readers get the twelve values',
      );
    });

    testWidgets('are drawn with twelve bars each', (tester) async {
      await pump(tester, stats());
      final charts = tester.widgetList<BarChart>(find.byType(BarChart));
      for (final chart in charts) {
        expect(chart.data.barGroups, hasLength(12));
      }
      expect(charts.first.data.barGroups.first.barRods.single.toY, 2.0);
    });

    testWidgets('an empty year still renders without error', (tester) async {
      await pump(
        tester,
        stats(monthly: [for (var m = 1; m <= 12; m++) MonthStat(m, 0, 0)]),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BarChart), findsNWidgets(3));
    });

    testWidgets('are left out for hand-built stats without months', (
      tester,
    ) async {
      await pump(tester, stats(monthly: const []));
      expect(find.byType(BarChart), findsNothing);
    });
  });

  group('averages and records', () {
    testWidgets('are listed with their values', (tester) async {
      await pump(
        tester,
        stats(
          averageRating: 4.25,
          averagePages: 312,
          averageReadingTime: const Duration(hours: 5, minutes: 30),
          longest: const NameCount('Der Lange', 900),
          shortest: const NameCount('Der Kurze', 80),
          fastest: const NameCount('Schnell', 3600),
          slowest: const NameCount('Langsam', 7200),
        ),
      );

      expect(find.byKey(const ValueKey('averages-card')), findsOneWidget);
      expect(find.text('Ø Bewertung'), findsOneWidget);
      expect(find.text('4.25'), findsOneWidget);
      expect(find.text('312 Seiten'), findsOneWidget);
      expect(find.text('5 Std. 30 Min.'), findsOneWidget);
      expect(find.text('Der Lange · 900 Seiten'), findsOneWidget);
      expect(find.text('Der Kurze · 80 Seiten'), findsOneWidget);
      expect(find.text('Schnell · 1 Std. 0 Min.'), findsOneWidget);
      expect(find.text('Langsam · 2 Std. 0 Min.'), findsOneWidget);
    });

    testWidgets('the card is hidden when there is nothing to show', (
      tester,
    ) async {
      await pump(tester, stats());
      expect(find.byKey(const ValueKey('averages-card')), findsNothing);
    });

    testWidgets('shows only the rows that have data', (tester) async {
      await pump(tester, stats(averageRating: 3.0));
      expect(find.text('Ø Bewertung'), findsOneWidget);
      expect(find.text('Ø Seitenzahl'), findsNothing);
      expect(find.text('Längstes Buch'), findsNothing);
    });
  });

  group('goal card', () {
    testWidgets('a pages-only goal shows just the page progress', (
      tester,
    ) async {
      await pump(
        tester,
        stats(
          goal: const GoalProgress(
            year: 2026,
            target: 0,
            completed: 5,
            expected: 0,
            targetPages: 2000,
            pagesRead: 500,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('goal-progress')), findsNothing);
      expect(find.byKey(const ValueKey('goal-pages-progress')), findsOneWidget);
      expect(find.text('500 von 2.000 Seiten'), findsOneWidget);
    });

    testWidgets('the dialog accepts a page goal without a book goal', (
      tester,
    ) async {
      final cubit = await pump(tester, stats());

      await tester.tap(find.text('Ziel festlegen'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('goal-pages-field')),
        '5000',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(cubit.goals, [(0, 5000)]);
    });

    testWidgets('both fields empty is rejected', (tester) async {
      final cubit = await pump(tester, stats());

      await tester.tap(find.text('Ziel festlegen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte eine Zahl größer 0 eingeben'), findsOneWidget);
      expect(cubit.goals, isEmpty);
    });

    testWidgets('editing a pages-only goal leaves the books field empty', (
      tester,
    ) async {
      await pump(
        tester,
        stats(
          goal: const GoalProgress(
            year: 2026,
            target: 0,
            completed: 0,
            expected: 0,
            targetPages: 2000,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Ziel ändern'));
      await tester.pumpAndSettle();

      final books = tester.widget<TextField>(find.byType(TextField).first);
      expect(books.controller!.text, isEmpty);
    });
  });
}
