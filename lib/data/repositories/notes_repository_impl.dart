import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/notes_dao.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesDao _dao;

  NotesRepositoryImpl(this._dao);

  @override
  Stream<List<BookNote>> watchNotes(int bookId) => _dao.watch(bookId);

  @override
  Future<List<BookNote>> getNotes(int bookId) => _dao.get(bookId);

  @override
  Future<int> addNote(
    int bookId, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  }) => _dao.insert(
    BookNotesCompanion.insert(
      bookId: bookId,
      kind: kind,
      content: content.trim(),
      pageNumber: Value(pageNumber),
    ),
  );

  @override
  Future<void> updateNote(
    int id, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  }) => _dao.update(
    id,
    BookNotesCompanion(
      kind: Value(kind),
      content: Value(content.trim()),
      pageNumber: Value(pageNumber),
      updatedAt: Value(DateTime.now()),
    ),
  );

  @override
  Future<void> deleteNote(int id) => _dao.delete(id);
}
