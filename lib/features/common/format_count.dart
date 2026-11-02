import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A count grouped by the app language: "12.345" / "12,345" (FR-R2-24).
String formatCount(BuildContext context, int value) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value);
