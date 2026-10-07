import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/tag_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/library/library_cubit.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late TagRepositoryImpl tags;
  late LibraryCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    tags = TagRepositoryImpl(TagsDao(db));
    cubit = LibraryCubit(books, tagRepository: tags);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<int> addBook(String title, {BookStatus status = BookStatus.unread}) =>
      books.insertBook(
        BooksCompanion.insert(
          title: title,
          authors: const ['A'],
          editedFields: const [],
          status: Value(status),
        ),
      );

  Future<List<String>> titles() async {
    final state = await cubit.stream.firstWhere((s) => s is LibraryLoaded);
    return (state as LibraryLoaded).books.map((b) => b.title).toList()..sort();
  }

  test('status chip actually filters the list', () async {
    await addBook('Gelesen', status: BookStatus.read);
    await addBook('Wunsch', status: BookStatus.wishlist);
    cubit.load();
    expect(await titles(), ['Gelesen', 'Wunsch']);

    cubit.filterByStatus(BookStatus.wishlist);
    expect(await titles(), ['Wunsch']);

    cubit.filterByStatus(null);
    expect(await titles(), ['Gelesen', 'Wunsch']);
  });

  test('query, status and tags combine (AND)', () async {
    final a = await addBook('Alpha', status: BookStatus.read);
    final b = await addBook('Alpine', status: BookStatus.read);
    final c = await addBook('Beta', status: BookStatus.read);
    final tag = await tags.createTag('Krimi');
    await tags.setBookTags(a, {tag});
    await tags.setBookTags(c, {tag});
    expect(b, isNot(a));

    cubit.load();
    cubit.toggleTag(tag);
    expect(await titles(), ['Alpha', 'Beta']);

    await cubit.search('Alp');
    expect(await titles(), ['Alpha']);

    await cubit.search('');
    cubit.toggleTag(tag);
    expect(await titles(), ['Alpha', 'Alpine', 'Beta']);
  });

  test('retainTags drops a deleted tag from the filter', () async {
    final a = await addBook('Alpha');
    final tag = await tags.createTag('Weg');
    await tags.setBookTags(a, {tag});
    cubit.load();
    cubit.toggleTag(tag);
    expect(await titles(), ['Alpha']);

    await tags.deleteTag(tag);
    cubit.retainTags({});
    final state = await cubit.stream.firstWhere(
      (s) => s is LibraryLoaded && s.tagIds.isEmpty,
    );
    expect((state as LibraryLoaded).books, hasLength(1));
  });

  test('moveToLibrary turns a wishlist book into an unread one', () async {
    final id = await addBook('Wunsch', status: BookStatus.wishlist);
    await cubit.moveToLibrary(id);
    expect((await books.getBook(id))!.status, BookStatus.unread);
  });
}
