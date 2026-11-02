import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/features/reading/widgets/log_session_dialog.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Manual reading entry (spec 003): the time actually read is optional and has
/// a unit; the reading period (start → end date) is tracked separately.
void main() {
  ManualSession? result;

  Future<void> open(WidgetTester tester, {int startPage = 10}) async {
    result = null;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showDialog<ManualSession>(
                context: context,
                builder: (_) => LogSessionDialog(startPage: startPage),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves with only dates: no time, no end page', (tester) async {
    await open(tester);
    await save(tester);

    expect(result, isNotNull);
    expect(result!.duration, Duration.zero);
    expect(result!.startPage, 10);
    expect(result!.endPage, 10, reason: 'no end page = no progress');
  });

  testWidgets('minutes are the default unit', (tester) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('session-duration')),
      '90',
    );
    await save(tester);

    expect(result!.duration, const Duration(minutes: 90));
  });

  testWidgets('hours can be chosen as the unit', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('session-duration')), '2');
    await tester.tap(find.byKey(const ValueKey('session-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stunden').last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(result!.duration, const Duration(hours: 2));
  });

  testWidgets('decimal hours are understood (1,5 h = 90 min)', (tester) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('session-duration')),
      '1,5',
    );
    await tester.tap(find.byKey(const ValueKey('session-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stunden').last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(result!.duration, const Duration(minutes: 90));
  });

  testWidgets('a time that is not a positive number blocks saving', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('session-duration')), '0');
    await save(tester);

    expect(result, isNull);
    expect(find.text('Bitte eine Zahl größer 0 eingeben'), findsOneWidget);
  });

  testWidgets('the end page is kept when given', (tester) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('session-end-page')),
      '55',
    );
    await save(tester);

    expect((result!.startPage, result!.endPage), (10, 55));
  });

  for (final text in ['1e999', 'NaN', 'Infinity']) {
    testWidgets('"$text" is rejected instead of crashing', (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('session-duration')),
        text,
      );
      await save(tester);

      expect(result, isNull);
      expect(find.text('Bitte eine Zahl größer 0 eingeben'), findsOneWidget);
    });
  }
}
