import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/reading_calendar.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/features/statistics/reading_calendar_cubit.dart';
import 'package:openreads/features/statistics/reading_heatmap.dart';
import 'package:openreads/l10n/app_localizations.dart';

ReadingSession session(
  int bookId,
  DateTime start, {
  DateTime? end,
  int seconds = 0,
}) => ReadingSession(
  id: start.microsecondsSinceEpoch + bookId,
  bookId: bookId,
  startedAt: start,
  endedAt: end,
  durationSeconds: seconds,
  startPage: 0,
);

class _Reading implements ReadingRepository {
  final List<ReadingSession> sessions;
  _Reading(this.sessions);

  @override
  Stream<List<ReadingSession>> watchAllSessions() => Stream.value(sessions);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final today = DateTime(2026, 6, 15);

  Future<void> pump(WidgetTester tester, List<ReadingSession> sessions) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReadingHeatmap(
              calendar: ReadingCalendar.of(sessions),
              today: today,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the summary of the current year', (tester) async {
    await pump(tester, [
      session(
        1,
        DateTime(2026, 3, 4, 20),
        end: DateTime(2026, 3, 4, 21),
        seconds: 3600,
      ),
      session(2, DateTime(2026, 5, 1), end: DateTime(2026, 5, 3)),
    ]);

    expect(find.text('Lesekalender'), findsOneWidget);
    expect(
      find.text('1 Tag mit Lesezeit · 4 Tage mit Buch in Arbeit'),
      findsOneWidget,
    );
  });

  testWidgets('a cell carries its level; time beats "in progress"', (
    tester,
  ) async {
    await pump(tester, [
      session(
        1,
        DateTime(2026, 3, 4, 20),
        end: DateTime(2026, 3, 4, 21),
        seconds: 3600,
      ),
      session(2, DateTime(2026, 5, 1), end: DateTime(2026, 5, 3)),
    ]);

    expect(find.byKey(const ValueKey('heat-2026-03-04-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2026-05-02-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2026-04-10-0')), findsOneWidget);
  });

  testWidgets('days after today are not drawn as reading days', (tester) async {
    await pump(tester, [
      session(1, DateTime(2026, 6, 10), end: DateTime(2026, 6, 12)),
    ]);

    expect(find.byKey(const ValueKey('heat-2026-06-15-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2026-06-16-0')), findsNothing);
  });

  testWidgets('tapping a day tells what happened on it', (tester) async {
    await pump(tester, [
      session(
        1,
        DateTime(2026, 3, 4, 20),
        end: DateTime(2026, 3, 4, 21),
        seconds: 3600,
      ),
    ]);

    await tester.tap(find.byKey(const ValueKey('heat-2026-03-04-4')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('1 Std. 0 Min. gelesen · 1 Buch in Arbeit'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('heat-2026-04-10-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('nichts gelesen'), findsOneWidget);
  });

  testWidgets('the arrows move between years that have data', (tester) async {
    await pump(tester, [
      session(1, DateTime(2025, 1, 5), end: DateTime(2025, 1, 6)),
      session(2, DateTime(2026, 2, 5), end: DateTime(2026, 2, 6)),
    ]);
    expect(find.text('2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('heatmap-prev')));
    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2025-01-05-1')), findsOneWidget);
    final prev = tester.widget<IconButton>(
      find.byKey(const ValueKey('heatmap-prev')),
    );
    expect(prev.onPressed, isNull, reason: 'no earlier year');
  });

  testWidgets('without data it says how to get some', (tester) async {
    await pump(tester, const []);

    expect(find.textContaining('Noch keine Lesedaten'), findsOneWidget);
  });

  test('the cubit builds the calendar from all sessions', () async {
    final cubit = ReadingCalendarCubit(
      _Reading([session(1, DateTime(2026, 3, 4), end: DateTime(2026, 3, 5))]),
    );
    addTearDown(cubit.close);

    cubit.load();
    await cubit.stream.firstWhere((s) => s is ReadingCalendarLoaded);

    final state = cubit.state as ReadingCalendarLoaded;
    expect(state.calendar.dayOf(DateTime(2026, 3, 5)).level, 1);
  });
}
