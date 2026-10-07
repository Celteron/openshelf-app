import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

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
  // Goodreads wraps ISBNs as `="0345339681"` to keep Excel from mangling them.
  final cleaned = cleanIsbn(raw?.replaceAll(RegExp(r'[="]'), ''));
  if (cleaned == null) return (null, null);
  if (cleaned.length == 13) return (cleaned, null);
  final isbn13 = isbn10To13(cleaned);
  return (isbn13, cleaned);
}

BookStatus? parseStatus(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  if (s == 'read' || s == 'gelesen' || s == 'finished') return BookStatus.read;
  if (s == 'currently-reading' ||
      s == 'reading' ||
      s == 'in progress' ||
      s == 'in_progress' ||
      s == 'am lesen' ||
      s == 'started') {
    return BookStatus.reading;
  }
  if (s == 'to-read' ||
      s == 'wishlist' ||
      s == 'want to read' ||
      s == 'planned' ||
      s == 'wunschliste') {
    return BookStatus.wishlist;
  }
  if (s == 'did-not-finish' ||
      s == 'dnf' ||
      s == 'abandoned' ||
      s == 'stopped-reading' ||
      s == 'abgebrochen') {
    return BookStatus.dnf;
  }
  if (s == 'unread' || s == 'ungelesen') return BookStatus.unread;
  if (s == 're_reading' || s == 'rereading' || s == 're-reading') {
    return BookStatus.reReading;
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
    case 'print':
      return BookFormat.paperback;
    case 'ebook':
    case 'e-book':
    case 'digital':
      return BookFormat.ebook;
    case 'audiobook':
    case 'audio':
    case 'hörbuch':
      return BookFormat.audiobook;
  }
  return null;
}

bool parseBool(String? raw) {
  final s = raw?.trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes' || s == 'ja';
}

/// Parses the date formats found in the supported exports: ISO 8601
/// (Openreads), `dd.MM.yyyy` (Bookstats) and `yyyy/MM/dd` (Goodreads,
/// StoryGraph). Returns `null` for anything else.
DateTime? parseDate(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  final german = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(s);
  if (german != null) {
    return _validDate(german.group(3)!, german.group(2)!, german.group(1)!);
  }
  final slashed = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$').firstMatch(s);
  if (slashed != null) {
    return _validDate(slashed.group(1)!, slashed.group(2)!, slashed.group(3)!);
  }
  return DateTime.tryParse(s);
}

DateTime? _validDate(String year, String month, String day) {
  final y = int.parse(year);
  final m = int.parse(month);
  final d = int.parse(day);
  final date = DateTime(y, m, d);
  // Reject overflow such as 31.02.2024 that DateTime would silently roll over.
  if (date.year != y || date.month != m || date.day != d) return null;
  return date;
}

/// Splits [raw] on [separator], trims, drops blanks and case-insensitive
/// duplicates. Values in [ignore] (lowercase) are dropped, and so are opaque
/// machine identifiers such as `7c9a6c79-19ea-4dea-90da-d7d47042d341_1001`
/// that some exports use in place of a category name.
List<String> parseTags(
  String? raw, {
  Pattern separator = ',',
  Set<String> ignore = const {},
}) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final seen = <String>{};
  final tags = <String>[];
  for (final part in raw.split(separator)) {
    final tag = part.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (tag.isEmpty || _opaqueId.hasMatch(tag)) continue;
    final key = tag.toLowerCase();
    if (ignore.contains(key) || !seen.add(key)) continue;
    tags.add(tag);
  }
  return tags;
}

final _opaqueId = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}');

/// Authors as written by Bookstats: either `First Last`, `Last, First`, or a
/// comma-separated mix of `Last, First` pairs (`Keeland, Vi, Ward, Penelope`).
///
/// The comma is ambiguous, so pairs are only formed when the token count is
/// even and no pair consists of two multi-word tokens (which would be two
/// `First Last` names, e.g. `Eric Stehfest, Michael J. Stephan`). Pairs are
/// rewritten to `First Last`.
List<String> parseLastFirstAuthors(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final tokens = raw
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.length < 2 || tokens.length.isOdd) return tokens;

  bool multiWord(String t) => t.contains(RegExp(r'\s'));
  final pairs = <(String, String)>[
    for (var i = 0; i < tokens.length; i += 2) (tokens[i], tokens[i + 1]),
  ];
  if (pairs.any((p) => multiWord(p.$1) && multiWord(p.$2))) return tokens;
  return [for (final (last, first) in pairs) '$first $last'];
}

/// Parses Openreads' `readings` value: `start|finish|customMillis` entries
/// joined by `;` (doc/csv.md). Entries without any value are dropped.
List<ReadingImport> parseOpenreadsReadings(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final readings = <ReadingImport>[];
  for (final entry in raw.split(';')) {
    final parts = entry.split('|');
    if (parts.length != 3) continue;
    final millis = int.tryParse(parts[2].trim());
    final reading = ReadingImport(
      startedAt: parseDate(parts[0]),
      finishedAt: parseDate(parts[1]),
      duration: millis == null || millis <= 0
          ? null
          : Duration(milliseconds: millis),
    );
    if (!reading.isEmpty) readings.add(reading);
  }
  return readings;
}

/// Builds the reading list for sources that only know a start and/or finish
/// date of the current read.
List<ReadingImport> singleReading(DateTime? start, DateTime? finish) {
  if (start == null && finish == null) return const [];
  return [ReadingImport(startedAt: start, finishedAt: finish)];
}

/// A free-text note as a one-element list, or empty for blank text.
List<NoteImport> noteList(String? text, {DateTime? createdAt}) {
  final content = text?.trim();
  if (content == null || content.isEmpty) return const [];
  return [NoteImport(content: content, createdAt: createdAt)];
}
