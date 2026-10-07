import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';

class TagRepositoryImpl implements TagRepository {
  final TagsDao _dao;

  TagRepositoryImpl(this._dao);

  @override
  Stream<List<TagWithCount>> watchTags() => _dao.watchWithCounts();

  @override
  Stream<List<Tag>> watchTagsForBook(int bookId) => _dao.watchForBook(bookId);

  @override
  Stream<Set<int>> watchBookIdsWithAllTags(Set<int> tagIds) => tagIds.isEmpty
      ? Stream.value(const <int>{})
      : _dao.watchBookIdsWithAllTags(tagIds);

  @override
  Future<int> createTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Tag name must not be blank');
    final existing = await _dao.findByName(trimmed);
    if (existing != null) return existing.id;
    return _dao.insert(trimmed);
  }

  @override
  Future<void> renameTag(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Tag name must not be blank');
    final existing = await _dao.findByName(trimmed);
    if (existing != null && existing.id != id) {
      throw TagNameTakenException(trimmed);
    }
    await _dao.rename(id, trimmed);
  }

  @override
  Future<void> deleteTag(int id) => _dao.delete(id);

  @override
  Future<void> setBookTags(int bookId, Set<int> tagIds) =>
      _dao.setBookTags(bookId, tagIds);
}
