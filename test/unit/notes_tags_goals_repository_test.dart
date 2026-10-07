import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/goals_dao.dart';
import 'package:openreads/data/database/daos/notes_dao.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/repositories/goal_repository_impl.dart';
import 'package:openreads/data/repositories/notes_repository_impl.dart';
import 'package:openreads/data/repositories/tag_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> addBook(String title) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          title: title,
          authors: const ['A'],
          editedFields: const [],
        ),
      );

  group('notes', () {
    test('CRUD for notes and quotes, newest first', () async {
      final repo = NotesRepositoryImpl(NotesDao(db));
      final book = await addBook('B');

      final first = await repo.addNote(
        book,
        kind: NoteKind.note,
        content: '  Erste Notiz ',
      );
      await repo.addNote(
        book,
        kind: NoteKind.quote,
        content: 'Zitat',
        pageNumber: 42,
      );

      var notes = await repo.getNotes(book);
      expect(notes.map((n) => n.content), ['Zitat', 'Erste Notiz']);
      expect(notes.first.kind, NoteKind.quote);
      expect(notes.first.pageNumber, 42);

      await repo.updateNote(
        first,
        kind: NoteKind.quote,
        content: 'Neu',
        pageNumber: 7,
      );
      notes = await repo.getNotes(book);
      final updated = notes.firstWhere((n) => n.id == first);
      expect(updated.content, 'Neu');
      expect(updated.kind, NoteKind.quote);
      expect(updated.pageNumber, 7);

      await repo.deleteNote(first);
      expect(await repo.getNotes(book), hasLength(1));
    });

    test('notes are removed with their book', () async {
      final repo = NotesRepositoryImpl(NotesDao(db));
      final book = await addBook('B');
      await repo.addNote(book, kind: NoteKind.note, content: 'x');
      await (db.delete(db.books)..where((t) => t.id.equals(book))).go();
      expect(await db.select(db.bookNotes).get(), isEmpty);
    });
  });

  group('tags', () {
    late TagRepositoryImpl repo;
    setUp(() => repo = TagRepositoryImpl(TagsDao(db)));

    test('createTag is case-insensitive and rejects blank names', () async {
      final a = await repo.createTag('Krimi');
      final b = await repo.createTag(' krimi ');
      expect(b, a);
      expect(() => repo.createTag('   '), throwsArgumentError);
    });

    test('case-insensitive matching also works for non-ASCII names', () async {
      // SQLite's lower() only folds ASCII; matching happens in Dart.
      final a = await repo.createTag('Übernatürliches');
      expect(await repo.createTag('übernatürliches'), a);
      expect(await repo.createTag('ÜBERNATÜRLICHES'), a);
      expect(await db.select(db.tags).get(), hasLength(1));
    });

    test('rename conflicts are rejected, self-rename allowed', () async {
      final a = await repo.createTag('A');
      await repo.createTag('B');
      await expectLater(
        repo.renameTag(a, 'b'),
        throwsA(isA<TagNameTakenException>()),
      );
      await repo.renameTag(a, 'a');
      expect((await repo.watchTags().first).map((t) => t.tag.name), ['a', 'B']);
    });

    test('watchTags reports book counts', () async {
      final b1 = await addBook('1');
      final b2 = await addBook('2');
      final t = await repo.createTag('Klassiker');
      await repo.createTag('Leer');
      await repo.setBookTags(b1, {t});
      await repo.setBookTags(b2, {t});

      final tags = await repo.watchTags().first;
      expect(
        {for (final x in tags) x.tag.name: x.bookCount},
        {'Klassiker': 2, 'Leer': 0},
      );
    });

    test('setBookTags replaces the assignment', () async {
      final b = await addBook('1');
      final t1 = await repo.createTag('A');
      final t2 = await repo.createTag('B');
      await repo.setBookTags(b, {t1, t2});
      expect((await repo.watchTagsForBook(b).first).map((t) => t.name), [
        'A',
        'B',
      ]);
      await repo.setBookTags(b, {t2});
      expect((await repo.watchTagsForBook(b).first).map((t) => t.name), ['B']);
      await repo.setBookTags(b, {});
      expect(await repo.watchTagsForBook(b).first, isEmpty);
    });

    test('AND filter returns only books carrying every selected tag', () async {
      final b1 = await addBook('1');
      final b2 = await addBook('2');
      final b3 = await addBook('3');
      final t1 = await repo.createTag('A');
      final t2 = await repo.createTag('B');
      await repo.setBookTags(b1, {t1, t2});
      await repo.setBookTags(b2, {t1});
      await repo.setBookTags(b3, {t2});

      expect(await repo.watchBookIdsWithAllTags({t1}).first, {b1, b2});
      expect(await repo.watchBookIdsWithAllTags({t1, t2}).first, {b1});
      expect(await repo.watchBookIdsWithAllTags({}).first, isEmpty);
    });

    test('deleting a tag keeps the books', () async {
      final b = await addBook('1');
      final t = await repo.createTag('A');
      await repo.setBookTags(b, {t});
      await repo.deleteTag(t);
      expect(await db.select(db.books).get(), hasLength(1));
      expect(await db.select(db.bookTags).get(), isEmpty);
    });
  });

  group('goals', () {
    test('set, update and clear a yearly goal', () async {
      final repo = GoalRepositoryImpl(GoalsDao(db));
      expect(await repo.watchGoal(2026).first, isNull);
      await repo.setGoal(2026, 20);
      expect((await repo.watchGoal(2026).first)!.targetBooks, 20);
      await repo.setGoal(2026, 25);
      expect((await repo.watchGoal(2026).first)!.targetBooks, 25);
      expect(await db.select(db.readingGoals).get(), hasLength(1));
      await repo.clearGoal(2026);
      expect(await repo.watchGoal(2026).first, isNull);
      expect(() => repo.setGoal(2026, 0), throwsArgumentError);
    });

    test('the page goal is optional, replaceable and validated', () async {
      final repo = GoalRepositoryImpl(GoalsDao(db));

      await repo.setGoal(2026, 20);
      expect((await repo.watchGoal(2026).first)!.targetPages, isNull);

      await repo.setGoal(2026, 20, targetPages: 6000);
      expect((await repo.watchGoal(2026).first)!.targetPages, 6000);

      await repo.setGoal(2026, 20); // dropping the page goal again
      expect((await repo.watchGoal(2026).first)!.targetPages, isNull);

      expect(() => repo.setGoal(2026, 20, targetPages: 0), throwsArgumentError);
    });
  });
}
