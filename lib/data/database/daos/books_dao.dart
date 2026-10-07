import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

class BooksDao {
  final AppDatabase db;
  BooksDao(this.db);

  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) {
    final select = db.select(db.books);
    if (status != null) {
      select.where((t) => t.status.equalsValue(status));
    }
    if (locationId != null) {
      select.where((t) => t.locationId.equals(locationId));
    }
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      select.where(
        (t) =>
            t.title.like('%$q%') |
            t.subtitle.like('%$q%') |
            t.authors.like('%$q%') |
            t.isbn13.like('%$q%') |
            t.isbn10.like('%$q%'),
      );
    }
    return select.watch();
  }

  Future<List<Book>> search(String query) {
    final q = query.trim();
    final select = db.select(db.books)
      ..where(
        (t) =>
            t.title.like('%$q%') |
            t.subtitle.like('%$q%') |
            t.authors.like('%$q%') |
            t.isbn13.like('%$q%') |
            t.isbn10.like('%$q%'),
      );
    return select.get();
  }

  Future<Book?> getById(int id) =>
      (db.select(db.books)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Book>> getAll() => db.select(db.books).get();

  Future<int> insert(BooksCompanion book) => db.into(db.books).insert(book);

  Future<int> insertAll(List<BooksCompanion> books) async {
    await db.transaction(() async {
      await db.batch((batch) {
        batch.insertAll(db.books, books);
      });
    });
    return books.length;
  }

  Future<int> update(int id, BooksCompanion book) =>
      (db.update(db.books)..where((t) => t.id.equals(id))).write(book);

  Future<void> bulkAssignLocation(List<int> ids, int? locationId) {
    return db.transaction(() async {
      await (db.update(db.books)..where((t) => t.id.isIn(ids))).write(
        BooksCompanion(locationId: Value(locationId)),
      );
    });
  }

  Future<bool> isbnExists(String isbn13) async {
    final matches = await (db.select(
      db.books,
    )..where((t) => t.isbn13.equals(isbn13))).get();
    return matches.isNotEmpty;
  }
}
