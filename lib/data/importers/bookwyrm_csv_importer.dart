import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the Bookwyrm "export to CSV" format (title, `author_text`,
/// `isbn_10`/`isbn_13`, `openlibrary_key`, `rating`, `review_content`, plus
/// `shelf`, `start_date`, `finish_date`).
///
/// Openreads treated every Bookwyrm row as read; when the export has a `shelf`
/// column the real status is used (`to-read`, `reading`, `read`,
/// `stopped-reading`), otherwise rows default to read.
class BookwyrmCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'title': ColumnMapper.fieldTitle,
    'author_text': ColumnMapper.fieldAuthors,
    'isbn_10': ColumnMapper.fieldIsbn10,
    'isbn_13': ColumnMapper.fieldIsbn13,
    'openlibrary_key': ColumnMapper.fieldOlid,
    'rating': ColumnMapper.fieldRating,
    'review_content': ColumnMapper.fieldReview,
    'shelf': ColumnMapper.fieldStatus,
    'start_date': ColumnMapper.fieldStartDate,
    'finish_date': ColumnMapper.fieldFinishDate,
  });

  @override
  String get formatName => 'Bookwyrm CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  @override
  Set<String> get expectedHeaders => {'title', 'author_text'};

  @override
  BookImport? buildBook(Map<String, String> fields) {
    final (isbn13, _) = parseIsbnPair(fields[ColumnMapper.fieldIsbn13]);
    final (fromTen13, isbn10) = parseIsbnPair(fields[ColumnMapper.fieldIsbn10]);
    final finish = parseDate(fields[ColumnMapper.fieldFinishDate]);
    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      authors: parseAuthors(fields[ColumnMapper.fieldAuthors]),
      isbn13: isbn13 ?? fromTen13,
      isbn10: isbn10,
      olid: fields[ColumnMapper.fieldOlid],
      rating: parseRating(fields[ColumnMapper.fieldRating]),
      review: fields[ColumnMapper.fieldReview],
      status: parseStatus(fields[ColumnMapper.fieldStatus]) ?? BookStatus.read,
      readings: singleReading(
        parseDate(fields[ColumnMapper.fieldStartDate]),
        finish,
      ),
    );
  }
}
