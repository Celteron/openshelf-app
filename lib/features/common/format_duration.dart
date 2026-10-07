import 'package:openreads/l10n/app_localizations.dart';

/// "1 Std. 5 Min." / "42 Min." for a duration given in seconds.
String formatDurationSeconds(AppLocalizations l10n, int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  return hours > 0
      ? l10n.durationHm(hours, minutes)
      : l10n.durationMin(minutes);
}

/// `HH:MM:SS` clock face for the live timer.
String formatClock(Duration elapsed) {
  final total = elapsed.isNegative ? 0 : elapsed.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two((total % 3600) ~/ 60)}:${two(total % 60)}';
}
