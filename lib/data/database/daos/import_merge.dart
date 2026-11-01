import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// What to do when an imported book matches one that already exists.
///
/// The existing book always wins: an import only *fills gaps* (empty fields,
/// an unrated book, an unread status, missing finish date) and never
/// overwrites anything the user has entered or edited. This keeps a re-import
/// of an old export safe.
///
/// Returns a companion carrying only the fields to write, or `null` when the
/// existing book already has everything the import could contribute.
BooksCompanion? mergeMissingFields(Book existing, BooksCompanion incoming) {
  T? read<T>(Value<T?> v) => v.present ? v.value : null;
  bool blank(String? s) => s == null || s.trim().isEmpty;

  String? fillText(String? current, Value<String?> value) {
    final next = read(value);
    return blank(current) && !blank(next) ? next : null;
  }

  T? fill<T>(T? current, Value<T?> value) {
    final next = read(value);
    return current == null && next != null ? next : null;
  }

  final subtitle = fillText(existing.subtitle, incoming.subtitle);
  final publisher = fillText(existing.publisher, incoming.publisher);
  final language = fillText(existing.language, incoming.language);
  final description = fillText(existing.description, incoming.description);
  final coverUrl = fillText(existing.coverUrl, incoming.coverUrl);
  final review = fillText(existing.review, incoming.review);
  final isbn13 = fill(existing.isbn13, incoming.isbn13);
  final isbn10 = fill(existing.isbn10, incoming.isbn10);
  final olid = fillText(existing.olid, incoming.olid);
  final genre = fillText(existing.genre, incoming.genre);
  final priceCents = fill(existing.priceCents, incoming.priceCents);
  final receivedAt = fill(existing.receivedAt, incoming.receivedAt);
  final receivedAs = fill(existing.receivedAs, incoming.receivedAs);
  final readingSeconds = fill(existing.readingSeconds, incoming.readingSeconds);
  final coverLocalPath = existing.coverLocalPath == null
      ? read(incoming.coverLocalPath)
      : null;
  final locationId = fill(existing.locationId, incoming.locationId);
  final seriesId = fill(existing.seriesId, incoming.seriesId);
  final seriesVolume = fill(existing.seriesVolume, incoming.seriesVolume);
  final publishedYear = fill(existing.publishedYear, incoming.publishedYear);
  final pageCount = fill(existing.pageCount, incoming.pageCount);
  final format = fill<BookFormat>(existing.format, incoming.format);

  final authors = existing.authors.isEmpty && incoming.authors.present
      ? (incoming.authors.value.isEmpty ? null : incoming.authors.value)
      : null;
  final rating =
      existing.rating == 0 &&
          incoming.rating.present &&
          incoming.rating.value > 0
      ? incoming.rating.value
      : null;
  final favorite =
      !existing.isFavorite &&
          incoming.isFavorite.present &&
          incoming.isFavorite.value
      ? true
      : null;

  // Reading state: an unread book adopts the imported state; a finished book
  // may gain the finish date / page it was missing.
  final inStatus = incoming.status.present
      ? incoming.status.value
      : BookStatus.unread;
  final inPage = incoming.currentPage.present ? incoming.currentPage.value : 0;
  final inFinished = read(incoming.finishedAt);
  BookStatus? status;
  int? currentPage;
  DateTime? finishedAt;
  if (existing.status == BookStatus.unread && inStatus != BookStatus.unread) {
    status = inStatus;
    if (existing.currentPage == 0 && inPage > 0) currentPage = inPage;
    finishedAt = fill(existing.finishedAt, Value(inFinished));
  } else if (existing.status == BookStatus.read &&
      inStatus == BookStatus.read) {
    if (existing.currentPage == 0 && inPage > 0) currentPage = inPage;
    finishedAt = fill(existing.finishedAt, Value(inFinished));
  }

  final changed = [
    subtitle,
    publisher,
    language,
    description,
    coverUrl,
    review,
    isbn13,
    isbn10,
    olid,
    genre,
    priceCents,
    receivedAt,
    receivedAs,
    readingSeconds,
    coverLocalPath,
    locationId,
    seriesId,
    seriesVolume,
    publishedYear,
    pageCount,
    format,
    authors,
    rating,
    favorite,
    status,
    currentPage,
    finishedAt,
  ].any((v) => v != null);
  if (!changed) return null;

  return BooksCompanion(
    subtitle: subtitle == null ? const Value.absent() : Value(subtitle),
    publisher: publisher == null ? const Value.absent() : Value(publisher),
    language: language == null ? const Value.absent() : Value(language),
    description: description == null
        ? const Value.absent()
        : Value(description),
    coverUrl: coverUrl == null ? const Value.absent() : Value(coverUrl),
    review: review == null ? const Value.absent() : Value(review),
    isbn13: isbn13 == null ? const Value.absent() : Value(isbn13),
    isbn10: isbn10 == null ? const Value.absent() : Value(isbn10),
    olid: olid == null ? const Value.absent() : Value(olid),
    genre: genre == null ? const Value.absent() : Value(genre),
    priceCents: priceCents == null ? const Value.absent() : Value(priceCents),
    receivedAt: receivedAt == null ? const Value.absent() : Value(receivedAt),
    receivedAs: receivedAs == null ? const Value.absent() : Value(receivedAs),
    readingSeconds: readingSeconds == null
        ? const Value.absent()
        : Value(readingSeconds),
    coverLocalPath: coverLocalPath == null
        ? const Value.absent()
        : Value(coverLocalPath),
    locationId: locationId == null ? const Value.absent() : Value(locationId),
    seriesId: seriesId == null ? const Value.absent() : Value(seriesId),
    seriesVolume: seriesVolume == null
        ? const Value.absent()
        : Value(seriesVolume),
    publishedYear: publishedYear == null
        ? const Value.absent()
        : Value(publishedYear),
    pageCount: pageCount == null ? const Value.absent() : Value(pageCount),
    format: format == null ? const Value.absent() : Value(format),
    authors: authors == null ? const Value.absent() : Value(authors),
    rating: rating == null ? const Value.absent() : Value(rating),
    isFavorite: favorite == null ? const Value.absent() : Value(favorite),
    status: status == null ? const Value.absent() : Value(status),
    currentPage: currentPage == null
        ? const Value.absent()
        : Value(currentPage),
    finishedAt: finishedAt == null ? const Value.absent() : Value(finishedAt),
    updatedAt: Value(DateTime.now()),
  );
}

