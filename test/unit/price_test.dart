import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/helpers/price.dart';

void main() {
  group('parsePriceCents', () {
    test('reads German and English decimal notation', () {
      expect(parsePriceCents('12,90'), 1290);
      expect(parsePriceCents('12.90'), 1290);
      expect(parsePriceCents('12'), 1200);
      expect(parsePriceCents('0,5'), 50);
    });

    test('ignores currency symbols and whitespace', () {
      expect(parsePriceCents(' 12,90 € '), 1290);
      expect(parsePriceCents('€ 9.99'), 999);
      expect(parsePriceCents('EUR 7,00'), 700);
    });

    test('understands thousands separators', () {
      expect(parsePriceCents('1.299,00'), 129900);
      expect(parsePriceCents('1,299.50'), 129950);
    });

    test('returns null for blank, negative or unparseable input', () {
      expect(parsePriceCents(null), isNull);
      expect(parsePriceCents(''), isNull);
      expect(parsePriceCents('gratis'), isNull);
      expect(parsePriceCents('-3,00'), isNull);
    });

    test('rejects garbage instead of guessing', () {
      expect(parsePriceCents('1,2,3'), isNull);
      expect(parsePriceCents('1.5.2024'), isNull);
      expect(parsePriceCents('12,90 Euro'), 1290);
    });

    test('rejects amounts that would overflow', () {
      expect(parsePriceCents('99999999999999999'), isNull);
    });

    test('a zero price is a real value (gift), not missing', () {
      expect(parsePriceCents('0,00'), 0);
    });
  });

  group('formatPriceCents', () {
    test('formats with the locale decimal separator and euro sign', () {
      // intl separates the amount and the sign with a no-break space.
      expect(formatPriceCents(1290, 'de'), '12,90\u00A0€');
      expect(formatPriceCents(1290, 'en'), '€12.90');
      expect(formatPriceCents(0, 'de'), '0,00\u00A0€');
    });
  });

  group('priceInputText', () {
    test('renders a plain editable number', () {
      expect(priceInputText(1290), '12,90');
      expect(priceInputText(null), '');
    });
  });
}
