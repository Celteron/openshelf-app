import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/reading_stats.dart';
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

class FakeStatisticsCubit extends StatisticsCubit {
  final goals = <int>[];
  final pageGoals = <int?>[];
  int cleared = 0;

  FakeStatisticsCubit(BookStatistics stats) : super(_Noop(), _Noop()) {
    emit(StatisticsLoaded(stats));
  }

  @override
  void load() {}

  @override
  Future<void> setGoal(int targetBooks, {int? targetPages}) async {
    goals.add(targetBooks);
    pageGoals.add(targetPages);
  }

  @override
  Future<void> clearGoal() async => cleared++;
}

BookStatistics statsWith({GoalProgress? goal, ReadingStats? reading}) =>
    BookStatistics(
      totalBooks: 0,
      statusCounts: {for (final s in BookStatus.values) s: 0},
      pagesRead: 0,
      topLocations: const [],
      topAuthors: const [],
      goal: goal,
      reading: reading ?? const ReadingStats.empty(),
    );

Future<FakeStatisticsCubit> pump(
  WidgetTester tester,
  BookStatistics stats,
) async {
  final cubit = FakeStatisticsCubit(stats);
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
  testWidgets('without a goal the card offers to set one', (tester) async {
    final cubit = await pump(tester, statsWith());

    expect(find.textContaining('Leseziel'), findsOneWidget);
    expect(find.text('Ziel festlegen'), findsOneWidget);

    await tester.tap(find.text('Ziel festlegen'));
    await tester.pumpAndSettle();

    // Invalid input keeps the dialog open.
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.text('Speichern'));
    await tester.pump();
    expect(find.text('Bitte eine Zahl größer 0 eingeben'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '24');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(cubit.goals, [24]);
    expect(cubit.pageGoals, [null], reason: 'the page goal is optional');
  });

  testWidgets('an optional page goal is saved and validated', (tester) async {
    final cubit = await pump(tester, statsWith());

    await tester.tap(find.text('Ziel festlegen'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '24');
    await tester.enterText(
      find.byKey(const ValueKey('goal-pages-field')),
      '-5',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pump();
    expect(find.text('Bitte eine Zahl größer 0 eingeben'), findsOneWidget);
    expect(cubit.goals, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('goal-pages-field')),
      '8000',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(cubit.goals, [24]);
    expect(cubit.pageGoals, [8000]);
  });

  testWidgets('shows page-goal progress next to the book goal', (tester) async {
    await pump(
      tester,
      statsWith(
        goal: const GoalProgress(
          year: 2026,
          target: 10,
          completed: 3,
          expected: 3,
          targetPages: 4000,
          pagesRead: 1000,
        ),
      ),
    );

    expect(find.text('1000 von 4000 Seiten'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('goal-pages-progress')),
    );
    expect(bar.value, 0.25);
  });

  testWidgets('without a page goal no page progress is shown', (tester) async {
    await pump(
      tester,
      statsWith(
        goal: const GoalProgress(
          year: 2026,
          target: 10,
          completed: 3,
          expected: 3,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('goal-pages-progress')), findsNothing);
  });

  testWidgets('shows progress, remaining books and pace', (tester) async {
    await pump(
      tester,
      statsWith(
        goal: const GoalProgress(
          year: 2026,
          target: 10,
          completed: 3,
          expected: 5,
        ),
      ),
    );

    expect(find.text('3 von 10 Büchern'), findsOneWidget);
    expect(
      find.text('Noch 7 Bücher · 2 Bücher hinter dem Plan'),
      findsOneWidget,
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('goal-progress')),
    );
    expect(bar.value, closeTo(0.3, 1e-9));
  });

  testWidgets('reached goal and clearing', (tester) async {
    final cubit = await pump(
      tester,
      statsWith(
        goal: const GoalProgress(
          year: 2026,
          target: 2,
          completed: 2,
          expected: 1,
        ),
      ),
    );
    expect(find.text('Ziel erreicht!'), findsOneWidget);

    await tester.tap(find.byTooltip('Ziel entfernen'));
    expect(cubit.cleared, 1);
  });

  testWidgets('reading speed card shows pages/hour', (tester) async {
    await pump(
      tester,
      statsWith(
        reading: const ReadingStats(
          sessionCount: 1,
          totalSeconds: 3600,
          totalPages: 30,
          speedSeconds: 3600,
          speedPages: 30,
        ),
      ),
    );
    expect(find.text('30.0 Seiten/Std.'), findsOneWidget);
    expect(find.text('1 Std. 0 Min.'), findsOneWidget);
  });
}
