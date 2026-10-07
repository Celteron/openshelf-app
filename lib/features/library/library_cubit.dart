import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
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
  final List<Book> books;
  final String query;
  final BookStatus? statusFilter;
  final int? locationId;

  /// Selected tag filters; a book must carry *all* of them (FR-P2-07).
  final Set<int> tagIds;

  /// Only books flagged as favourite.
  final bool favoritesOnly;

  final LibrarySort sort;

  const LibraryLoaded({
    required this.books,
    this.query = '',
    this.statusFilter,
    this.locationId,
    this.tagIds = const {},
    this.favoritesOnly = false,
    this.sort = const LibrarySort(),
  });

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      statusFilter != null ||
      tagIds.isNotEmpty ||
      favoritesOnly;
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
  StreamSubscription<List<Book>>? _subscription;

  String _query = '';
  BookStatus? _status;
  int? _locationId;
  Set<int> _tagIds = const {};
  bool _favoritesOnly = false;
  LibrarySort _sort = const LibrarySort();

  LibraryCubit(this._repository, {TagRepository? tagRepository})
    : _tags = tagRepository,
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

  void _subscribe() {
    _subscription?.cancel();
    final books = _repository.watchBooks(
      query: _query,
      status: _status,
      locationId: _locationId,
    );
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

    final favoritesOnly = _favoritesOnly;
    final sort = _sort;
    _subscription = filtered
        .map(
          (books) => sort.apply(
            favoritesOnly ? books.where((b) => b.isFavorite) : books,
          ),
        )
        .listen(
          (books) => emit(
            LibraryLoaded(
              books: books,
              query: _query,
              statusFilter: _status,
              locationId: _locationId,
              tagIds: _tagIds,
              favoritesOnly: favoritesOnly,
              sort: sort,
            ),
          ),
          onError: (_) => emit(const LibraryError('Failed to load books')),
        );
  }

  Future<void> addBook(BookDraft draft) => _repository.addBook(draft);

  Future<void> updateBook(int id, BookDraft draft) =>
      _repository.updateBookDraft(id, draft);

  Future<void> setRating(int bookId, double rating) =>
      _repository.updateRating(bookId, rating);

  Future<void> setFavorite(int bookId, bool isFavorite) =>
      _repository.updateFavorite(bookId, isFavorite);

  Future<void> setReview(int bookId, String? review) =>
      _repository.updateReview(bookId, review);

  Future<void> deleteBook(int bookId) => _repository.deleteBook(bookId);

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
