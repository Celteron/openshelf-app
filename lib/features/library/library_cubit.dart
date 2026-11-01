import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/models/shelf_partition.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:rxdart/rxdart.dart';

sealed class LibraryState {
  const LibraryState();
}

class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoaded extends LibraryState {
  /// The entries: single books and slipcases (ADR-0003).
  final List<Book> books;

  /// The volumes of every slipcase in [books], by slipcase id.
  final Map<int, List<Book>> volumes;
  final String query;
  final BookStatus? statusFilter;
  final int? locationId;

  /// Selected tag filters; a book must carry *all* of them (FR-P2-07).
  final Set<int> tagIds;

  /// Only books flagged as favourite.
  final bool favoritesOnly;

  final LibrarySort sort;

  /// Only books finished in this year (Openreads year filter chip).
  final int? yearFilter;

  /// Years that have finished books, newest first; feeds the year filter.
  final List<int> availableYears;

  const LibraryLoaded({
    required this.books,
    this.volumes = const {},
    this.query = '',
    this.statusFilter,
    this.locationId,
    this.tagIds = const {},
    this.favoritesOnly = false,
    this.sort = const LibrarySort(),
    this.yearFilter,
    this.availableYears = const [],
  });

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      statusFilter != null ||
      tagIds.isNotEmpty ||
      favoritesOnly ||
      yearFilter != null;
}

class LibraryError extends LibraryState {
  final String message;
  const LibraryError(this.message);
}

/// Loads, filters, and searches books for the library list (spec §6.1).
///
/// The visible list is the reactive intersection of the text query, the status
/// chip, the tag chips and the location (FR-P2-07). Tag filtering is optional:
/// without a [TagRepository] the tag filter is simply unavailable.
class LibraryCubit extends Cubit<LibraryState> {
  final BookRepository _repository;
  final TagRepository? _tags;
  final ReadingRepository? _reading;
  StreamSubscription<Object?>? _subscription;

  String _query = '';
  BookStatus? _status;
  int? _locationId;
  Set<int> _tagIds = const {};
  bool _favoritesOnly = false;
  LibrarySort _sort = const LibrarySort();
  int? _year;

  LibraryCubit(
    this._repository, {
    TagRepository? tagRepository,
    ReadingRepository? readingRepository,
  }) : _tags = tagRepository,
       _reading = readingRepository,
       super(const LibraryInitial());

  void load({int? locationId}) {
    _locationId = locationId;
    emit(const LibraryLoading());
    _subscribe();
  }

  Future<void> search(String query) async {
    _query = query.trim();
    _subscribe();
  }

  void filterByStatus(BookStatus? status) {
    _status = status;
    _subscribe();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _subscribe();
  }

  /// Selecting the active sort field flips its direction.
  void selectSort(LibrarySortField field) {
    _sort = _sort.select(field);
    _subscribe();
  }

  /// Filters to books finished in [year]; `null` shows all.
  void filterByYear(int? year) {
    _year = year;
    _subscribe();
  }

  void toggleTag(int tagId) {
    final next = {..._tagIds};
    if (!next.remove(tagId)) next.add(tagId);
    _tagIds = next;
    _subscribe();
  }

  /// Drops selected tags that no longer exist (e.g. after deleting a tag),
  /// so a stale filter cannot hide the whole library.
  void retainTags(Set<int> existing) {
    final next = _tagIds.intersection(existing);
    if (next.length == _tagIds.length) return;
    _tagIds = next;
    _subscribe();
  }

