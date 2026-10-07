import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the native Openreads CSV export (spec §5.3). The inherited Openreads
/// `Book.toJSON` shape is used as the reference; exact columns are validated
/// against a real export fixture during integration.
class OpenreadsCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'title': ColumnMapper.fieldTitle,
    'subtitle': ColumnMapper.fieldSubtitle,
    'author': ColumnMapper.fieldAuthors,
    'isbn': ColumnMapper.fieldIsbn,
    'pages': ColumnMapper.fieldPageCount,
    'publication_year': ColumnMapper.fieldPublishedYear,
    'book_type': ColumnMapper.fieldFormat,
    'rating': ColumnMapper.fieldRating,
    'status': ColumnMapper.fieldStatus,
  });

  @override
  String get formatName => 'Openreads CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  @override
  Set<String> get expectedHeaders => {'title', 'author'};

  @override
  BookImport? buildBook(Map<String, String> fields) {
    final (isbn13, isbn10) = parseIsbnPair(fields[ColumnMapper.fieldIsbn]);
    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      subtitle: fields[ColumnMapper.fieldSubtitle],
      authors: parseAuthors(fields[ColumnMapper.fieldAuthors]),
      isbn13: isbn13,
      isbn10: isbn10,
      pageCount: parseInt(fields[ColumnMapper.fieldPageCount]),
      publishedYear: parseInt(fields[ColumnMapper.fieldPublishedYear]),
      format: parseFormat(fields[ColumnMapper.fieldFormat]),
      rating: parseRating(fields[ColumnMapper.fieldRating]),
      status: parseStatus(fields[ColumnMapper.fieldStatus]),
    );
  }
}
