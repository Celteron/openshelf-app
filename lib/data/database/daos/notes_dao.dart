import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class NotesDao {
  final AppDatabase db;
  NotesDao(this.db);

  SimpleSelectStatement<$BookNotesTable, BookNote> _forBook(int bookId) =>
      db.select(db.bookNotes)
        ..where((t) => t.bookId.equals(bookId))
        ..orderBy([
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.desc(t.id),
        ]);

  Stream<List<BookNote>> watch(int bookId) => _forBook(bookId).watch();

  Future<List<BookNote>> get(int bookId) => _forBook(bookId).get();

  Future<int> insert(BookNotesCompanion note) =>
      db.into(db.bookNotes).insert(note);

  Future<void> update(int id, BookNotesCompanion note) =>
      (db.update(db.bookNotes)..where((t) => t.id.equals(id))).write(note);

  Future<void> delete(int id) =>
      (db.delete(db.bookNotes)..where((t) => t.id.equals(id))).go();
}
