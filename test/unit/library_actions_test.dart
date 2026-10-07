import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/lending_dao.dart';
import 'package:openreads/data/database/daos/notes_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/lending_repository_impl.dart';
import 'package:openreads/data/repositories/notes_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/data/repositories/tag_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/features/library/library_cubit.dart';

/// Phase 2 library actions: delete, favourite, review, sorting and the
/// favourites filter, against a real in-memory database.
void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late LibraryCubit cubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Foreign keys are enabled in `beforeOpen`; force the database to open.
    await db.customSelect('select 1').get();
    books = BookRepositoryImpl(BooksDao(db));
    cubit = LibraryCubit(books);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<int> addBook(
    String title, {
    double rating = 0,
    bool favorite = false,
    DateTime? createdAt,
  }) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
      rating: Value(rating),
      isFavorite: Value(favorite),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  Future<List<String>> titles() async {
    final state = await cubit.stream.firstWhere((s) => s is LibraryLoaded);
    return (state as LibraryLoaded).books.map((b) => b.title).toList();
  }

  group('deleteBook', () {
    test('removes the book together with everything attached to it', () async {
      final id = await addBook('Weg damit');
      final other = await addBook('Bleibt');

      final tagId = await TagRepositoryImpl(TagsDao(db)).createTag('Krimi');
      await TagRepositoryImpl(TagsDao(db)).setBookTags(id, {tagId});
      await NotesRepositoryImpl(
        NotesDao(db),
      ).addNote(id, kind: NoteKind.quote, content: 'Zitat');
      await ReadingRepositoryImpl(ReadingDao(db)).logSession(
        id,
        startedAt: DateTime(2026),
        duration: const Duration(minutes: 20),
        startPage: 0,
        endPage: 10,
      );
      await LendingRepositoryImpl(
        LendingDao(db),
      ).lend(id, borrowerName: 'Anna');

      await books.deleteBook(id);

      final remaining = await db.select(db.books).get();
      expect(remaining.map((b) => b.id), [other]);
      expect(await db.select(db.bookNotes).get(), isEmpty);
      expect(await db.select(db.readingSessions).get(), isEmpty);
      expect(await db.select(db.bookTags).get(), isEmpty);
      expect(await db.select(db.lending).get(), isEmpty);
      expect(
        await db.select(db.tags).get(),
        hasLength(1),
        reason: 'the tag itself stays',
      );
    });

    test('deleting an unknown id is a no-op', () async {
      await addBook('A');
      await books.deleteBook(9999);
      expect(await db.select(db.books).get(), hasLength(1));
    });
  });

  test('updateFavorite toggles the flag', () async {
    final id = await addBook('A');
    expect((await books.getBook(id))!.isFavorite, isFalse);

    await books.updateFavorite(id, true);
    expect((await books.getBook(id))!.isFavorite, isTrue);

    await books.updateFavorite(id, false);
    expect((await books.getBook(id))!.isFavorite, isFalse);
  });

  test('updateReview trims, stores and clears on blank text', () async {
    final id = await addBook('A');

    await books.updateReview(id, '  Sehr gut.  ');
    expect((await books.getBook(id))!.review, 'Sehr gut.');

    await books.updateReview(id, '   ');
    expect((await books.getBook(id))!.review, isNull);

    await books.updateReview(id, 'Wieder da');
    await books.updateReview(id, null);
    expect((await books.getBook(id))!.review, isNull);
  });

  group('LibraryCubit', () {
    test(
      'favourites filter shows only favourites and combines with search',
      () async {
        await addBook('Alpha', favorite: true);
        await addBook('Alpine');
        await addBook('Beta', favorite: true);
        cubit.load();
        expect(await titles(), hasLength(3));

        cubit.toggleFavoritesOnly();
        final state =
            await cubit.stream.firstWhere(
                  (s) => s is LibraryLoaded && s.favoritesOnly,
                )
                as LibraryLoaded;
        expect(state.books.map((b) => b.title).toSet(), {'Alpha', 'Beta'});
        expect(state.hasActiveFilters, isTrue);

        cubit.search('Alp');
        final narrowed =
            await cubit.stream.firstWhere(
                  (s) => s is LibraryLoaded && s.query == 'Alp',
                )
                as LibraryLoaded;
        expect(narrowed.books.map((b) => b.title), ['Alpha']);

        cubit.toggleFavoritesOnly();
        cubit.search('');
        final all =
            await cubit.stream.firstWhere(
                  (s) =>
                      s is LibraryLoaded && !s.favoritesOnly && s.query.isEmpty,
                )
                as LibraryLoaded;
        expect(all.books, hasLength(3));
      },
    );

    test('setFavorite updates the running list reactively', () async {
      final id = await addBook('Alpha');
      await addBook('Beta');
      cubit.load();
      cubit.toggleFavoritesOnly();
      await cubit.stream.firstWhere(
        (s) => s is LibraryLoaded && s.favoritesOnly && s.books.isEmpty,
      );

      await cubit.setFavorite(id, true);
      final state =
          await cubit.stream.firstWhere(
                (s) => s is LibraryLoaded && s.books.isNotEmpty,
              )
              as LibraryLoaded;
      expect(state.books.single.title, 'Alpha');
    });

    test(
      'selectSort re-orders the list and flips on the active field',
      () async {
        await addBook('Beta', rating: 2, createdAt: DateTime(2024));
        await addBook('Alpha', rating: 5, createdAt: DateTime(2025));
        await addBook('Gamma', rating: 3.5, createdAt: DateTime(2023));
        cubit.load();
        expect(await titles(), [
          'Alpha',
          'Beta',
          'Gamma',
        ], reason: 'newest first');

        cubit.selectSort(LibrarySortField.title);
        expect(
          (await cubit.stream.firstWhere(
                    (s) =>
                        s is LibraryLoaded &&
                        s.sort.field == LibrarySortField.title,
                  )
                  as LibraryLoaded)
              .books
              .map((b) => b.title),
          ['Alpha', 'Beta', 'Gamma'],
        );

        cubit.selectSort(LibrarySortField.title); // flip
        expect(
          (await cubit.stream.firstWhere(
                    (s) => s is LibraryLoaded && !s.sort.ascending,
                  )
                  as LibraryLoaded)
              .books
              .map((b) => b.title),
          ['Gamma', 'Beta', 'Alpha'],
        );

        cubit.selectSort(LibrarySortField.rating);
        expect(
          (await cubit.stream.firstWhere(
                    (s) =>
                        s is LibraryLoaded &&
                        s.sort.field == LibrarySortField.rating,
                  )
                  as LibraryLoaded)
              .books
              .map((b) => b.rating),
          [5.0, 3.5, 2.0],
        );
      },
    );

    test('deleteBook removes the book from the running list', () async {
      final id = await addBook('Weg');
      await addBook('Bleibt');
      cubit.load();
      expect(await titles(), hasLength(2));

      await cubit.deleteBook(id);
      final state =
          await cubit.stream.firstWhere(
                (s) => s is LibraryLoaded && s.books.length == 1,
              )
              as LibraryLoaded;
      expect(state.books.single.title, 'Bleibt');
    });
  });
}
