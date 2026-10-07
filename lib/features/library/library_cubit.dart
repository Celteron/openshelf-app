import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

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

  const LibraryLoaded({
    required this.books,
    this.query = '',
    this.statusFilter,
    this.locationId,
  });

  bool get hasActiveFilters => query.isNotEmpty || statusFilter != null;
}

class LibraryError extends LibraryState {
  final String message;
  const LibraryError(this.message);
}

/// Loads, filters, and searches books for the library list (spec §6.1).
class LibraryCubit extends Cubit<LibraryState> {
  final BookRepository _repository;
  StreamSubscription<List<Book>>? _subscription;

  String _query = '';
  BookStatus? _status;
  int? _locationId;

  LibraryCubit(this._repository) : super(const LibraryInitial());

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

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository
        .watchBooks(query: _query, status: _status, locationId: _locationId)
        .listen(
          (books) => emit(
            LibraryLoaded(
              books: books,
              query: _query,
              statusFilter: _status,
              locationId: _locationId,
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

  Future<void> setStatus(int bookId, BookStatus status) =>
      _repository.updateStatus(bookId, status);

  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId) =>
      _repository.bulkAssignLocation(bookIds, locationId);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
