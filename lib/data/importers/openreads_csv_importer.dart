import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the native Openreads CSV export (`doc/csv.md`, spec §5.3): besides
/// the bibliographic columns it carries `favourite`, `my_review`, `notes`,
/// `tags` (separated by `|||||`), `readings` and `date_added`.
class OpenreadsCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'title': ColumnMapper.fieldTitle,
    'subtitle': ColumnMapper.fieldSubtitle,
    'author': ColumnMapper.fieldAuthors,
    'description': ColumnMapper.fieldDescription,
    'isbn': ColumnMapper.fieldIsbn,
    'pages': ColumnMapper.fieldPageCount,
    'publication_year': ColumnMapper.fieldPublishedYear,
    'book_type': ColumnMapper.fieldFormat,
    'book_format': ColumnMapper.fieldFormat,
    'rating': ColumnMapper.fieldRating,
    'status': ColumnMapper.fieldStatus,
    'favourite': ColumnMapper.fieldFavorite,
    'my_review': ColumnMapper.fieldReview,
    'notes': ColumnMapper.fieldNotes,
    'tags': ColumnMapper.fieldTags,
    'readings': ColumnMapper.fieldReadings,
    'date_added': ColumnMapper.fieldDateAdded,
    'deleted': 'deleted',
  });

  @override
  String get formatName => 'Openreads CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  /// `publication_year` separates Openreads from Goodreads, which also has
  /// `title` and `author`.
  @override
  Set<String> get expectedHeaders => {'title', 'author', 'publication_year'};

  @override
  BookImport? buildBook(Map<String, String> fields) {
    // Soft-deleted books must not come back to life.
    if (parseBool(fields['deleted'])) {
      throw const FormatException('Deleted in source');
    }
    final (isbn13, isbn10) = parseIsbnPair(fields[ColumnMapper.fieldIsbn]);
    final addedAt = parseDate(fields[ColumnMapper.fieldDateAdded]);
    final rating = double.tryParse(fields[ColumnMapper.fieldRating] ?? '');
    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      subtitle: fields[ColumnMapper.fieldSubtitle],
      authors: parseAuthors(fields[ColumnMapper.fieldAuthors]),
      description: fields[ColumnMapper.fieldDescription],
      isbn13: isbn13,
      isbn10: isbn10,
      pageCount: parseInt(fields[ColumnMapper.fieldPageCount]),
      publishedYear: parseInt(fields[ColumnMapper.fieldPublishedYear]),
      format: parseFormat(fields[ColumnMapper.fieldFormat]),
      // doc/csv.md documents 0.0–5.0; the legacy 0–50 integer scale is also
      // tolerated.
      rating: parseRating(
        rating == null ? null : (rating > 5 ? rating / 10 : rating).toString(),
      ),
      status: parseStatus(fields[ColumnMapper.fieldStatus]),
      isFavorite: parseBool(fields[ColumnMapper.fieldFavorite]),
      review: fields[ColumnMapper.fieldReview],
      tags: parseTags(fields[ColumnMapper.fieldTags], separator: '|||||'),
      notes: noteList(fields[ColumnMapper.fieldNotes], createdAt: addedAt),
      readings: parseOpenreadsReadings(fields[ColumnMapper.fieldReadings]),
      addedAt: addedAt,
    );
  }
}
