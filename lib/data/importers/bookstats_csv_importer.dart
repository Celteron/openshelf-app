import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_importer_base.dart';
import 'package:openreads/data/importers/csv_utils.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/import.dart';

/// Imports the legacy Bookstats CSV format (German column headers, spec §5.3).
/// The column mapping is flexible and user-confirmed via [ColumnMapper].
class BookstatsCsvImporter extends CsvImporter {
  static final ColumnMapper _mapper = ColumnMapper({
    'titel': ColumnMapper.fieldTitle,
    'title': ColumnMapper.fieldTitle,
    'untertitel': ColumnMapper.fieldSubtitle,
    'autor': ColumnMapper.fieldAuthors,
    'autoren': ColumnMapper.fieldAuthors,
    'isbn': ColumnMapper.fieldIsbn,
    'isbn13': ColumnMapper.fieldIsbn13,
    'isbn10': ColumnMapper.fieldIsbn10,
    'verlag': ColumnMapper.fieldPublisher,
    'jahr': ColumnMapper.fieldPublishedYear,
    'erscheinungsjahr': ColumnMapper.fieldPublishedYear,
    'seiten': ColumnMapper.fieldPageCount,
    'seitenzahl': ColumnMapper.fieldPageCount,
    'bewertung': ColumnMapper.fieldRating,
    'rating': ColumnMapper.fieldRating,
    'status': ColumnMapper.fieldStatus,
    'format': ColumnMapper.fieldFormat,
    'sprache': ColumnMapper.fieldLanguage,
    'beschreibung': ColumnMapper.fieldDescription,
    'serie': ColumnMapper.fieldSeriesName,
    'reihe': ColumnMapper.fieldSeriesName,
    'band': ColumnMapper.fieldSeriesVolume,
  });

  @override
  String get formatName => 'Bookstats CSV';

  @override
  ColumnMapper get columnMapper => _mapper;

  @override
  Set<String> get expectedHeaders => {'titel', 'isbn'};

  @override
  bool canParse(ImportFile file) {
    try {
      final rows = parseCsvRows(file.content);
      if (rows.isEmpty) return false;
      final header = rows.first
          .map((e) => e.toString().trim().toLowerCase())
          .toSet();
      return header.contains('titel') || header.contains('isbn');
    } catch (_) {
      return false;
    }
  }

  @override
  BookImport? buildBook(Map<String, String> fields) {
    final (isbn13, isbn10) = parseIsbnPair(
      fields[ColumnMapper.fieldIsbn13] ?? fields[ColumnMapper.fieldIsbn],
    );
    return BookImport(
      title: fields[ColumnMapper.fieldTitle],
      subtitle: fields[ColumnMapper.fieldSubtitle],
      authors: parseAuthors(fields[ColumnMapper.fieldAuthors]),
      isbn13: isbn13,
      isbn10: isbn10,
      publisher: fields[ColumnMapper.fieldPublisher],
      publishedYear: parseInt(fields[ColumnMapper.fieldPublishedYear]),
      pageCount: parseInt(fields[ColumnMapper.fieldPageCount]),
      format: parseFormat(fields[ColumnMapper.fieldFormat]),
      language: fields[ColumnMapper.fieldLanguage],
      description: fields[ColumnMapper.fieldDescription],
      rating: parseRating(fields[ColumnMapper.fieldRating]),
      status: parseStatus(fields[ColumnMapper.fieldStatus]),
      seriesName: fields[ColumnMapper.fieldSeriesName],
      seriesVolume: _parseSeriesVolume(fields[ColumnMapper.fieldSeriesVolume]),
    );
  }

  double? _parseSeriesVolume(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }
}
