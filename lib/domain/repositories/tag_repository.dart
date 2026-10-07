import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/tag_with_count.dart';

/// Custom tags and their assignment to books (Phase 2).
abstract class TagRepository {
  Stream<List<TagWithCount>> watchTags();

  Stream<List<Tag>> watchTagsForBook(int bookId);

  /// Ids of the books that carry *all* of [tagIds] (AND semantics).
  Stream<Set<int>> watchBookIdsWithAllTags(Set<int> tagIds);

  /// Creates a tag, or returns the id of the existing tag whose name matches
  /// case-insensitively. Throws [ArgumentError] for a blank name.
  Future<int> createTag(String name);

  /// Throws [TagNameTakenException] when another tag already has [name].
  Future<void> renameTag(int id, String name);

  /// Deletes the tag and its assignments only; books are untouched.
  Future<void> deleteTag(int id);

  /// Replaces the tags of a book with exactly [tagIds] in one transaction.
  Future<void> setBookTags(int bookId, Set<int> tagIds);
}

class TagNameTakenException implements Exception {
  final String name;
  TagNameTakenException(this.name);

  @override
  String toString() => 'TagNameTakenException: $name';
}
