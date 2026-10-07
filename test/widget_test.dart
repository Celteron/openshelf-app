import 'package:flutter/material.dart';
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

  testWidgets('RatingControl renders 48x48 tappable stars', (tester) async {
    double? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RatingControl(value: 2.5, onChanged: (v) => tapped = v),
        ),
      ),
    );

    // 5 stars × 2 halves = 10 tappable areas, each 48×48 dp.
    final stars = find.byType(InkWell);
    expect(stars, findsNWidgets(10));

    final size = tester.getSize(stars.first);
    expect(size.width, 48);
    expect(size.height, 48);

    // Tapping the first star half selects 0.5.
    await tester.tap(stars.first);
    expect(tapped, 0.5);
  });
}
