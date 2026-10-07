import 'dart:convert';

import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the native Openreads JSON export (spec §5.3). The inherited
/// Openreads `Book.toJSON` shape is the reference; `rating` is on a 0–50
/// integer scale (0.5 steps × 10) and `status` on a 0–3 integer scale.
class OpenreadsJsonImporter implements BookImporter {
  @override
  String get formatName => 'Openreads JSON';

  @override
  ImportFileType get supportedType => ImportFileType.json;

  @override
  bool canParse(ImportFile file) {
    try {
      final decoded = jsonDecode(file.content);
      final items = _toList(decoded);
      return items != null && items.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<ImportRow> parse(ImportFile file) async* {
    List<dynamic>? items;
    try {
      items = _toList(jsonDecode(file.content));
    } catch (_) {
      yield const ImportRow(rowNumber: 0, error: 'Malformed JSON');
      return;
    }
    if (items == null) return;

    for (var i = 0; i < items.length; i++) {
      try {
        final map = items[i] as Map<String, dynamic>;
        if (_isDeleted(map)) {
          yield ImportRow(rowNumber: i + 1, error: 'Deleted in source');
          continue;
        }
        final book = _buildBook(map);
        if (book.isEmpty) {
          yield ImportRow(rowNumber: i + 1, error: 'Empty row');
        } else {
          yield ImportRow(rowNumber: i + 1, book: book);
        }
      } catch (e) {
        yield ImportRow(rowNumber: i + 1, error: e.toString());
      }
    }
  }

  List<dynamic>? _toList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final books = decoded['books'];
      if (books is List) return books;
    }
    return null;
  }

  bool _isDeleted(Map<String, dynamic> map) {
    final deleted = map['deleted'];
    return deleted == 1 || deleted == true || deleted == 'true';
  }

  String? _text(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  BookImport _buildBook(Map<String, dynamic> map) {
    final (isbn13, isbn10) = parseIsbnPair(map['isbn'] as String?);

    final addedAt = parseDate(_text(map, 'date_added'));
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
      status: _parseStatus((map['status'] as num?)?.toInt()),
      description: _text(map, 'description'),
      isFavorite: map['favourite'] == 1 || map['favourite'] == true,
      review: _text(map, 'my_review'),
      tags: parseTags(_text(map, 'tags'), separator: '|||||'),
      notes: noteList(_text(map, 'notes'), createdAt: addedAt),
      readings: parseOpenreadsReadings(_text(map, 'readings')),
      addedAt: addedAt,
    );
  }

  BookStatus? _parseStatus(int? value) {
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
}
