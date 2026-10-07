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

  BookImport _buildBook(Map<String, dynamic> map) {
    final (isbn13, isbn10) = parseIsbnPair(map['isbn'] as String?);

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
