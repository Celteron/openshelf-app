import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/helpers/isbn.dart';

void main() {
  group('isValidIsbn13', () {
    test('accepts a valid ISBN-13', () {
      expect(isValidIsbn13('9780306406157'), isTrue);
    });

    test('rejects a wrong check digit', () {
      expect(isValidIsbn13('9780306406150'), isFalse);
    });

    test('rejects wrong length', () {
      expect(isValidIsbn13('978030640615'), isFalse);
      expect(isValidIsbn13('97803064061578'), isFalse);
    });
  });

  group('isValidIsbn10', () {
    test('accepts a valid ISBN-10', () {
      expect(isValidIsbn10('0306406152'), isTrue);
    });

    test('accepts ISBN-10 with X check digit', () {
      expect(isValidIsbn10('097522980X'), isTrue);
    });

    test('rejects invalid ISBN-10', () {
      expect(isValidIsbn10('0306406150'), isFalse);
    });
  });

  group('isbn10To13', () {
    test('converts ISBN-10 to ISBN-13', () {
      expect(isbn10To13('0306406152'), '9780306406157');
    });
  });

  group('normalizeIsbn', () {
    test('normalizes a dashed ISBN-13', () {
      expect(normalizeIsbn('978-0-306-40615-7'), '9780306406157');
    });

    test('normalizes an ISBN-10 to ISBN-13', () {
      expect(normalizeIsbn('0-306-40615-2'), '9780306406157');
    });

    test('returns null for garbage', () {
      expect(normalizeIsbn('123'), isNull);
      expect(normalizeIsbn(''), isNull);
      expect(normalizeIsbn(null), isNull);
    });

    test('returns null for invalid check digit', () {
      expect(normalizeIsbn('9780306406150'), isNull);
    });
  });
}
