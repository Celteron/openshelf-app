import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/services/ocr_text.dart';

void main() {
  test('lines of one paragraph are joined', () {
    expect(
      cleanRecognizedText('Das ist ein Satz\nüber zwei Zeilen.'),
      'Das ist ein Satz über zwei Zeilen.',
    );
  });

  test(
    'a hyphen at the line end before a lower-case letter is a word break',
    () {
      expect(
        cleanRecognizedText('Ein Bei-\nspiel mit Um-\nbruch.'),
        'Ein Beispiel mit Umbruch.',
      );
    },
  );

  test('a hyphen before a capital stays: it is part of the word', () {
    expect(cleanRecognizedText('Nord-\nOst-Passage'), 'Nord- Ost-Passage');
  });

  test('blank lines stay as paragraph breaks', () {
    expect(
      cleanRecognizedText('Erster Absatz\nweiter.\n\nZweiter Absatz.'),
      'Erster Absatz weiter.\n\nZweiter Absatz.',
    );
  });

  test('stray spaces and surrounding whitespace are trimmed', () {
    expect(
      cleanRecognizedText('  Hallo   Welt \n\n\n\n Ende  '),
      'Hallo Welt\n\nEnde',
    );
  });

  test('nothing recognised gives an empty string', () {
    expect(cleanRecognizedText(' \n \n'), '');
  });
}
