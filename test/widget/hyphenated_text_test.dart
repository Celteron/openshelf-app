import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/features/common/widgets/hyphenated_text.dart';

void main() {
  // The test font draws every letter as a square of the font size.
  Future<void> pump(WidgetTester tester, String text, double width) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: HyphenatedText(
                  text,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('a long known word breaks at a syllable with a hyphen', (
    tester,
  ) async {
    // Text styles add a little letter spacing, so give the line some room.
    await pump(tester, 'Lesegeschwindigkeit', 140);

    final shown = tester.widget<Text>(find.byType(Text)).data!;
    expect(shown, 'Lesegeschwin-\ndigkeit');
  });

  testWidgets('no line is a single letter at any width', (tester) async {
    for (var width = 50.0; width <= 190; width += 5) {
      await pump(tester, 'Lesegeschwindigkeit', width);
      final shown = tester.widget<Text>(find.byType(Text)).data!;
      for (final line in shown.split('\n')) {
        expect(
          line.replaceAll('-', '').length,
          greaterThan(1),
          reason: '$width: $shown',
        );
      }
      expect(
        shown.replaceAll('-\n', ''),
        'Lesegeschwindigkeit',
        reason: '$width',
      );
    }
  });

  testWidgets('text that fits is a plain Text', (tester) async {
    await pump(tester, 'Seiten', 300);

    expect(tester.widget<Text>(find.byType(Text)).data, 'Seiten');
  });

  testWidgets('screen readers get the whole word', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, 'Lesegeschwindigkeit', 130);

    expect(find.bySemanticsLabel('Lesegeschwindigkeit'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('in an unbounded place it is a plain Text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HyphenatedText('Lesegeschwindigkeit'),
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.byType(Text)).data, 'Lesegeschwindigkeit');
  });
}
