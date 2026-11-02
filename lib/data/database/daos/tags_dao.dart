import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/tag_with_count.dart';

class TagsDao {
  final AppDatabase db;
  TagsDao(this.db);

  Stream<List<TagWithCount>> watchWithCounts() {
    final count = db.bookTags.bookId.count();
    final query =
        db.select(db.tags).join([
            leftOuterJoin(db.bookTags, db.bookTags.tagId.equalsExp(db.tags.id)),
          ])
          ..addColumns([count])
          ..groupBy([db.tags.id])
          ..orderBy([OrderingTerm.asc(db.tags.name.lower())]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          TagWithCount(row.readTable(db.tags), row.read(count) ?? 0),
      ],
    );
  }

  Stream<List<Tag>> watchForBook(int bookId) {
    final query =
        db.select(db.tags).join([
            innerJoin(db.bookTags, db.bookTags.tagId.equalsExp(db.tags.id)),
          ])
          ..where(db.bookTags.bookId.equals(bookId))
          ..orderBy([OrderingTerm.asc(db.tags.name.lower())]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(db.tags)],
    );
  }

  Stream<Map<int, Set<int>>> watchTagsByBook() =>
      db.select(db.bookTags).watch().map((rows) {
        final result = <int, Set<int>>{};
        for (final row in rows) {
          (result[row.bookId] ??= {}).add(row.tagId);
        }
        return result;
      });

  Stream<Set<int>> watchBookIdsWithAllTags(Set<int> tagIds) {
    final distinctTags = db.bookTags.tagId.count(distinct: true);
    final query = db.selectOnly(db.bookTags)
      ..addColumns([db.bookTags.bookId])
      ..where(db.bookTags.tagId.isIn(tagIds))
      ..groupBy([
        db.bookTags.bookId,
      ], having: distinctTags.equals(tagIds.length));
    return query.watch().map(
      (rows) => {for (final row in rows) row.read(db.bookTags.bookId)!},
    );
  }

  /// Case-insensitive lookup done in Dart: SQLite's `lower()` only folds ASCII,
  /// so comparing in SQL would miss names such as `Übung`.
  Future<Tag?> findByName(String name) async {
    final wanted = name.toLowerCase();
    final tags = await db.select(db.tags).get();
    for (final tag in tags) {
      if (tag.name.toLowerCase() == wanted) return tag;
    }
    return null;
  }

  Future<int> insert(String name) =>
      db.into(db.tags).insert(TagsCompanion.insert(name: name));

  Future<void> rename(int id, String name) => (db.update(
    db.tags,
  )..where((t) => t.id.equals(id))).write(TagsCompanion(name: Value(name)));

  Future<void> delete(int id) =>
      (db.delete(db.tags)..where((t) => t.id.equals(id))).go();

  Future<void> setBookTags(int bookId, Set<int> tagIds) {
    return db.transaction(() async {
      await (db.delete(
        db.bookTags,
      )..where((t) => t.bookId.equals(bookId))).go();
      await db.batch((batch) {
        batch.insertAll(db.bookTags, [
          for (final tagId in tagIds)
            BookTagsCompanion.insert(bookId: bookId, tagId: tagId),
        ]);
      });
    });
  }
}
