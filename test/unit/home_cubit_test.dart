import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/features/home/home_cubit.dart';

class _Books implements BookRepository {
  final controller = StreamController<List<Book>>();

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book _book(int id, BookStatus status) => Book(
  id: id,
  title: 'B$id',
  authors: const ['A'],
  status: status,
  rating: 0,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026, 1, id),
  updatedAt: DateTime(2026),
);

/// The home tab's state (FR-R2-19).
void main() {
  late _Books books;
  late HomeCubit cubit;

  setUp(() {
    books = _Books();
    cubit = HomeCubit(books, now: () => DateTime(2026, 6, 15))..load();
  });

  tearDown(() => cubit.close());

  test('follows the library', () async {
    books.controller.add([_book(1, BookStatus.read)]);
    await pumpEventQueue();
    expect((cubit.state as HomeLoaded).summary.read, 1);

    books.controller.add([
      _book(1, BookStatus.read),
      _book(2, BookStatus.unread),
    ]);
    await pumpEventQueue();
    expect((cubit.state as HomeLoaded).summary.total, 2);
  });

  test('a failing library shows the error, not a crash', () async {
    books.controller.addError(StateError('db closed'));
    await pumpEventQueue();
    expect(cubit.state, isA<HomeError>());
  });

  test('closing stops listening to the library', () async {
    expect(books.controller.hasListener, isTrue);
    await cubit.close();
    expect(books.controller.hasListener, isFalse);
  });
}
