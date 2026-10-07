import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/domain/models/enums.dart';

/// Shared row-parsing helpers for importers.

List<String> parseAuthors(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(RegExp(r'[,;]'))
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList();
}

double? parseRating(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = double.tryParse(raw.trim());
  if (value == null) return null;
  return normalizeRating(value);
}

int? parseInt(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return int.tryParse(raw.trim());
}

/// Splits an ISBN into `(isbn13, isbn10)` after normalization.
(String?, String?) parseIsbnPair(String? raw) {
  final cleaned = cleanIsbn(raw);
  if (cleaned == null) return (null, null);
  if (cleaned.length == 13) return (cleaned, null);
  final isbn13 = isbn10To13(cleaned);
  return (isbn13, cleaned);
}

BookStatus? parseStatus(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  if (s == 'read' || s == 'gelesen') return BookStatus.read;
  if (s == 'currently-reading' ||
      s == 'reading' ||
      s == 'in progress' ||
      s == 'am lesen' ||
      s == 'started') {
    return BookStatus.reading;
  }
  if (s == 'to-read' ||
      s == 'wishlist' ||
      s == 'want to read' ||
      s == 'wunschliste') {
    return BookStatus.wishlist;
  }
  if (s == 'did-not-finish' || s == 'dnf' || s == 'abgebrochen') {
    return BookStatus.dnf;
  }
  return null;
}

BookFormat? parseFormat(String? raw) {
  if (raw == null) return null;
  switch (raw.trim().toLowerCase()) {
    case 'hardcover':
    case 'gebundene ausgabe':
      return BookFormat.hardcover;
    case 'paperback':
    case 'taschenbuch':
      return BookFormat.paperback;
    case 'ebook':
    case 'e-book':
      return BookFormat.ebook;
    case 'audiobook':
    case 'hörbuch':
      return BookFormat.audiobook;
  }
  return null;
}
