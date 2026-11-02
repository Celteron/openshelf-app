import 'package:openreads/domain/models/enums.dart';

/// Canonical field names tracked in a book's `edited_fields` set. These match
/// the `BookMetadata` property names and are used by the deterministic merge
/// (Constitution Article III.2).
const Set<String> allMetadataFields = {
  'isbn13',
  'isbn10',
  'title',
  'subtitle',
  'authors',
  'publisher',
  'publishedYear',
  'pageCount',
  'format',
  'language',
  'description',
  'coverUrl',
  'seriesName',
  'seriesVolume',
};

/// A transport object carrying metadata resolved from a single source.
class BookMetadata {
  final String? isbn13;
  final String? isbn10;
  final String? title;
  final String? subtitle;
  final List<String> authors;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final BookFormat? format;
  final String? language;
  final String? description;
  final String? coverUrl;
  final String? seriesName;
  final double? seriesVolume;

  const BookMetadata({
    this.isbn13,
    this.isbn10,
    this.title,
    this.subtitle,
    this.authors = const [],
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.format,
    this.language,
    this.description,
    this.coverUrl,
    this.seriesName,
    this.seriesVolume,
  });

  /// The same metadata with a different cover URL.
  BookMetadata withCoverUrl(String? url) => BookMetadata(
    isbn13: isbn13,
    isbn10: isbn10,
    title: title,
    subtitle: subtitle,
    authors: authors,
    publisher: publisher,
    publishedYear: publishedYear,
    pageCount: pageCount,
    format: format,
    language: language,
    description: description,
    coverUrl: url,
    seriesName: seriesName,
    seriesVolume: seriesVolume,
  );

  /// Whether every field is empty (the source yielded nothing useful).
  bool get isEmpty =>
      isbn13 == null &&
      isbn10 == null &&
      (title == null || title!.isEmpty) &&
      subtitle == null &&
      authors.isEmpty &&
      publisher == null &&
      publishedYear == null &&
      pageCount == null &&
      format == null &&
      language == null &&
      description == null &&
      coverUrl == null &&
      seriesName == null &&
      seriesVolume == null;
}

/// A strategy that resolves metadata for one remote source.
abstract class MetadataSourceStrategy {
  MetadataSource get id;

  Future<BookMetadata?> lookupByIsbn(String isbn13);
}

/// The result of the metadata aggregation (deterministic merge of all sources).
class AggregatedMetadata {
  final BookMetadata metadata;
  final MetadataSource? primarySource;

  const AggregatedMetadata({required this.metadata, this.primarySource});
}
