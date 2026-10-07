import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/library/library_cubit.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late LibraryCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    cubit = LibraryCubit(books);
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
}
