import 'package:openreads/l10n/app_localizations.dart';

/// Reading time for display (FR-R2-24): "1 T. 2 Std." from a day on,
/// "1 Std. 5 Min.", "42 Min.", and "42 Sek." under a minute.
String formatDurationSeconds(AppLocalizations l10n, int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final days = total ~/ 86400;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  if (days > 0) return l10n.durationDh(days, hours % 24);
  if (hours > 0) return l10n.durationHm(hours, minutes);
  if (minutes > 0) return l10n.durationMin(minutes);
  return l10n.durationSec(total);
}

/// `HH:MM:SS` clock face for the live timer.
String formatClock(Duration elapsed) {
  final total = elapsed.isNegative ? 0 : elapsed.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two((total % 3600) ~/ 60)}:${two(total % 60)}';
}
