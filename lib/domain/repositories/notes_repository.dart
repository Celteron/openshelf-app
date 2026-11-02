import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// Notes and quotes attached to a book (Phase 2).
abstract class NotesRepository {
  /// Newest first.
  Stream<List<BookNote>> watchNotes(int bookId);

  Future<List<BookNote>> getNotes(int bookId);

  Future<int> addNote(
    int bookId, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  });

  Future<void> updateNote(
    int id, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  });

  Future<void> deleteNote(int id);
}
