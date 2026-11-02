import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/features/library/widgets/rating_control.dart';
import 'package:openreads/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations resolves German by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).navLibrary),
        ),
      ),
    );

    expect(find.text('Bibliothek'), findsOneWidget);
  });

  testWidgets('AppLocalizations falls back to English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).navLibrary),
        ),
      ),
    );

    expect(find.text('Library'), findsOneWidget);
  });

  group('RatingControl', () {
    Future<void> pumpControl(
      WidgetTester tester,
      double value,
      ValueChanged<double> onChanged,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RatingControl(value: value, onChanged: onChanged),
        ),
      ),
    );

    testWidgets('shows five stars, not ten', (tester) async {
      await pumpControl(tester, 2.5, (_) {});

      final icons = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((i) => i.icon)
          .toList();
      expect(icons, [
        Icons.star,
        Icons.star,
        Icons.star_half,
        Icons.star_border,
        Icons.star_border,
      ]);
    });

    testWidgets('the whole control is one large touch target', (tester) async {
      await pumpControl(tester, 0, (_) {});

      final size = tester.getSize(find.byKey(const ValueKey('rating-bar')));
      expect(size.height, greaterThanOrEqualTo(56));
      expect(size.width / 5, greaterThanOrEqualTo(60), reason: 'per star');
    });

    testWidgets('the left half of a star is a half, the right half a full', (
      tester,
    ) async {
      final taps = <double>[];
      await pumpControl(tester, 0, taps.add);
      final bar = tester.getTopLeft(find.byKey(const ValueKey('rating-bar')));
      const star = 60.0;

      await tester.tapAt(bar + const Offset(10, 28)); // star 1, left
      await tester.tapAt(bar + const Offset(50, 28)); // star 1, right
      await tester.tapAt(bar + const Offset(2 * star + 10, 28)); // star 3, left
      await tester.tapAt(
        bar + const Offset(2 * star + 50, 28),
      ); // star 3, right
      await tester.tapAt(
        bar + const Offset(4 * star + 50, 28),
      ); // star 5, right

      expect(taps, [0.5, 1.0, 2.5, 3.0, 5.0]);
    });

    testWidgets('a drag across the stars picks the value where it ends', (
      tester,
    ) async {
      final changes = <double>[];
      await pumpControl(tester, 0, changes.add);
      final bar = tester.getTopLeft(find.byKey(const ValueKey('rating-bar')));

      final gesture = await tester.startGesture(bar + const Offset(10, 28));
      await gesture.moveTo(bar + const Offset(150, 28));
      await gesture.moveTo(bar + const Offset(230, 28));
      expect(changes, isEmpty, reason: 'nothing is saved while dragging');
      await gesture.up();

      expect(changes, [4.0]);
    });

    testWidgets('a drag past the ends stays within 0.5 to 5', (tester) async {
      final changes = <double>[];
      await pumpControl(tester, 3, changes.add);
      final bar = tester.getTopLeft(find.byKey(const ValueKey('rating-bar')));

      final gesture = await tester.startGesture(bar + const Offset(150, 28));
      await gesture.moveTo(bar + const Offset(900, 28));
      await gesture.up();

      expect(changes, [5.0]);
    });

    testWidgets('the semantic zones still select their value', (tester) async {
      final handle = tester.ensureSemantics();
      final taps = <double>[];
      await pumpControl(tester, 0, taps.add);

      await tester.tap(find.bySemanticsLabel('3.5 stars'));
      await tester.tap(find.bySemanticsLabel('4.0 stars'));

      expect(taps, [3.5, 4.0]);
      handle.dispose();
    });

    testWidgets('screen readers can step the rating up and down', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final changes = <double>[];
      await pumpControl(tester, 3, changes.add);

      tester.semantics.performAction(
        find.semantics.byLabel('Rating'),
        SemanticsAction.increase,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Rating'),
        SemanticsAction.decrease,
      );

      expect(changes, [3.5, 2.5]);
      handle.dispose();
    });
  });
}
