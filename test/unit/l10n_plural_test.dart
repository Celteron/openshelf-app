import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/l10n/app_localizations_de.dart';
import 'package:openreads/l10n/app_localizations_en.dart';

/// Counted texts use the singular for one.
void main() {
  test('one page is "1 Seite", not "1 Seiten"', () {
    expect(AppLocalizationsDe().pageCount(1), '1 Seite');
    expect(AppLocalizationsDe().pageCount(1200), '1.200 Seiten');
    expect(AppLocalizationsEn().pageCount(1), '1 page');
    expect(AppLocalizationsEn().pageCount(2), '2 pages');
  });
}
