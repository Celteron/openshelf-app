import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';

sealed class TagsState {
  const TagsState();
}

class TagsLoading extends TagsState {
  const TagsLoading();
}

class TagsLoaded extends TagsState {
  final List<TagWithCount> tags;
  const TagsLoaded(this.tags);
}

class TagsError extends TagsState {
  const TagsError();
}

/// Outcome of a tag rename/create, so the UI can show a precise message.
enum TagResult { ok, blank, nameTaken }

/// All tags with usage counts; backs tag management, the library filter chips
/// and the per-book tag picker (Phase 2, US-C).
class TagsCubit extends Cubit<TagsState> {
  final TagRepository _repository;
  StreamSubscription<List<TagWithCount>>? _subscription;

  TagsCubit(this._repository) : super(const TagsLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _repository.watchTags().listen(
      (tags) => emit(TagsLoaded(tags)),
      onError: (_) => emit(const TagsError()),
    );
  }

  /// Creates the tag (or finds the case-insensitive match) and returns its id,
  /// or `null` for a blank name.
  Future<int?> create(String name) async {
    if (name.trim().isEmpty) return null;
    return _repository.createTag(name);
  }

  Future<TagResult> rename(int id, String name) async {
    if (name.trim().isEmpty) return TagResult.blank;
    try {
      await _repository.renameTag(id, name);
      return TagResult.ok;
    } on TagNameTakenException {
      return TagResult.nameTaken;
    }
  }

  Future<void> delete(int id) => _repository.deleteTag(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// The tags of a single book and the actions to change them.
class BookTagsCubit extends Cubit<List<Tag>> {
  final int bookId;
  final TagRepository _repository;
  StreamSubscription<List<Tag>>? _subscription;

  BookTagsCubit(this.bookId, this._repository) : super(const []);

  void load() {
    _subscription?.cancel();
    _subscription = _repository.watchTagsForBook(bookId).listen(emit);
  }

  Set<int> get _ids => {for (final tag in state) tag.id};

  Future<void> toggle(int tagId) {
    final ids = _ids;
    if (!ids.remove(tagId)) ids.add(tagId);
    return _repository.setBookTags(bookId, ids);
  }

  /// Creates [name] if needed and assigns it to the book.
  Future<void> createAndAssign(String name) async {
    if (name.trim().isEmpty) return;
    final id = await _repository.createTag(name);
    await _repository.setBookTags(bookId, {..._ids, id});
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
