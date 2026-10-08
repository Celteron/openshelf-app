import 'dart:convert';

import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/core/helpers/price.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the legacy Bookstats JSON format (spec §5.3). German field names are
/// mapped flexibly; the exact shape is locked down by committed fixtures.
class BookstatsJsonImporter implements BookImporter {
  @override
  String get formatName => 'Bookstats JSON';

  @override
  ImportFileType get supportedType => ImportFileType.json;

  @override
  bool canParse(ImportFile file) {
    try {
      final decoded = jsonDecode(file.content);
      return _toList(decoded) != null;
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
      for (final key in const ['books', 'buecher', 'items']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return null;
  }

  String? _pick(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  BookImport _buildBook(Map<String, dynamic> map) {
    final title = _pick(map, const ['titel', 'title']);
    final author = _pick(map, const ['autor', 'autoren', 'author', 'authors']);
    final isbn = _pick(map, const ['isbn', 'isbn13', 'isbn10']);
    final (isbn13, isbn10) = parseIsbnPair(isbn);
    final addedAt = parseDate(
      _pick(map, const ['erhalten am', 'hinzugefuegt']),
    );

    double? rating;
    final rawRating = map['bewertung'] ?? map['rating'];
    if (rawRating is num) rating = normalizeRating(rawRating.toDouble());

    return BookImport(
      title: title,
      authors: parseAuthors(author),
      isbn13: isbn13,
      isbn10: isbn10,
      publisher: _pick(map, const ['verlag', 'publisher']),
      publishedYear: _pickInt(map, const ['jahr', 'erscheinungsjahr', 'year']),
      pageCount: _pickInt(map, const ['seiten', 'seitenzahl', 'pages']),
      language: _pick(map, const ['sprache', 'language']),
      rating: rating,
      status: parseStatus(_pick(map, const ['lesestatus', 'status'])),
      format: parseFormat(_pick(map, const ['buchart', 'format'])),
      isFavorite: map['favorit'] == true || map['favorite'] == true,
      review: _pick(map, const ['rezension', 'review']),
      genre: parseGenre(_pick(map, const ['genre'])),
      priceCents: _pickPriceCents(map),
      receivedAt: parseDate(_pick(map, const ['erhalten am'])),
      tags: parseTags(
        [
          _pick(map, const ['genre']),
          _pick(map, const ['kategorie', 'tags']),
        ].whereType<String>().join(';'),
        separator: ';',
      ),
      notes: noteList(
        _pick(map, const ['notizen', 'notes']),
        createdAt: addedAt,
      ),
      readings: singleReading(
        parseDate(_pick(map, const ['lesebeginn', 'startdatum'])),
        parseDate(_pick(map, const ['leseende', 'enddatum'])),
      ),
      addedAt: addedAt,
    );
  }

  /// Prices come as numbers (`12.9`, taken as euros) or text (`"12,90 €"`).
  int? _pickPriceCents(Map<String, dynamic> map) {
    final value = map['preis'] ?? map['price'];
    if (value is num) return value < 0 ? null : (value * 100).round();
    return value is String ? parsePriceCents(value) : null;
  }

  int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
