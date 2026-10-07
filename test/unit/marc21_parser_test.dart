import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/metadata/marc21_parser.dart';

void main() {
  const parser = Marc21Parser();

  String readFixture(String name) =>
      File('test/fixtures/marc21/$name').readAsStringSync();

  test('parses a full DNB SRU response into metadata', () {
    final metadata = parser.parse(readFixture('dnb_record.xml'))!;

    expect(metadata.isbn13, '9783442719255');
    expect(metadata.isbn10, '3442719252');
    expect(metadata.title, 'Der Vorleser');
    expect(metadata.subtitle, 'Roman');
    expect(metadata.authors, ['Schlink, Bernhard', 'Muster, Max']);
    expect(metadata.publisher, 'Diogenes');
    expect(metadata.publishedYear, 1997);
    expect(metadata.pageCount, 206);
    expect(metadata.seriesName, 'Diogenes Taschenbuch');
    expect(metadata.seriesVolume, 22988.0);
  });

  test('extracts the language code from controlfield 008', () {
    const xml = '''
<record xmlns="http://www.loc.gov/MARC21/slim">
  <controlfield tag="008">180406s2018    gw ||||| |||| 00| 0 ger d</controlfield>
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">Titel</subfield>
  </datafield>
</record>''';
    final metadata = parser.parse(xml)!;
    expect(metadata.language, 'ger');
  });

  test('830 overrides 490 for series', () {
    const xml = '''
<record xmlns="http://www.loc.gov/MARC21/slim">
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">Titel</subfield>
  </datafield>
  <datafield tag="490" ind1="1" ind2=" ">
    <subfield code="a">Alte Reihe</subfield>
    <subfield code="v">1</subfield>
  </datafield>
  <datafield tag="830" ind1=" " ind2="0">
    <subfield code="a">Neue Reihe</subfield>
    <subfield code="v">2</subfield>
  </datafield>
</record>''';
    final metadata = parser.parse(xml)!;
    expect(metadata.seriesName, 'Neue Reihe');
    expect(metadata.seriesVolume, 2.0);
  });

  test('strips MARC21 non-sorting control characters from the title', () {
    const xml = '''
<record xmlns="http://www.loc.gov/MARC21/slim">
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">\u0098Der\u009C Schwarm</subfield>
    <subfield code="b">Roman</subfield>
  </datafield>
</record>''';
    final metadata = parser.parse(xml)!;
    expect(metadata.title, 'Der Schwarm');
    expect(metadata.subtitle, 'Roman');
  });

  test('returns null for malformed XML', () {
    expect(parser.parse('<record><datafield'), isNull);
  });

  test('returns null when no data fields are present', () {
    expect(parser.parse('<empty></empty>'), isNull);
  });
}
