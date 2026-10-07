import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/importers/csv_utils.dart';
import 'package:openreads/data/importers/import_decoding.dart';
import 'package:openreads/data/importers/import_parsing.dart';

void main() {
  group('parseLastFirstAuthors', () {
    test('flips "Last, First" and keeps "First Last"', () {
      expect(parseLastFirstAuthors('Reed, Ava'), ['Ava Reed']);
      expect(parseLastFirstAuthors('Sophie Jordan'), ['Sophie Jordan']);
      expect(parseLastFirstAuthors('Armentrout, Jennifer L.'), [
        'Jennifer L. Armentrout',
      ]);
      expect(parseLastFirstAuthors('Santos de Lima, Gabriella'), [
        'Gabriella Santos de Lima',
      ]);
    });

    test('splits several "Last, First" pairs', () {
      expect(parseLastFirstAuthors('Keeland, Vi, Ward, Penelope'), [
        'Vi Keeland',
        'Penelope Ward',
      ]);
      expect(parseLastFirstAuthors('Cast, P.C., Cast, Kristin'), [
        'P.C. Cast',
        'Kristin Cast',
      ]);
      expect(
        parseLastFirstAuthors('Green, John, Johnson, Maureen, Myracle, Lauren'),
        ['John Green', 'Maureen Johnson', 'Lauren Myracle'],
      );
    });

    test('treats two multi-word tokens as two "First Last" names', () {
      expect(parseLastFirstAuthors('Eric Stehfest, Michael J. Stephan'), [
        'Eric Stehfest',
        'Michael J. Stephan',
      ]);
    });

    test('handles blanks and odd token counts without inventing names', () {
      expect(parseLastFirstAuthors(null), isEmpty);
      expect(parseLastFirstAuthors('  '), isEmpty);
      expect(parseLastFirstAuthors('A, B, C'), ['A', 'B', 'C']);
    });
  });

  group('parseDate', () {
    test('reads ISO, German and slashed dates', () {
      expect(parseDate('2024-03-05T10:00:00.000'), DateTime(2024, 3, 5, 10));
      expect(parseDate('24.03.2022'), DateTime(2022, 3, 24));
      expect(parseDate('5.3.2022'), DateTime(2022, 3, 5));
      expect(parseDate('2021/12/31'), DateTime(2021, 12, 31));
    });

    test('rejects blanks, garbage and impossible dates', () {
      expect(parseDate(null), isNull);
      expect(parseDate(''), isNull);
      expect(parseDate('gestern'), isNull);
      expect(parseDate('31.02.2024'), isNull);
    });
  });

  group('parseTags', () {
    test('trims, de-duplicates case-insensitively and drops blanks', () {
      expect(parseTags(' Krimi, krimi ,, Thriller  ,Sci  Fi'), [
        'Krimi',
        'Thriller',
        'Sci Fi',
      ]);
    });

    test('drops ignored values and opaque machine ids', () {
      expect(
        parseTags(
          'read, Fantasy, 7c9a6c79-19ea-4dea-90da-d7d47042d341_1001',
          ignore: {'read'},
        ),
        ['Fantasy'],
      );
    });

    test('supports a custom separator', () {
      expect(parseTags('a|||||b|||||a', separator: '|||||'), ['a', 'b']);
    });
  });

  group('parseOpenreadsReadings', () {
    test('parses start|finish|millis entries joined by ;', () {
      final readings = parseOpenreadsReadings(
        '2024-01-02T00:00:00.000|2024-01-09T00:00:00.000|7200000;'
        '|2025-05-01T00:00:00.000|',
      );
      expect(readings, hasLength(2));
      expect(readings[0].startedAt, DateTime(2024, 1, 2));
      expect(readings[0].finishedAt, DateTime(2024, 1, 9));
      expect(readings[0].duration, const Duration(hours: 2));
      expect(readings[1].startedAt, isNull);
      expect(readings[1].finishedAt, DateTime(2025, 5, 1));
      expect(readings[1].duration, isNull);
    });

    test('drops empty and malformed entries', () {
      expect(parseOpenreadsReadings(''), isEmpty);
      expect(parseOpenreadsReadings('||'), isEmpty);
      expect(parseOpenreadsReadings('garbage'), isEmpty);
    });
  });

  group('parseIsbnPair', () {
    test('unwraps the Goodreads ="…" form', () {
      expect(parseIsbnPair('="9780345339683"'), ('9780345339683', null));
      expect(parseIsbnPair('="0345339681"').$2, '0345339681');
    });
  });

  group('CSV delimiter and decoding', () {
    test('detects ; , and tab from the header line', () {
      expect(detectCsvDelimiter('a;b;c\n1,2;3'), ';');
      expect(detectCsvDelimiter('a,b,c\n1;2;3'), ',');
      expect(detectCsvDelimiter('a\tb\tc\n'), '\t');
      expect(detectCsvDelimiter('single'), ',');
    });

    test('ignores delimiters inside quoted header cells', () {
      expect(detectCsvDelimiter('"a;b;c",d,e\n'), ',');
    });

    test('parses ;-separated quoted rows, CRLF and a BOM', () {
      final rows = parseCsvRows('﻿"A";"B"\r\n"x;y";"z"\r\n');
      expect(rows, [
        ['A', 'B'],
        ['x;y', 'z'],
      ]);
    });

    test('decodeImportBytes handles UTF-8, Latin-1 and BOMs', () {
      expect(decodeImportBytes(utf8.encode('Müller')), 'Müller');
      expect(decodeImportBytes(latin1.encode('Müller')), 'Müller');
      expect(decodeImportBytes([0xEF, 0xBB, 0xBF, ...utf8.encode('a')]), 'a');
    });
  });
}
