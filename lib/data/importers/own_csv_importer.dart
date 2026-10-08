import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_utils.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/domain/models/import.dart';

/// Fallback for any CSV the other importers do not recognise: a file the user
/// made themselves. Column names in German and English are suggested to the
/// matcher, and the user assigns the rest before importing.
///
/// It reads the same fields as the Openreads CSV importer, so everything an
/// OpenShelf export can hold can be matched. It must be the *last* importer in
/// the detection order because it accepts every CSV with data.
class OwnCsvImporter extends OpenreadsCsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    for (final entry in _synonyms.entries)
      for (final header in entry.value) header: entry.key,
  });

  static const _synonyms = <String, List<String>>{
    ColumnMapper.fieldTitle: ['title', 'titel', 'buchtitel', 'book title'],
    ColumnMapper.fieldSubtitle: ['subtitle', 'untertitel'],
    ColumnMapper.fieldAuthors: [
      'author',
      'authors',
      'autor',
      'autoren',
      'autor(en)',
      'autorin',
      'verfasser',
    ],
    ColumnMapper.fieldIsbn: ['isbn'],
    ColumnMapper.fieldIsbn13: ['isbn13', 'isbn-13', 'isbn 13'],
    ColumnMapper.fieldIsbn10: ['isbn10', 'isbn-10', 'isbn 10'],
    ColumnMapper.fieldPublisher: ['publisher', 'verlag'],
    ColumnMapper.fieldPublishedYear: [
      'year',
      'jahr',
      'publication_year',
      'publication year',
      'erscheinungsjahr',
    ],
    ColumnMapper.fieldPageCount: [
      'pages',
      'seiten',
      'seitenzahl',
      'seitenanzahl',
      'number of pages',
    ],
    ColumnMapper.fieldFormat: ['format', 'buchart', 'book_format', 'binding'],
    ColumnMapper.fieldLanguage: ['language', 'sprache'],
    ColumnMapper.fieldDescription: [
      'description',
      'beschreibung',
      'klappentext',
    ],
    ColumnMapper.fieldRating: ['rating', 'bewertung', 'my rating'],
    ColumnMapper.fieldStatus: ['status', 'lesestatus', 'read status'],
    ColumnMapper.fieldSeriesName: ['series', 'serie', 'reihe'],
    ColumnMapper.fieldSeriesVolume: ['series_volume', 'volume', 'band'],
    ColumnMapper.fieldGenre: ['genre'],
    ColumnMapper.fieldTags: [
      'tags',
      'kategorie',
      'kategorien',
      'category',
      'categories',
    ],
    ColumnMapper.fieldNotes: ['notes', 'notizen'],
    ColumnMapper.fieldReview: ['review', 'my_review', 'rezension'],
    ColumnMapper.fieldPrice: ['price', 'preis'],
    ColumnMapper.fieldReceivedAt: ['received_at', 'received', 'erhalten am'],
    ColumnMapper.fieldDateAdded: [
      'date_added',
      'date added',
      'hinzugefügt am',
      'hinzugefuegt',
    ],
    ColumnMapper.fieldStartDate: ['start date', 'date started', 'lesebeginn'],
    ColumnMapper.fieldFinishDate: [
      'end date',
      'date finished',
      'date read',
      'leseende',
    ],
    ColumnMapper.fieldFavorite: ['favourite', 'favorite', 'favorit'],
    ColumnMapper.fieldLocation: ['location', 'standort'],
    ColumnMapper.fieldCoverUrl: ['cover', 'cover_url', 'cover url'],
    ColumnMapper.fieldOlid: ['olid'],
  };

  /// Everything the Openreads reader understands can be matched, so the
  /// suggestion list is not the limit.
  static final Set<String> _assignable = {
    ...OpenreadsCsvImporter().mappableFields,
    ColumnMapper.fieldStartDate,
    ColumnMapper.fieldFinishDate,
  };

  @override
  String get formatName => 'Custom CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  @override
  Set<String> get mappableFields => _assignable;

  @override
  Set<String> get expectedHeaders => const {};

  /// Own files separate tags by `;`, `,` or the Openreads marker.
  @override
  Pattern get tagSeparator => RegExp(r'\s*(?:;|,|\|\|\|\|\|)\s*');

  /// Accepts any CSV that has a header and at least one data row.
  @override
  bool canParse(ImportFile file) {
    try {
      return parseCsvRows(file.content).length >= 2;
    } catch (_) {
      return false;
    }
  }
}
