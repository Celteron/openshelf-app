import 'dart:typed_data';

import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

/// Whether a legacy Openreads book JSON is soft-deleted (`deleted: 1`).
bool openreadsJsonIsDeleted(Map<String, dynamic> map) {
  final deleted = map['deleted'];
  return deleted == 1 || deleted == true || deleted == 'true';
}

/// Maps one legacy Openreads `Book.toJSON` object to a [BookImport]. Shared by
/// the JSON importer and the legacy backup archive importer.
///
/// `rating` is on the 0–50 integer scale (0.5 steps × 10), `status` on 0–3,
/// `tags` is `|||||`-separated and `readings` is `start|finish|millis;…`.
///
/// With [keepDeleted] a soft-deleted book is kept as a trashed book (full
/// backup restore); otherwise callers skip deleted rows.
BookImport bookImportFromOpenreadsJson(
  Map<String, dynamic> map, {
  Uint8List? coverBytes,
  bool keepDeleted = false,
}) {
  String? text(String key) {
    final value = map[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  final (isbn13, isbn10) = parseIsbnPair(map['isbn'] as String?);
  final addedAt = parseDate(text('date_added'));

  double? rating;
  final rawRating = map['rating'];
  if (rawRating is num) rating = normalizeRating(rawRating.toDouble() / 10.0);

  return BookImport(
    title: map['title'] as String?,
    subtitle: map['subtitle'] as String?,
    authors: parseAuthors(map['author'] as String?),
    isbn13: isbn13,
    isbn10: isbn10,
    pageCount: (map['pages'] as num?)?.toInt(),
    publishedYear: (map['publication_year'] as num?)?.toInt(),
    format: parseFormat(map['book_type'] as String?),
    rating: rating,
    status: _status((map['status'] as num?)?.toInt()),
    description: text('description'),
    isFavorite: map['favourite'] == 1 || map['favourite'] == true,
    review: text('my_review'),
    olid: text('olid'),
    tags: parseTags(text('tags'), separator: '|||||'),
    notes: noteList(text('notes'), createdAt: addedAt),
    readings: parseOpenreadsReadings(text('readings')),
    addedAt: addedAt,
    updatedAt: parseDate(text('date_modified')),
    deletedAt: keepDeleted && openreadsJsonIsDeleted(map)
        ? parseDate(text('date_modified')) ?? DateTime.now()
        : null,
    coverBytes: coverBytes,
  );
}

BookStatus? _status(int? value) {
  switch (value) {
    case 0:
      return BookStatus.read;
    case 1:
      return BookStatus.reading;
    case 2:
      return BookStatus.wishlist;
    case 3:
      return BookStatus.dnf;
  }
  return null;
}
