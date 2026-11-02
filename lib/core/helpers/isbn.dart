/// ISBN normalization helpers.
///
/// ISBNs are normalized to ISBN-13 at every entry point (manual, scanner,
/// importer, lookup) so duplicate detection and metadata lookups operate on a
/// single canonical key (spec FR-014).
library;

/// Removes separators and returns a compact digit string, or `null` when the
/// input is not a plausible ISBN (10 or 13 digits, with optional `X` check
/// character for ISBN-10).
String? cleanIsbn(String? input) {
  if (input == null) return null;
  final cleaned = input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  if (cleaned.length == 10 || cleaned.length == 13) return cleaned;
  return null;
}

bool _isDigits(String s) => RegExp(r'^\d+$').hasMatch(s);

bool isValidIsbn13(String isbn13) {
  if (isbn13.length != 13 || !_isDigits(isbn13)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final digit = int.parse(isbn13[i]);
    sum += (i.isEven) ? digit : digit * 3;
  }
  final check = (10 - (sum % 10)) % 10;
  return check == int.parse(isbn13[12]);
}

bool isValidIsbn10(String isbn10) {
  if (isbn10.length != 10) return false;
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    final c = isbn10[i];
    final value = (c == 'X' && i == 9)
        ? 10
        : (c == 'X' ? null : int.tryParse(c));
    if (value == null) return false;
    sum += value * (10 - i);
  }
  return sum % 11 == 0;
}

/// Converts an ISBN-10 to its ISBN-13 equivalent (EAN prefix 978). Returns
/// `null` when [isbn10] is not a valid ISBN-10.
String? isbn10To13(String isbn10) {
  if (!isValidIsbn10(isbn10)) return null;
  final prefix = '978${isbn10.substring(0, 9)}';
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final digit = int.parse(prefix[i]);
    sum += (i.isEven) ? digit : digit * 3;
  }
  final check = (10 - (sum % 10)) % 10;
  return '$prefix$check';
}

/// Normalizes any ISBN (10 or 13) to its canonical ISBN-13 form.
///
/// Returns `null` when the input is neither a valid ISBN-10 nor ISBN-13.
String? normalizeIsbn(String? input) {
  final cleaned = cleanIsbn(input);
  if (cleaned == null) return null;
  if (cleaned.length == 13) {
    return isValidIsbn13(cleaned) ? cleaned : null;
  }
  return isbn10To13(cleaned);
}
