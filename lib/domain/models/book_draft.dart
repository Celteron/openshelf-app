import 'package:openreads/domain/models/enums.dart';

/// A plain domain model for creating/updating a book, free of Drift types so
/// the presentation layer never imports `package:drift` (Constitution II).
class BookDraft {
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn13;
  final String? isbn10;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final BookFormat? format;
  final String? language;
  final String? description;
  final String? coverUrl;

  /// A manually chosen or cached cover file on this device.
  final String? coverLocalPath;
  final String? olid;
  final double? seriesVolume;
  final BookStatus status;
  final double rating;
  final MetadataSource? metadataSource;
  final int? locationId;
  final int? seriesId;

  /// Free-text genre, purchase price (euro cents) and received date.
  final String? genre;
  final int? priceCents;
  final DateTime? receivedAt;

  /// Reading time entered without a dated session, in seconds.
  final int? readingSeconds;

  /// Canonical field names the user edited by hand. Used to flip the DNB
  /// verification badge to "bearbeitet" (spec §6.3).
  final Set<String> editedFields;

  const BookDraft({
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn13,
    this.isbn10,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.format,
    this.language,
    this.description,
    this.coverUrl,
    this.coverLocalPath,
    this.olid,
    this.seriesVolume,
    this.status = BookStatus.unread,
    this.rating = 0.0,
    this.metadataSource,
    this.locationId,
    this.seriesId,
    this.genre,
    this.priceCents,
    this.receivedAt,
    this.readingSeconds,
    this.editedFields = const {},
  });
}
