import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FR-P2-10: German (template) and English must define identical message
/// keys (`@key` placeholder metadata lives in the template only).
void main() {
  Set<String> keys(String path) =>
      (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
          .where((k) => !k.startsWith('@'))
          .toSet();

  test('app_de.arb and app_en.arb have identical key sets', () {
    final de = keys('lib/l10n/app_de.arb');
    final en = keys('lib/l10n/app_en.arb');
    expect(de.difference(en), isEmpty, reason: 'missing in en');
    expect(en.difference(de), isEmpty, reason: 'missing in de');
  });
}
