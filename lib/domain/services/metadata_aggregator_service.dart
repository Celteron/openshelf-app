import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';

/// Orchestrates metadata sources in strict priority order and merges
/// deterministically:
///
///   1. DNB SRU (authoritative bibliographic fields)
///   2. Google Books (enrichment: cover URL + description)
///   3. Open Library (fallback when 1 and 2 yield nothing)
///
/// Merge rules (Constitution Article III / spec §4.3):
///   - User-edited fields are never overwritten.
///   - Higher-priority sources win; a source only fills fields still empty.
class MetadataAggregatorService {
  static const Set<String> dnbFields = {
    'isbn13',
    'isbn10',
    'title',
    'subtitle',
    'authors',
    'publisher',
    'publishedYear',
    'pageCount',
    'language',
    'seriesName',
    'seriesVolume',
  };

  static const Set<String> googleBooksFields = {'coverUrl', 'description'};

  static const Set<String> openLibraryFields = {
    'isbn13',
    'isbn10',
    'title',
    'subtitle',
    'authors',
    'publisher',
    'publishedYear',
    'pageCount',
    'language',
    'description',
    'coverUrl',
    'format',
  };

  final List<MetadataSourceStrategy> sources;

  const MetadataAggregatorService(this.sources);

  Future<AggregatedMetadata> enrich(
    BookMetadata base, {
    Set<String> editedFields = const {},
  }) async {
    final isbn = base.isbn13 ?? base.isbn10;
    if (isbn == null || isbn.isEmpty) {
      return AggregatedMetadata(metadata: base);
    }

    var merged = base;
    MetadataSource? primary;
    for (final source in sources) {
      BookMetadata? incoming;
      try {
        incoming = await source.lookupByIsbn(isbn);
      } catch (_) {
        incoming = null;
      }
      if (incoming == null || incoming.isEmpty) continue;

      merged = _merge(merged, incoming, _fillableFor(source.id), editedFields);
      primary ??= source.id;
    }

    return AggregatedMetadata(metadata: merged, primarySource: primary);
  }

  Set<String> _fillableFor(MetadataSource source) {
    switch (source) {
      case MetadataSource.dnb:
        return dnbFields;
      case MetadataSource.googleBooks:
        return googleBooksFields;
      case MetadataSource.openLibrary:
        return openLibraryFields;
      case MetadataSource.manual:
        return const {};
    }
  }

  BookMetadata _merge(
    BookMetadata base,
    BookMetadata incoming,
    Set<String> fillable,
    Set<String> edited,
  ) {
    bool can(String f) => fillable.contains(f) && !edited.contains(f);

    String? pick(String f, String? baseVal, String? incVal) =>
        can(f) && (baseVal == null || baseVal.isEmpty) && incVal != null
        ? incVal
        : baseVal;

    return BookMetadata(
      isbn13: pick('isbn13', base.isbn13, incoming.isbn13),
      isbn10: pick('isbn10', base.isbn10, incoming.isbn10),
      title: pick('title', base.title, incoming.title),
      subtitle: pick('subtitle', base.subtitle, incoming.subtitle),
      authors:
          can('authors') && base.authors.isEmpty && incoming.authors.isNotEmpty
          ? incoming.authors
          : base.authors,
      publisher: pick('publisher', base.publisher, incoming.publisher),
      publishedYear:
          can('publishedYear') &&
              base.publishedYear == null &&
              incoming.publishedYear != null
          ? incoming.publishedYear
          : base.publishedYear,
      pageCount:
          can('pageCount') &&
              base.pageCount == null &&
              incoming.pageCount != null
          ? incoming.pageCount
          : base.pageCount,
      format: can('format') && base.format == null && incoming.format != null
          ? incoming.format
          : base.format,
      language: pick('language', base.language, incoming.language),
      description: pick('description', base.description, incoming.description),
      coverUrl: pick('coverUrl', base.coverUrl, incoming.coverUrl),
      seriesName: pick('seriesName', base.seriesName, incoming.seriesName),
      seriesVolume:
          can('seriesVolume') &&
              base.seriesVolume == null &&
              incoming.seriesVolume != null
          ? incoming.seriesVolume
          : base.seriesVolume,
    );
  }
}
