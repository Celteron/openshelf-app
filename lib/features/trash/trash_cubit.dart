import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

sealed class TrashState {
  const TrashState();
}

class TrashLoading extends TrashState {
  const TrashLoading();
}

class TrashLoaded extends TrashState {
  /// Most recently deleted first.
  final List<Book> books;
  const TrashLoaded(this.books);
}

class TrashError extends TrashState {
  const TrashError();
}

/// The trash (Openreads "deleted books"): restore a book or delete it for
/// good. Permanent deletion also removes the book's cover file.
class TrashCubit extends Cubit<TrashState> {
  final BookRepository _repository;
  final CoverCacheService? _covers;
  StreamSubscription<List<Book>>? _subscription;

  TrashCubit(this._repository, {CoverCacheService? coverCache})
    : _covers = coverCache,
      super(const TrashLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _repository.watchTrashedBooks().listen(
      (books) => emit(TrashLoaded(books)),
      onError: (_) => emit(const TrashError()),
    );
  }

  Future<void> restore(int bookId) => _repository.restoreBook(bookId);

  Future<void> deleteForever(Book book) async {
    await _repository.purgeBook(book.id);
    await _covers?.deleteFile(book.coverLocalPath);
  }

  /// Permanently deletes everything in the trash; returns how many books.
  Future<int> emptyTrash() async {
    final current = state;
    final books = current is TrashLoaded ? current.books : const <Book>[];
    final count = await _repository.emptyTrash();
    for (final book in books) {
      await _covers?.deleteFile(book.coverLocalPath);
    }
    return count;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
