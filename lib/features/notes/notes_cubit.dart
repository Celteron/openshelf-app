import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';

sealed class NotesState {
  const NotesState();
}

class NotesLoading extends NotesState {
  const NotesLoading();
}

class NotesLoaded extends NotesState {
  /// Newest first.
  final List<BookNote> notes;
  const NotesLoaded(this.notes);

  List<BookNote> ofKind(NoteKind kind) =>
      notes.where((n) => n.kind == kind).toList();
}

class NotesError extends NotesState {
  const NotesError();
}

/// Notes and quotes of one book (Phase 2, US-B).
class NotesCubit extends Cubit<NotesState> {
  final int bookId;
  final NotesRepository _repository;
  StreamSubscription<List<BookNote>>? _subscription;

  NotesCubit(this.bookId, this._repository) : super(const NotesLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _repository
        .watchNotes(bookId)
        .listen(
          (notes) => emit(NotesLoaded(notes)),
          onError: (_) => emit(const NotesError()),
        );
  }

  /// Blank content is ignored so an accidental empty save creates no row.
  Future<void> add({
    required NoteKind kind,
    required String content,
    int? pageNumber,
  }) async {
    if (content.trim().isEmpty) return;
    await _repository.addNote(
      bookId,
      kind: kind,
      content: content,
      pageNumber: pageNumber,
    );
  }

  Future<void> update(
    int id, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  }) async {
    if (content.trim().isEmpty) return;
    await _repository.updateNote(
      id,
      kind: kind,
      content: content,
      pageNumber: pageNumber,
    );
  }

  Future<void> delete(int id) => _repository.deleteNote(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