/// Finds the existing book an import row refers to, within one transaction.
///
/// Matching order: ISBN-13, then ISBN-10, then identical title + authors
/// (case-insensitive) — the last one only when at least one side has no
/// ISBN-13, because two different ISBN-13s are two different editions.
class BookMatchIndex {
  final Map<int, Book> _byId = {};
  final Map<String, int> _byIsbn13 = {};
  final Map<String, int> _byIsbn10 = {};
  final Map<String, List<int>> _byTitle = {};

  BookMatchIndex(Iterable<Book> books) {
    books.forEach(put);
  }

  /// Adds a book, or refreshes it after it was updated.
  void put(Book book) {
    _byId[book.id] = book;
    final isbn13 = book.isbn13;
    if (isbn13 != null) _byIsbn13[isbn13] = book.id;
    final isbn10 = book.isbn10;
    if (isbn10 != null) _byIsbn10.putIfAbsent(isbn10, () => book.id);
    final ids = _byTitle.putIfAbsent(
      titleKey(book.title, book.authors),
      () => [],
    );
    if (!ids.contains(book.id)) ids.add(book.id);
  }

  Book? find(BooksCompanion incoming) {
    final isbn13 = incoming.isbn13.present ? incoming.isbn13.value : null;
    final isbn10 = incoming.isbn10.present ? incoming.isbn10.value : null;

    if (isbn13 != null) {
      final id = _byIsbn13[isbn13];
      if (id != null) return _byId[id];
    }
    if (isbn10 != null) {
      final id = _byIsbn10[isbn10];
      if (id != null) return _byId[id];
    }
    final key = titleKey(
      incoming.title.value,
      incoming.authors.present ? incoming.authors.value : const [],
    );
    for (final id in _byTitle[key] ?? const <int>[]) {
      final candidate = _byId[id]!;
      if (isbn13 == null || candidate.isbn13 == null) return candidate;
    }
    return null;
  }

  static String titleKey(String title, List<String> authors) =>
      '${_norm(title)}|${authors.map(_norm).join('|')}';

  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
