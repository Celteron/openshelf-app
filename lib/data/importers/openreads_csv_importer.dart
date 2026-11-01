import 'package:openreads/core/helpers/price.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the native Openreads CSV export (`doc/csv.md`, spec §5.3): besides
/// the bibliographic columns it carries `favourite`, `my_review`, `notes`,
/// `tags` (separated by `|||||`), `readings` and `date_added`.
///
/// It also reads the extra columns OpenShelf's own CSV export adds (quotes,
/// location path, series, lending status, current page, …), so an OpenShelf
/// CSV round-trips.
class OpenreadsCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'title': ColumnMapper.fieldTitle,
    'subtitle': ColumnMapper.fieldSubtitle,
    'author': ColumnMapper.fieldAuthors,
    'description': ColumnMapper.fieldDescription,
    'isbn': ColumnMapper.fieldIsbn,
    'isbn13': ColumnMapper.fieldIsbn13,
    'isbn10': ColumnMapper.fieldIsbn10,
    'pages': ColumnMapper.fieldPageCount,
    'publication_year': ColumnMapper.fieldPublishedYear,
    'book_type': ColumnMapper.fieldFormat,
    'book_format': ColumnMapper.fieldFormat,
    'rating': ColumnMapper.fieldRating,
    'status': ColumnMapper.fieldStatus,
    'favourite': ColumnMapper.fieldFavorite,
    'my_review': ColumnMapper.fieldReview,
    'notes': ColumnMapper.fieldNotes,
    'quotes': ColumnMapper.fieldQuotes,
    'tags': ColumnMapper.fieldTags,
    'readings': ColumnMapper.fieldReadings,
    'date_added': ColumnMapper.fieldDateAdded,
    'date_modified': ColumnMapper.fieldDateModified,
    'olid': ColumnMapper.fieldOlid,
    'genre': ColumnMapper.fieldGenre,
    'price': ColumnMapper.fieldPrice,
    'received_at': ColumnMapper.fieldReceivedAt,
    'received_as': ColumnMapper.fieldReceivedAs,
    'reading_seconds': ColumnMapper.fieldReadingSeconds,
    'publisher': ColumnMapper.fieldPublisher,
    'language': ColumnMapper.fieldLanguage,
    'current_page': ColumnMapper.fieldCurrentPage,
    'finished_at': ColumnMapper.fieldFinishedAt,
    'series': ColumnMapper.fieldSeriesName,
    'series_volume': ColumnMapper.fieldSeriesVolume,
    'location': ColumnMapper.fieldLocation,
    'lending_status': ColumnMapper.fieldLendingStatus,
    'borrower': ColumnMapper.fieldBorrower,
    'lent_at': ColumnMapper.fieldLentAt,
    'expected_return': ColumnMapper.fieldExpectedReturn,
    'cover_url': ColumnMapper.fieldCoverUrl,
    'deleted': 'deleted',
  });

  @override
  String get formatName => 'Openreads CSV';

  /// Separates the tags inside one cell.
  Pattern get tagSeparator => ExportService.tagSeparator;

  /// `deleted` is an internal flag, not something to match a column to.
  @override
  Set<String> get mappableFields =>
      super.mappableFields.difference({'deleted'});

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
    final (isbn13, isbn10) = _isbns(fields);
    final addedAt = parseDate(fields[ColumnMapper.fieldDateAdded]);
    final rating = double.tryParse(fields[ColumnMapper.fieldRating] ?? '');
    final lentAt = parseDate(fields[ColumnMapper.fieldLentAt]);
    final borrower = fields[ColumnMapper.fieldBorrower];
    final lent = fields[ColumnMapper.fieldLendingStatus] == 'lent';

    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      subtitle: fields[ColumnMapper.fieldSubtitle],
      authors: parseAuthors(fields[ColumnMapper.fieldAuthors]),
      description: fields[ColumnMapper.fieldDescription],
      isbn13: isbn13,
      isbn10: isbn10,
      publisher: fields[ColumnMapper.fieldPublisher],
      language: fields[ColumnMapper.fieldLanguage],
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
      tags: parseTags(fields[ColumnMapper.fieldTags], separator: tagSeparator),
      notes: [
        ..._splitNotes(fields[ColumnMapper.fieldNotes], NoteKind.note, addedAt),
        ..._splitNotes(
          fields[ColumnMapper.fieldQuotes],
          NoteKind.quote,
          addedAt,
        ),
      ],
      readings: (fields[ColumnMapper.fieldReadings] ?? '').trim().isNotEmpty
          ? parseOpenreadsReadings(fields[ColumnMapper.fieldReadings])
          // Plain start/finish date columns (own CSV files).
          : singleReading(
              parseDate(fields[ColumnMapper.fieldStartDate]),
              parseDate(fields[ColumnMapper.fieldFinishDate]),
            ),
      addedAt: addedAt,
      updatedAt: parseDate(fields[ColumnMapper.fieldDateModified]),
      olid: fields[ColumnMapper.fieldOlid],
      genre: fields[ColumnMapper.fieldGenre],
      priceCents: parsePriceCents(fields[ColumnMapper.fieldPrice]),
      receivedAt: parseDate(fields[ColumnMapper.fieldReceivedAt]),
      receivedAs: parseReceivedAs(fields[ColumnMapper.fieldReceivedAs]),
      readingSeconds: parseInt(fields[ColumnMapper.fieldReadingSeconds]),
      coverUrl: fields[ColumnMapper.fieldCoverUrl],
      seriesName: fields[ColumnMapper.fieldSeriesName],
      seriesVolume: double.tryParse(
        (fields[ColumnMapper.fieldSeriesVolume] ?? '').replaceAll(',', '.'),
      ),
      currentPage: parseInt(fields[ColumnMapper.fieldCurrentPage]),
      finishedAt: parseDate(fields[ColumnMapper.fieldFinishedAt]),
      locationPath: LocationRef.fromNames(
        (fields[ColumnMapper.fieldLocation] ?? '').split('>'),
      ),
      lendings: lent && borrower != null && borrower.trim().isNotEmpty
          ? [
              LendingImport(
                borrowerName: borrower.trim(),
                lentAt: lentAt ?? addedAt ?? DateTime.now(),
                expectedReturn: parseDate(
                  fields[ColumnMapper.fieldExpectedReturn],
                ),
              ),
            ]
          : const [],
    );
  }

  /// OpenShelf's CSV carries `isbn13`/`isbn10` next to the combined `isbn`.
  (String?, String?) _isbns(Map<String, String> fields) {
    final combined = parseIsbnPair(fields[ColumnMapper.fieldIsbn]);
    final explicit13 = parseIsbnPair(fields[ColumnMapper.fieldIsbn13]).$1;
    final explicit10 = parseIsbnPair(fields[ColumnMapper.fieldIsbn10]).$2;
    return (explicit13 ?? combined.$1, explicit10 ?? combined.$2);
  }

  List<NoteImport> _splitNotes(String? raw, NoteKind kind, DateTime? at) => [
    for (final part in (raw ?? '').split(ExportService.noteSeparator))
      if (part.trim().isNotEmpty)
        NoteImport(kind: kind, content: part.trim(), createdAt: at),
  ];
}
