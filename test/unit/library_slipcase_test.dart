import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/library/library_cubit.dart';

/// The library shows a slipcase as one entry with its volumes (ADR-0003).
void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late LibraryCubit cubit;
  late int box;
  late List<int> volumes;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    books = BookRepositoryImpl(BooksDao(db));
    cubit = LibraryCubit(books);
    await books.insertBook(
      BooksCompanion.insert(
        title: 'Einzeln',
        authors: const ['A'],
        editedFields: const [],
      ),
    );
    box = await books.insertBook(
      BooksCompanion.insert(
        title: 'Schuber',
        authors: const ['A'],
        editedFields: const [],
      ),
    );
    volumes = await books.splitIntoVolumes(box, const [
      VolumeDraft(title: 'Tödliche Spiele'),
      VolumeDraft(title: 'Gefährliche Liebe'),
    ]);
    await books.updateStatus(volumes.first, BookStatus.read);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<LibraryLoaded> next() async =>
      await cubit.stream.firstWhere((s) => s is LibraryLoaded) as LibraryLoaded;

  test('a slipcase is one entry carrying its volumes', () async {
    cubit.load();
    final state = await next();

    expect(state.books.map((b) => b.title), ['Einzeln', 'Schuber']);
    expect(state.volumes[box]!.map((v) => v.id), volumes);
  });

  test('a search hit on a volume shows its slipcase', () async {
    cubit.load();
    await next();
    await cubit.search('Tödliche');

    expect((await next()).books.map((b) => b.title), ['Schuber']);
  });

  test('the status filter judges a slipcase by its volumes', () async {
    cubit.load();
    await next();

    cubit.filterByStatus(BookStatus.reading);
    expect((await next()).books.map((b) => b.title), ['Schuber']);

    cubit.filterByStatus(BookStatus.unread);
    expect((await next()).books.map((b) => b.title), [
      'Einzeln',
      'Schuber',
    ], reason: 'one volume is still unread');
  });
}
