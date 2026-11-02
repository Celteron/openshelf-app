import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/helpers/hyphenation.dart';

void main() {
  group('break points', () {
    test('a known word breaks at its syllables', () {
      expect(
        hyphenationPoints(
          'Lesegeschwindigkeit',
        ).map((i) => 'Lesegeschwindigkeit'.substring(0, i)),
        ['Lese', 'Lesege', 'Lesegeschwin', 'Lesegeschwindig'],
        reason: 'syllable joints, never a lone letter',
      );
    });

    test('a break leaves at least two letters before and three after', () {
      for (final word in germanHyphenationWords) {
        final plain = word.replaceAll('-', '');
        for (final i in hyphenationPoints(plain)) {
          expect(i, greaterThanOrEqualTo(2), reason: word);
          expect(plain.length - i, greaterThanOrEqualTo(3), reason: word);
        }
      }
    });

    test('case does not matter, punctuation around the word is kept out', () {
      expect(
        hyphenationPoints('zurücksetzen'),
        hyphenationPoints('Zurücksetzen'),
      );
      expect(hyphenationPoints('(Einkaufsliste)'), isNotEmpty);
    });

    test('an unknown word has no break point', () {
      expect(hyphenationPoints('Xyzzyplugh'), isEmpty);
      expect(hyphenationPoints(''), isEmpty);
    });

    test('every dictionary entry is made of its own syllables', () {
      for (final word in germanHyphenationWords) {
        expect(
          word,
          matches(RegExp(r'^[A-Za-zÄÖÜäöüß]+(-[A-Za-zÄÖÜäöüß]+)+$')),
        );
      }
    });
  });

  group('lines', () {
    // Every character is 10 wide, a hyphen too.
    double measure(String s) => s.length * 10.0;

    test('text that fits stays on one line', () {
      expect(breakIntoLines('Zu kurz', 100, measure), ['Zu kurz']);
    });

    test('words wrap at spaces as usual', () {
      expect(breakIntoLines('Eins zwei drei', 90, measure), [
        'Eins zwei',
        'drei',
      ]);
    });

    test('a long known word breaks at a syllable with a hyphen', () {
      expect(breakIntoLines('Lesegeschwindigkeit', 130, measure), [
        'Lesegeschwin-',
        'digkeit',
      ]);
    });

    test('the break is the latest one that fits', () {
      expect(breakIntoLines('Lesegeschwindigkeit', 150, measure), [
        'Lesegeschwin-',
        'digkeit',
      ]);
      expect(breakIntoLines('Lesegeschwindigkeit', 170, measure), [
        'Lesegeschwindig-',
        'keit',
      ]);
    });

    test('never leaves a single letter on a line', () {
      for (var width = 50.0; width <= 200; width += 10) {
        for (final line in breakIntoLines(
          'Lesegeschwindigkeit',
          width,
          measure,
        )) {
          expect(
            line.replaceAll('-', '').length,
            greaterThan(1),
            reason: '$width: $line',
          );
        }
      }
    });

    test('a word that fits on the next line is moved, not broken', () {
      expect(breakIntoLines('Die Einstellungen', 140, measure), [
        'Die',
        'Einstellungen',
      ]);
    });

    test('a word wider than any line fills the rest of the current one', () {
      expect(breakIntoLines('Die Einstellungen', 110, measure), [
        'Die Ein-',
        'stellungen',
      ]);
    });

    test('a word that cannot be broken is left to the engine', () {
      expect(breakIntoLines('Xyzzyplughabc', 50, measure), ['Xyzzyplughabc']);
    });

    test('a break that does not fit even alone is not taken', () {
      // 40 wide: even "Lese-" (50) does not fit, so the word stays whole.
      expect(breakIntoLines('Lesegeschwindigkeit', 40, measure), [
        'Lesegeschwindigkeit',
      ]);
    });

    test('the lines keep all letters', () {
      const text = 'Die Lesegeschwindigkeit und die Einstellungen';
      for (var width = 60.0; width <= 300; width += 10) {
        final lines = breakIntoLines(text, width, measure);
        expect(
          lines.join(' ').replaceAll('- ', '').replaceAll(' ', ''),
          text.replaceAll(' ', ''),
          reason: '$width',
        );
      }
    });
  });

  test('every long German UI word has break points', () {
    final arb =
        jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync())
            as Map<String, dynamic>;
    final missing = <String>{};
    for (final entry in arb.entries) {
      final value = entry.value;
      if (entry.key.startsWith('@') || value is! String) continue;
      final text = value.replaceAll(RegExp(r'\{[^}]*\}'), ' ');
      for (final m in RegExp(r'[A-Za-zÄÖÜäöüß]{13,}').allMatches(text)) {
        final word = m[0]!;
        // camelCase names (import field ids in a help text) are not prose.
        if (RegExp(r'[a-zäöüß][A-Z]').hasMatch(word)) continue;
        if (hyphenationPoints(word).isEmpty) {
          missing.add('$word (${entry.key})');
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'Add these to germanHyphenationWords in hyphenation.dart '
          '(syllables separated by "-"), or they wrap mid-word in narrow cards.',
    );
  });
}
