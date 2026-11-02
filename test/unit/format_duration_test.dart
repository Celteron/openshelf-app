import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/l10n/app_localizations_de.dart';

/// Reading time display (FR-R2-24).
void main() {
  final l10n = AppLocalizationsDe();

  test('short durations show minutes, or seconds under a minute', () {
    expect(formatDurationSeconds(l10n, 42), '42 Sek.');
    expect(formatDurationSeconds(l10n, 5 * 60 + 3), '5 Min.');
    expect(formatDurationSeconds(l10n, 3600 + 5 * 60), '1 Std. 5 Min.');
  });

  test('a day or more is shown in days and hours', () {
    expect(formatDurationSeconds(l10n, 86400 + 2 * 3600), '1 T. 2 Std.');
    expect(formatDurationSeconds(l10n, 30 * 3600), '1 T. 6 Std.');
  });

  test('negative input counts as nothing', () {
    expect(formatDurationSeconds(l10n, -5), '0 Sek.');
  });
}
