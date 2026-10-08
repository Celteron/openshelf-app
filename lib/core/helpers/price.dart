import 'package:intl/intl.dart';

/// Parses a user- or file-supplied price into euro cents.
///
/// Accepts German (`12,90`, `1.299,00`) and English (`12.90`, `1,299.50`)
/// notation with an optional currency marker (`€`, `EUR`, `Euro`). A `,` or
/// `.` followed by exactly three digits is a thousands separator, followed by
/// one or two digits it is the decimal separator. Returns `null` for blank,
/// negative, overlong or unparseable input. `0` is a valid price (a gift).
int? parsePriceCents(String? raw) {
  if (raw == null) return null;
  final cleaned = raw
      .replaceAll(RegExp(r'EUR(O)?|€', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s'), '');
  // Plain digits or digits grouped by thousands, then an optional 1–2 digit
  // decimal part. Anything else (`1,2,3`, a date like `1.5.2024`) is no price.
  final match = RegExp(
    r'^(\d{1,9}|\d{1,3}(?:[.,]\d{3})+)(?:[.,](\d{1,2}))?$',
  ).firstMatch(cleaned);
  if (match == null) return null;
  final euros = int.parse(match.group(1)!.replaceAll(RegExp(r'[.,]'), ''));
  final cents = int.parse((match.group(2) ?? '').padRight(2, '0'));
  return euros * 100 + cents;
}

/// A price for display, e.g. `12,90 €` (de) or `€12.90` (en).
String formatPriceCents(int cents, String locale) => NumberFormat.currency(
  locale: locale,
  symbol: '€',
  decimalDigits: 2,
).format(cents / 100);

/// A price as plain editable text (`12,90`); empty when there is none.
String priceInputText(int? cents) {
  if (cents == null) return '';
  final euros = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  return '$euros,$rest';
}
