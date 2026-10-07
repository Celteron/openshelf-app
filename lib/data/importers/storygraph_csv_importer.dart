import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the StoryGraph "Export to CSV" format (spec §5.3).
class StoryGraphCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'title': ColumnMapper.fieldTitle,
    'authors': ColumnMapper.fieldAuthors,
    'author': ColumnMapper.fieldAuthors,
    'isbn/uid': ColumnMapper.fieldIsbn,
    'isbn': ColumnMapper.fieldIsbn,
    'rating': ColumnMapper.fieldRating,
    'number of pages': ColumnMapper.fieldPageCount,
    'format': ColumnMapper.fieldFormat,
  });

  @override
  String get formatName => 'StoryGraph CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  @override
  Set<String> get expectedHeaders => {'title', 'authors'};

  @override
  BookImport? buildBook(Map<String, String> fields) {
    final (isbn13, isbn10) = parseIsbnPair(fields[ColumnMapper.fieldIsbn]);
    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      authors: parseAuthors(fields[ColumnMapper.fieldAuthors]),
      isbn13: isbn13,
      isbn10: isbn10,
      pageCount: parseInt(fields[ColumnMapper.fieldPageCount]),
      rating: parseRating(fields[ColumnMapper.fieldRating]),
      format: parseFormat(fields[ColumnMapper.fieldFormat]),
    );
  }
}
