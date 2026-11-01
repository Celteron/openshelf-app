import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/lending_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/database/daos/notes_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/lending_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
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
    String? coverLocalPath,
  }) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
      rating: Value(rating),
      isFavorite: Value(favorite),
      coverLocalPath: Value(coverLocalPath),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  Future<List<String>> titles() async {
    final state = await cubit.stream.firstWhere((s) => s is LibraryLoaded);
    return (state as LibraryLoaded).books.map((b) => b.title).toList();
  }

  group('purgeBook', () {
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

      await books.purgeBook(id);

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

    test('purging an unknown id is a no-op', () async {
      await addBook('A');
      await books.purgeBook(9999);
      expect(await db.select(db.books).get(), hasLength(1));
    });
  });

  group('trash', () {
    Future<List<String>> library() async => [
      for (final b in await books.watchBooks().first) b.title,
    ];
    Future<List<String>> trash() async => [
      for (final b in await books.watchTrashedBooks().first) b.title,
    ];

    test('deleteBook moves the book to the trash and keeps its data', () async {
      final id = await addBook('Weg');
      await addBook('Bleibt');
      await NotesRepositoryImpl(
        NotesDao(db),
      ).addNote(id, kind: NoteKind.note, content: 'Notiz');

      await books.deleteBook(id);

      expect(await library(), ['Bleibt']);
      expect(await trash(), ['Weg']);
      expect((await books.getBook(id))!.deletedAt, isNotNull);
      expect(await db.select(db.bookNotes).get(), hasLength(1));
    });

    test('trashed books are hidden from search and getAll', () async {
      final id = await addBook('Verstecktes Buch');
      await addBook('Sichtbares Buch');
      await books.deleteBook(id);

      expect((await books.searchLocal('Buch')).map((b) => b.title), [
        'Sichtbares Buch',
      ]);
      expect((await books.getAllBooks()).map((b) => b.title), [
        'Sichtbares Buch',
      ]);
    });

    test('restoreBook brings it back', () async {
      final id = await addBook('Zurück');
      await books.deleteBook(id);
      expect(await library(), isEmpty);

      await books.restoreBook(id);

      expect(await library(), ['Zurück']);
      expect(await trash(), isEmpty);
      expect((await books.getBook(id))!.deletedAt, isNull);
    });

    test('deleting twice keeps the first deletion time', () async {
      final id = await addBook('A');
      await books.deleteBook(id);
      final first = (await books.getBook(id))!.deletedAt;
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      await books.deleteBook(id);

      expect((await books.getBook(id))!.deletedAt, first);
    });

    test('deleteBooks trashes several at once', () async {
      final a = await addBook('A');
      final b = await addBook('B');
      await addBook('C');

      await books.deleteBooks([a, b]);

      expect(await library(), ['C']);
      expect((await trash())..sort(), ['A', 'B']);
    });

    test('the trash lists the most recently deleted first', () async {
      final a = await addBook('Zuerst');
      final b = await addBook('Danach');
      await books.deleteBook(a);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await books.deleteBook(b);

      expect(await trash(), ['Danach', 'Zuerst']);
    });

    test('emptyTrash purges only trashed books, with their data', () async {
      final gone = await addBook('Weg');
      final keep = await addBook('Bleibt');
      await NotesRepositoryImpl(
        NotesDao(db),
      ).addNote(gone, kind: NoteKind.note, content: 'x');
      await books.deleteBook(gone);

      final removed = await books.emptyTrash();

      expect(removed, 1);
      expect((await db.select(db.books).get()).map((b) => b.id), [keep]);
      expect(await db.select(db.bookNotes).get(), isEmpty);
    });

    test('an ISBN in the trash still counts as taken', () async {
      final id = await books.insertBook(
        BooksCompanion.insert(
          title: 'Mit ISBN',
          authors: const ['A'],
          editedFields: const [],
          isbn13: const Value('9783000000001'),
        ),
      );
      await books.deleteBook(id);

      // The column is unique, so scanning it again must not try to insert.
      expect(await books.isbnExists('9783000000001'), isTrue);
    });

    test('trashed books do not count for a location', () async {
      final locations = LocationRepositoryImpl(LocationsDao(db));
      final shelf = await locations.createLocation(
        name: 'Regal',
        type: LocationType.shelf,
      );
      final id = await books.insertBook(
        BooksCompanion.insert(
          title: 'Im Regal',
          authors: const ['A'],
          editedFields: const [],
          locationId: Value(shelf),
        ),
      );
      expect(await LocationsDao(db).countBooksAt(shelf), 1);

      await books.deleteBook(id);

      expect(await LocationsDao(db).countBooksAt(shelf), 0);
    });

    test(
      'cubit: the list drops a trashed book and shows it again on restore',
      () async {
        final id = await addBook('Flackern');
        cubit.load();
        expect(await titles(), ['Flackern']);

        await cubit.deleteBook(id);
        await cubit.stream.firstWhere(
          (s) => s is LibraryLoaded && s.books.isEmpty,
        );

        await cubit.restoreBook(id);
        final state = await cubit.stream.firstWhere(
          (s) => s is LibraryLoaded && s.books.isNotEmpty,
        );
        expect((state as LibraryLoaded).books.single.title, 'Flackern');
      },
    );
  });

  group('bulk edit', () {
    test(
      'bulkSetFormat and bulkSetAuthors change only the selected books',
      () async {
        final a = await addBook('A');
        final b = await addBook('B');
        final c = await addBook('C');

        await books.bulkSetFormat([a, b], BookFormat.hardcover);
        await books.bulkSetAuthors([b, c], ['Neu Autor']);

        Future<Book> get(int id) async => (await books.getBook(id))!;
        expect((await get(a)).format, BookFormat.hardcover);
        expect((await get(b)).format, BookFormat.hardcover);
        expect((await get(c)).format, isNull);
        expect((await get(a)).authors, ['A']);
        expect((await get(b)).authors, ['Neu Autor']);
        expect((await get(c)).authors, ['Neu Autor']);
      },
    );
  });

  test('setCoverLocalPath stores and clears the path', () async {
    final id = await addBook('Cover');
    await books.setCoverLocalPath(id, '/tmp/covers/x.jpg');
    expect((await books.getBook(id))!.coverLocalPath, '/tmp/covers/x.jpg');

    await books.setCoverLocalPath(id, null);
    expect((await books.getBook(id))!.coverLocalPath, isNull);
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

    group('without-cover filter (FR-R2-14)', () {
      test('narrows to books without a cover file', () async {
        await addBook('Mit', coverLocalPath: '/covers/mit.jpg');
        await addBook('Ohne');
        cubit.load();
        final loaded =
            await cubit.stream.firstWhere((s) => s is LibraryLoaded)
                as LibraryLoaded;
        expect(loaded.hasCoverless, isTrue);
        expect(loaded.withoutCoverOnly, isFalse);

        cubit.toggleWithoutCover();
        final state =
            await cubit.stream.firstWhere(
                  (s) => s is LibraryLoaded && s.withoutCoverOnly,
                )
                as LibraryLoaded;
        expect(state.books.map((b) => b.title), ['Ohne']);
        expect(state.hasActiveFilters, isTrue);
      });

      test('is not offered when every book has a cover', () async {
        await addBook('Mit', coverLocalPath: '/covers/mit.jpg');
        cubit.load();
        final loaded =
            await cubit.stream.firstWhere((s) => s is LibraryLoaded)
                as LibraryLoaded;
        expect(loaded.hasCoverless, isFalse);
      });

      test(
        'showWithoutCover drops the chip filters that could hide them',
        () async {
          await addBook('Ohne');
          await addBook('Favorit', favorite: true, coverLocalPath: '/c.jpg');
          cubit.load();
          cubit.toggleFavoritesOnly();
          cubit.filterByStatus(BookStatus.read);
          await cubit.stream.firstWhere(
            (s) => s is LibraryLoaded && s.statusFilter == BookStatus.read,
          );

          cubit.showWithoutCover();
          cubit.showWithoutCover();
          final state =
              await cubit.stream.firstWhere(
                    (s) => s is LibraryLoaded && s.withoutCoverOnly,
                  )
                  as LibraryLoaded;
          expect(state.favoritesOnly, isFalse);
          expect(state.statusFilter, isNull);
          expect(state.books.map((b) => b.title), ['Ohne']);
        },
      );
    });

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
        await addBook('Beta', rating: 2, createdAt: DateTime(2025));
        await addBook('Alpha', rating: 5, createdAt: DateTime(2024));
        await addBook('Gamma', rating: 3.5, createdAt: DateTime(2023));
        cubit.load();
        expect(await titles(), [
          'Alpha',
          'Beta',
          'Gamma',
        ], reason: 'title A→Z by default');

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

        cubit.selectSort(LibrarySortField.added);
        expect(
          (await cubit.stream.firstWhere(
                    (s) =>
                        s is LibraryLoaded &&
                        s.sort.field == LibrarySortField.added,
                  )
                  as LibraryLoaded)
              .books
              .map((b) => b.title),
          ['Beta', 'Alpha', 'Gamma'],
          reason: 'newest first',
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
