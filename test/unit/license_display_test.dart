import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/l10n/app_localizations_de.dart';
import 'package:openreads/l10n/app_localizations_en.dart';

/// The Settings screen renders `licenseText`; it must read GPL-2.0 in every
/// language.
void main() {
  test('the license is shown as GPL-2.0 in German and English', () {
    expect(AppLocalizationsDe().licenseText, 'GPL-2.0');
    expect(AppLocalizationsEn().licenseText, 'GPL-2.0');
  });
}