  /// Drops every tag filter at once.
  void clearTags() {
    if (_tagIds.isEmpty) return;
    _tagIds = const {};
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    // The status is filtered in Dart: a slipcase's status comes from its
    // volumes, which the whole library is needed for.
    final books = _repository.watchBooks(
      query: _query,
      locationId: _locationId,
    );
    final all = _repository.watchBooks();
    final tags = _tags;
    final filtered = (_tagIds.isEmpty || tags == null)
        ? books
        : Rx.combineLatest2<List<Book>, Set<int>, List<Book>>(
            books,
            tags.watchBookIdsWithAllTags(_tagIds),
            (books, ids) => [
              for (final book in books)
                if (ids.contains(book.id)) book,
            ],
          );

    final status = _status;
    final favoritesOnly = _favoritesOnly;
    final sort = _sort;
    final year = _year;
    final sessions =
        _reading?.watchAllSessions().map(readingSpans) ??
        Stream.value(const <int, ReadingSpan>{});

    _subscription =
        Rx.combineLatest3<
              List<Book>,
              List<Book>,
              Map<int, ReadingSpan>,
              (List<Book>, List<Book>, Map<int, ReadingSpan>)
            >(
              filtered,
              all,
              sessions,
              (books, all, spans) => (books, all, spans),
            )
            .listen(
              (data) {
                final (books, all, spans) = data;
                // Both streams fire on a write, `all` possibly second: the
                // filtered rows are newer, so they win over `all`'s copies.
                final shelf = ShelfPartition.of(
                  {
                    for (final b in all) b.id: b,
                    for (final b in books) b.id: b,
                  }.values,
                );
                final years = {
                  for (final b in books)
                    if (b.status == BookStatus.read && !shelf.isSlipcase(b.id))
                      (b.finishedAt ?? b.createdAt).year,
                }.toList()..sort((a, b) => b.compareTo(a));
                Iterable<Book> visible = books;
                if (favoritesOnly) visible = visible.where((b) => b.isFavorite);
                if (year != null) {
                  visible = visible.where(
                    (b) => GoalProgress.countsForYear(b, year),
                  );
                }
                final entries = shelf.entries(
                  sort.apply(visible, spans: spans),
                  status: status,
                );
                emit(
                  LibraryLoaded(
                    books: entries,
                    volumes: {
                      for (final e in entries)
                        if (shelf.isSlipcase(e.id)) e.id: shelf.volumesOf(e.id),
                    },
                    query: _query,
                    statusFilter: status,
                    locationId: _locationId,
                    tagIds: _tagIds,
                    favoritesOnly: favoritesOnly,
                    sort: sort,
                    yearFilter: year,
                    availableYears: years,
                  ),
                );
              },
              onError: (_) => emit(const LibraryError('Failed to load books')),
            );
  }

  /// Adds a book and returns its id.
  Future<int> addBook(BookDraft draft) => _repository.addBook(draft);

  Future<void> updateBook(int id, BookDraft draft) =>
      _repository.updateBookDraft(id, draft);

  Future<void> setRating(int bookId, double rating) =>
      _repository.updateRating(bookId, rating);

  Future<void> setFavorite(int bookId, bool isFavorite) =>
      _repository.updateFavorite(bookId, isFavorite);

  Future<void> setReview(int bookId, String? review) =>
      _repository.updateReview(bookId, review);

  /// Moves a book to the trash (it can be restored from there).
  Future<void> deleteBook(int bookId) => _repository.deleteBook(bookId);

  Future<void> deleteBooks(List<int> bookIds) =>
      _repository.deleteBooks(bookIds);

  Future<void> restoreBook(int bookId) => _repository.restoreBook(bookId);

  Future<List<int>> splitIntoVolumes(int bookId, List<VolumeDraft> volumes) =>
      _repository.splitIntoVolumes(bookId, volumes);

  Future<void> bulkSetFormat(List<int> bookIds, BookFormat format) =>
      _repository.bulkSetFormat(bookIds, format);

  Future<void> bulkSetAuthors(List<int> bookIds, List<String> authors) =>
      _repository.bulkSetAuthors(bookIds, authors);

  Future<void> setStatus(int bookId, BookStatus status) =>
      _repository.updateStatus(bookId, status);

  /// Wishlist → owned: the book becomes `unread` (Phase 2, US-E).
  Future<void> moveToLibrary(int bookId) =>
      _repository.updateStatus(bookId, BookStatus.unread);

  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId) =>
      _repository.bulkAssignLocation(bookIds, locationId);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
