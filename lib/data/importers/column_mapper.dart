/// Canonical import field names and a flexible header → field mapper.
///
/// The mapper lets each importer declare how its source headers map to
/// canonical fields; the UI can confirm/override this mapping before import.
class ColumnMapper {
  static const fieldTitle = 'title';
  static const fieldSubtitle = 'subtitle';
  static const fieldAuthors = 'authors';
  static const fieldIsbn = 'isbn';
  static const fieldIsbn13 = 'isbn13';
  static const fieldIsbn10 = 'isbn10';
  static const fieldPublisher = 'publisher';
  static const fieldPublishedYear = 'publishedYear';
  static const fieldPageCount = 'pageCount';
  static const fieldFormat = 'format';
  static const fieldLanguage = 'language';
  static const fieldDescription = 'description';
  static const fieldRating = 'rating';
  static const fieldStatus = 'status';
  static const fieldSeriesName = 'seriesName';
  static const fieldSeriesVolume = 'seriesVolume';
  static const fieldFavorite = 'favorite';
  static const fieldReview = 'review';
  static const fieldNotes = 'notes';
  static const fieldTags = 'tags';
  static const fieldStartDate = 'startDate';
  static const fieldFinishDate = 'finishDate';
  static const fieldReadings = 'readings';
  static const fieldDateAdded = 'dateAdded';
  static const fieldOlid = 'olid';
  static const fieldQuotes = 'quotes';
  static const fieldCurrentPage = 'currentPage';
  static const fieldFinishedAt = 'finishedAt';
  static const fieldLocation = 'location';
  static const fieldBorrower = 'borrower';
  static const fieldLentAt = 'lentAt';
  static const fieldExpectedReturn = 'expectedReturn';
  static const fieldLendingStatus = 'lendingStatus';
  static const fieldCoverUrl = 'coverUrl';
  static const fieldDateModified = 'dateModified';

  /// Source header (lowercased and trimmed) → canonical field.
  final Map<String, String> headerToField;

  ColumnMapper(this.headerToField);

  String? fieldForHeader(String header) =>
      headerToField[header.trim().toLowerCase()];

  /// Maps a raw source row (header → value) to a canonical field → value map.
  Map<String, String> mapRow(Map<String, String> sourceRow) {
    final result = <String, String>{};
    for (final entry in sourceRow.entries) {
      final field = fieldForHeader(entry.key);
      if (field != null) result[field] = entry.value;
    }
    return result;
  }
}
