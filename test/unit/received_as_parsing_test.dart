import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/enums.dart';

/// "Erhalten als" values from Bookstats and other sources (FR-R2-07).
void main() {
  test('maps the German and English words', () {
    expect(parseReceivedAs('Kauf'), ReceivedAs.purchase);
    expect(parseReceivedAs(' gekauft '), ReceivedAs.purchase);
    expect(parseReceivedAs('Geschenk'), ReceivedAs.gift);
    expect(parseReceivedAs('Leihe'), ReceivedAs.loan);
    expect(parseReceivedAs('Ausleihe'), ReceivedAs.loan);
    expect(parseReceivedAs('Rezensionsexemplar'), ReceivedAs.reviewCopy);
    expect(parseReceivedAs('review copy'), ReceivedAs.reviewCopy);
  });

  test('reads the exported enum names back', () {
    for (final value in ReceivedAs.values) {
      expect(parseReceivedAs(value.name), value);
    }
    expect(parseReceivedAs('review_copy'), ReceivedAs.reviewCopy);
  });

  test('blank is unknown, anything else is other', () {
    expect(parseReceivedAs(null), isNull);
    expect(parseReceivedAs('  '), isNull);
    expect(parseReceivedAs('Tausch'), ReceivedAs.other);
  });
}
