import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/features/trash/trash_cubit.dart';

import '../helpers/test_images.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late CoverCacheService covers;
  late Directory dir;
  late TrashCubit cubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    books = BookRepositoryImpl(BooksDao(db));
    dir = Directory.systemTemp.createTempSync('trash_cubit_test');
    covers = CoverCacheService(baseDirectory: dir);
    cubit = TrashCubit(books, coverCache: covers);
  });
  tearDown(() async {
    await cubit.close();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<int> add(String title, {String? cover}) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
      coverLocalPath: Value(cover),
    ),
  );

  Future<TrashLoaded> loaded(bool Function(TrashLoaded) test) async =>
      (await cubit.stream.firstWhere((s) => s is TrashLoaded && test(s)))
          as TrashLoaded;

  test('starts loading, then lists the trashed books', () async {
    final a = await add('A');
    await add('B');
    await books.deleteBook(a);

    expect(cubit.state, isA<TrashLoading>());
    cubit.load();

    final state = await loaded((_) => true);
    expect(state.books.map((b) => b.title), ['A']);
  });

  test('is empty when nothing was deleted', () async {
    await add('A');
    cubit.load();
    expect((await loaded((_) => true)).books, isEmpty);
  });

  test('follows deletions and restores live', () async {
    final id = await add('Flackern');
    cubit.load();
    await loaded((s) => s.books.isEmpty);

    await books.deleteBook(id);
    await loaded((s) => s.books.length == 1);

    await cubit.restore(id);
    await loaded((s) => s.books.isEmpty);
    expect((await books.getBook(id))!.deletedAt, isNull);
  });

  test('deleteForever removes the book and its cover file', () async {
    final path = await covers.saveCover('x', testPng());
    final id = await add('Weg', cover: path);
    await books.deleteBook(id);
    cubit.load();
    final book = (await loaded((s) => s.books.isNotEmpty)).books.single;

    await cubit.deleteForever(book);

    expect(await books.getBook(id), isNull);
    expect(covers.exists(path), isFalse);
  });

  test('deleteForever without a cover file works too', () async {
    final id = await add('Ohne');
    await books.deleteBook(id);
    cubit.load();
    final book = (await loaded((s) => s.books.isNotEmpty)).books.single;

    await cubit.deleteForever(book);

    expect(await books.getBook(id), isNull);
  });

  test('emptyTrash purges everything in the trash and its covers', () async {
    final p1 = await covers.saveCover('c1', testPng(seed: 1));
    final p2 = await covers.saveCover('c2', testPng(seed: 2));
    final keepPath = await covers.saveCover('keep', testPng(seed: 3));
    final a = await add('A', cover: p1);
    final b = await add('B', cover: p2);
    final keep = await add('Bleibt', cover: keepPath);
    await books.deleteBooks([a, b]);
    cubit.load();
    await loaded((s) => s.books.length == 2);

    final removed = await cubit.emptyTrash();

    expect(removed, 2);
    expect(covers.exists(p1), isFalse);
    expect(covers.exists(p2), isFalse);
    expect(covers.exists(keepPath), isTrue, reason: 'only trashed covers go');
    expect(await books.getBook(keep), isNotNull);
    expect(await books.getBook(a), isNull);
  });

  test('works without a cover service', () async {
    final id = await add('A');
    await books.deleteBook(id);
    final plain = TrashCubit(books);
    addTearDown(plain.close);
    plain.load();
    await plain.stream.firstWhere((s) => s is TrashLoaded);

    expect(await plain.emptyTrash(), 1);
  });
}
