import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the Goodreads "Export to CSV" format (spec §5.3).
class GoodreadsCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'title': ColumnMapper.fieldTitle,
    'author': ColumnMapper.fieldAuthors,
    'additional authors': ColumnMapper.fieldAuthors,
    'isbn': ColumnMapper.fieldIsbn,
    'isbn13': ColumnMapper.fieldIsbn13,
    'my rating': ColumnMapper.fieldRating,
    'exclusive shelf': ColumnMapper.fieldStatus,
    'number of pages': ColumnMapper.fieldPageCount,
    'publisher': ColumnMapper.fieldPublisher,
    'binding': ColumnMapper.fieldFormat,
    'year published': ColumnMapper.fieldPublishedYear,
    'my review': ColumnMapper.fieldReview,
    'private notes': ColumnMapper.fieldNotes,
    'bookshelves': ColumnMapper.fieldTags,
    'date read': ColumnMapper.fieldFinishDate,
    'date added': ColumnMapper.fieldDateAdded,
  });

  /// Shelves that encode the reading status rather than a user category.
  static const _statusShelves = {
    'read',
    'to-read',
    'currently-reading',
    'did-not-finish',
  };

  @override
  String get formatName => 'Goodreads CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  @override
  Set<String> get expectedHeaders => {'title', 'author'};

  @override
  BookImport? buildBook(Map<String, String> fields) {
    final (isbn13, isbn10) = _parseIsbn(fields);
    final addedAt = parseDate(fields[ColumnMapper.fieldDateAdded]);
    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      authors: _goodreadsAuthors(fields[ColumnMapper.fieldAuthors]),
      isbn13: isbn13,
      isbn10: isbn10,
      publisher: fields[ColumnMapper.fieldPublisher],
      publishedYear: parseInt(fields[ColumnMapper.fieldPublishedYear]),
      pageCount: parseInt(fields[ColumnMapper.fieldPageCount]),
      format: parseFormat(fields[ColumnMapper.fieldFormat]),
      rating: parseRating(fields[ColumnMapper.fieldRating]),
      status: parseStatus(fields[ColumnMapper.fieldStatus]),
      review: fields[ColumnMapper.fieldReview],
      tags: parseTags(fields[ColumnMapper.fieldTags], ignore: _statusShelves),
      notes: noteList(fields[ColumnMapper.fieldNotes], createdAt: addedAt),
      readings: singleReading(
        null,
        parseDate(fields[ColumnMapper.fieldFinishDate]),
      ),
      addedAt: addedAt,
    );
  }

  (String?, String?) _parseIsbn(Map<String, String> fields) {
    String? isbn13;
    String? isbn10;
    final isbn13Field = fields[ColumnMapper.fieldIsbn13];
    if (isbn13Field != null) {
      final pair = parseIsbnPair(isbn13Field);
      isbn13 = pair.$1;
      isbn10 = pair.$2;
    }
    final isbnField = fields[ColumnMapper.fieldIsbn];
    if (isbnField != null) {
      final pair = parseIsbnPair(isbnField);
      isbn13 ??= pair.$1;
      isbn10 ??= pair.$2;
    }
    return (isbn13, isbn10);
  }

  /// Goodreads lists the primary author in "Author" (often "Last, First") and
  /// additional authors (comma-separated) in "Additional Authors". The base
  /// importer merges both columns into one `authors` value joined by ';'.
  List<String> _goodreadsAuthors(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final parts = raw.split(';');
    final authors = <String>[];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;
      if (i == 0) {
        authors.add(part);
      } else {
        authors.addAll(
          part.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
    }
    return authors;
  }
}
