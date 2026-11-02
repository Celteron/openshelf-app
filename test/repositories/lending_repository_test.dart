import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/lending_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/lending_repository_impl.dart';
import 'package:openreads/features/lending/lending_cubit.dart';

void main() {
  late AppDatabase db;
  late LendingRepositoryImpl lending;
  late BookRepositoryImpl books;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Foreign keys are switched on when the database opens.
    await db.customSelect('select 1').get();
    lending = LendingRepositoryImpl(LendingDao(db));
    books = BookRepositoryImpl(BooksDao(db));
  });

  tearDown(() => db.close());

  Future<int> addBook(String title) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
    ),
  );

  group('lending', () {
    test('a book is available until it is lent', () async {
      final book = await addBook('Buch');
      expect(await lending.getActiveLending(book), isNull);
      expect(await lending.watchActiveLending(book).first, isNull);
    });

    test('lend records the borrower and makes the lending active', () async {
      final book = await addBook('Buch');
      final before = DateTime.now().subtract(const Duration(seconds: 2));

      final id = await lending.lend(book, borrowerName: '  Anna  ');

      final active = (await lending.getActiveLending(book))!;
      expect(active.id, id);
      expect(active.bookId, book);
      expect(active.borrowerName, 'Anna', reason: 'trimmed');
      expect(active.lentAt.isAfter(before), isTrue);
      expect(active.returnedAt, isNull);
      expect(active.expectedReturn, isNull);
      expect((await lending.watchActiveLending(book).first)!.id, id);
    });

    test('an expected return date is stored', () async {
      final book = await addBook('Buch');
      final due = DateTime(2030, 6, 1);

      await lending.lend(book, borrowerName: 'Ben', expectedReturn: due);

      expect((await lending.getActiveLending(book))!.expectedReturn, due);
    });

    test('a blank borrower is rejected', () async {
      final book = await addBook('Buch');
      await expectLater(
        lending.lend(book, borrowerName: '   '),
        throwsArgumentError,
      );
      expect(await db.select(db.lending).get(), isEmpty);
    });

    test('a book cannot be lent twice at the same time', () async {
      final book = await addBook('Buch');
      await lending.lend(book, borrowerName: 'Anna');

      await expectLater(
        lending.lend(book, borrowerName: 'Ben'),
        throwsStateError,
      );

      final all = await db.select(db.lending).get();
      expect(all, hasLength(1));
      expect(all.single.borrowerName, 'Anna');
    });

    test('different books can be lent at the same time', () async {
      final a = await addBook('A');
      final b = await addBook('B');

      await lending.lend(a, borrowerName: 'Anna');
      await lending.lend(b, borrowerName: 'Ben');

      expect((await lending.getActiveLending(a))!.borrowerName, 'Anna');
      expect((await lending.getActiveLending(b))!.borrowerName, 'Ben');
    });
  });

  group('returning', () {
    test('markReturned ends the active lending', () async {
      final book = await addBook('Buch');
      final id = await lending.lend(book, borrowerName: 'Anna');
      final returnedAt = DateTime(2026, 5, 4, 10);

      await lending.markReturned(id, returnedAt);

      expect(await lending.getActiveLending(book), isNull);
      expect(await lending.watchActiveLending(book).first, isNull);
      final row = (await db.select(db.lending).get()).single;
      expect(row.returnedAt, returnedAt);
      expect(row.borrowerName, 'Anna', reason: 'history is kept');
    });

    test('a returned book can be lent again', () async {
      final book = await addBook('Buch');
      final first = await lending.lend(book, borrowerName: 'Anna');
      await lending.markReturned(first, DateTime.now());

      final second = await lending.lend(book, borrowerName: 'Ben');

      expect(second, isNot(first));
      expect((await lending.getActiveLending(book))!.borrowerName, 'Ben');
    });

    test('returning twice keeps the first return date', () async {
      final book = await addBook('Buch');
      final id = await lending.lend(book, borrowerName: 'Anna');
      await lending.markReturned(id, DateTime(2026, 1, 1));

      await lending.markReturned(id, DateTime(2027, 2, 2));

      expect(
        (await db.select(db.lending).get()).single.returnedAt,
        DateTime(2026, 1, 1),
      );
    });

    test('returning an unknown lending changes nothing', () async {
      final book = await addBook('Buch');
      await lending.lend(book, borrowerName: 'Anna');

      await lending.markReturned(9999, DateTime.now());

      expect(await lending.getActiveLending(book), isNotNull);
    });
  });

  group('history and active status tracking', () {
    test('the history lists every lending, newest first', () async {
      final book = await addBook('Buch');
      final first = await lending.lend(book, borrowerName: 'Anna');
      await lending.markReturned(first, DateTime.now());
      final second = await lending.lend(book, borrowerName: 'Ben');
      await lending.markReturned(second, DateTime.now());
      await lending.lend(book, borrowerName: 'Carla');

      final history = await lending.watchHistory(book).first;

      expect(history.map((l) => l.borrowerName), ['Carla', 'Ben', 'Anna']);
      expect(history.where((l) => l.returnedAt == null), hasLength(1));
    });

    test('the active-lending stream follows lend and return', () async {
      final book = await addBook('Buch');
      final events = <String?>[];
      final sub = lending
          .watchActiveLending(book)
          .listen((l) => events.add(l?.borrowerName));
      addTearDown(sub.cancel);

      await pumpEventQueue();
      final id = await lending.lend(book, borrowerName: 'Anna');
      await pumpEventQueue();
      await lending.markReturned(id, DateTime.now());
      await pumpEventQueue();

      expect(events, [null, 'Anna', null]);
    });

    test('the history of one book does not include another', () async {
      final a = await addBook('A');
      final b = await addBook('B');
      await lending.lend(a, borrowerName: 'Anna');

      expect(await lending.watchHistory(b).first, isEmpty);
    });
  });

  group('relation to the book', () {
    test('moving a book to the trash keeps its lending', () async {
      final book = await addBook('Buch');
      await lending.lend(book, borrowerName: 'Anna');

      await books.deleteBook(book);

      expect(await lending.getActiveLending(book), isNotNull);
    });

    test('deleting a book permanently deletes its lendings', () async {
      final book = await addBook('Buch');
      final other = await addBook('Anderes');
      await lending.lend(book, borrowerName: 'Anna');
      await lending.lend(other, borrowerName: 'Ben');

      await books.purgeBook(book);

      final rows = await db.select(db.lending).get();
      expect(rows.map((l) => l.borrowerName), ['Ben']);
    });
  });

  group('LendingCubit', () {
    test('reports available, active and available again', () async {
      final book = await addBook('Buch');
      final cubit = LendingCubit(lending);
      addTearDown(cubit.close);

      cubit.watch(book);
      expect(await cubit.stream.first, isA<LendingAvailable>());

      await cubit.lend(book, borrowerName: 'Anna');
      final active = await cubit.stream.firstWhere((s) => s is LendingActive);
      expect((active as LendingActive).lending.borrowerName, 'Anna');

      await cubit.markReturned(active.lending.id);
      expect(
        await cubit.stream.firstWhere((s) => s is LendingAvailable),
        isA<LendingAvailable>(),
      );
    });
  });
}
