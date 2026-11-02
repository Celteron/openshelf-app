import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/locations/shelf_wall_cubit.dart';

class _Books implements BookRepository {
  final controller = StreamController<List<Book>>.broadcast();
  final moves = <String>[];
  Object? moveError;

  @override
  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId) async {
    if (moveError != null) throw moveError!;
    moves.add('${bookIds.join(',')}->$locationId');
  }

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Locations implements LocationRepository {
  final controller = StreamController<List<Location>>.broadcast();

  @override
  Stream<List<Location>> watchLocations() => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book book(int id, String title, {int? location}) => Book(
  id: id,
  title: title,
  authors: const ['A'],
  status: BookStatus.unread,
  rating: 0,
  locationId: location,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _Books books;
  late _Locations locations;
  late ShelfWallCubit cubit;

  setUp(() {
    books = _Books();
    locations = _Locations();
    cubit = ShelfWallCubit(books, locations)..load();
  });

  tearDown(() async {
    await cubit.close();
    await books.controller.close();
    await locations.controller.close();
  });

  test('it waits for both books and locations', () async {
    expect(cubit.state, isA<ShelfWallLoading>());
    books.controller.add([book(1, 'A')]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<ShelfWallLoading>());

    locations.controller.add(const []);
    final loaded = await cubit.stream.firstWhere((s) => s is ShelfWallLoaded);

    expect(
      (loaded as ShelfWallLoaded).wall.rows.single.spines.single.book.title,
      'A',
    );
  });

  test('the wall follows later changes of the library', () async {
    locations.controller.add(const []);
    books.controller.add([book(1, 'A')]);
    await cubit.stream.firstWhere((s) => s is ShelfWallLoaded);

    books.controller.add([book(1, 'A'), book(2, 'B')]);
    final next = await cubit.stream.firstWhere(
      (s) => s is ShelfWallLoaded && s.wall.rows.single.spines.length == 2,
    );

    expect(next, isA<ShelfWallLoaded>());
  });

  test('a failing stream ends in the error state', () async {
    books.controller.addError(StateError('db'));

    await cubit.stream.firstWhere((s) => s is ShelfWallError);
  });

  group('find it', () {
    Future<ShelfWallLoaded> loaded() async {
      locations.controller.add(const [
        Location(
          id: 1,
          name: 'Fach',
          type: LocationType.compartment,
          sortOrder: 0,
        ),
      ]);
      books.controller.add([
        book(1, 'Roman A', location: 1),
        book(2, 'Gedichte', location: 1),
        book(3, 'Roman B', location: 1),
      ]);
      return await cubit.stream.firstWhere((s) => s is ShelfWallLoaded)
          as ShelfWallLoaded;
    }

    ShelfWallLoaded now() => cubit.state as ShelfWallLoaded;

    test('a query marks the hits and focuses the first', () async {
      await loaded();

      cubit.find('roman');

      expect(now().hits, [1, 3]);
      expect(now().focusedBookId, 1);
      expect(now().query, 'roman');
    });

    test('next and previous go round', () async {
      await loaded();
      cubit.find('roman');

      cubit.nextHit();
      expect(now().focusedBookId, 3);
      cubit.nextHit();
      expect(now().focusedBookId, 1);
      cubit.previousHit();
      expect(now().focusedBookId, 3);
    });

    test('no hit means no focus, and stepping does nothing', () async {
      await loaded();

      cubit.find('xyz');
      cubit.nextHit();

      expect(now().hits, isEmpty);
      expect(now().focusedBookId, isNull);
    });

    test('clearing the search shows the whole wall again', () async {
      await loaded();
      cubit.find('roman');

      cubit.clearFind();

      expect(now().query, '');
      expect(now().hits, isEmpty);
    });

    test('a change in the library keeps the search up to date', () async {
      await loaded();
      cubit.find('roman');

      books.controller.add([book(3, 'Roman B', location: 1)]);
      await cubit.stream.firstWhere(
        (s) => s is ShelfWallLoaded && s.hits.length == 1,
      );

      expect(now().hits, [3]);
      expect(now().focusedBookId, 3);
    });
  });

  group('moving a book', () {
    Future<void> loaded() async {
      locations.controller.add(const [
        Location(
          id: 1,
          name: 'Fach 1',
          type: LocationType.compartment,
          sortOrder: 0,
        ),
        Location(
          id: 2,
          name: 'Fach 2',
          type: LocationType.compartment,
          sortOrder: 1,
        ),
      ]);
      books.controller.add([book(1, 'A', location: 1), book(2, 'B')]);
      await cubit.stream.firstWhere((s) => s is ShelfWallLoaded);
    }

    test('assigns the new location and reports where it came from', () async {
      await loaded();

      final move = await cubit.moveBook(1, 2);

      expect(books.moves, ['1->2']);
      expect((move?.bookId, move?.from, move?.to), (1, 1, 2));
    });

    test(
      'a book without a location can be moved onto a shelf and back',
      () async {
        await loaded();

        final move = await cubit.moveBook(2, 1);
        expect(move?.from, isNull);

        // The database change reaches the wall through the stream.
        books.controller.add([
          book(1, 'A', location: 1),
          book(2, 'B', location: 1),
        ]);
        await cubit.stream.firstWhere(
          (s) => s is ShelfWallLoaded && s.wall.rows.first.spines.length == 2,
        );

        await cubit.moveBook(2, move!.from);
        expect(books.moves.last, '2->null');
      },
    );

    test('moving to where the book already stands does nothing', () async {
      await loaded();

      expect(await cubit.moveBook(1, 1), isNull);
      expect(await cubit.moveBook(2, null), isNull);
      expect(books.moves, isEmpty);
    });

    test('a book that is not on the wall is not moved', () async {
      await loaded();

      expect(await cubit.moveBook(99, 2), isNull);
      expect(books.moves, isEmpty);
    });

    test('a failing repository throws and leaves the wall as it was', () async {
      await loaded();
      final before = cubit.state;
      books.moveError = StateError('db');

      await expectLater(cubit.moveBook(1, 2), throwsStateError);

      expect(cubit.state, same(before));
    });
  });

  group('slipcases', () {
    Future<void> loaded() async {
      locations.controller.add(const [
        Location(
          id: 1,
          name: 'Fach',
          type: LocationType.compartment,
          sortOrder: 0,
        ),
      ]);
      books.controller.add([
        book(1, 'Schuber', location: 1),
        Book(
          id: 2,
          title: 'Sturmzeit',
          authors: const ['A'],
          status: BookStatus.unread,
          rating: 0,
          parentId: 1,
          locationId: 1,
          editedFields: const [],
          currentPage: 0,
          isFavorite: false,
          coverNotFound: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await cubit.stream.firstWhere((s) => s is ShelfWallLoaded);
    }

    ShelfWallLoaded now() => cubit.state as ShelfWallLoaded;

    test('a slipcase opens and closes', () async {
      await loaded();
      expect(now().expanded, isEmpty);

      cubit.toggleSlipcase(1);
      expect(now().expanded, {1});

      cubit.toggleSlipcase(1);
      expect(now().expanded, isEmpty);
    });

    test('finding a volume opens its slipcase', () async {
      await loaded();

      cubit.find('sturmzeit');

      expect(now().focusedBookId, 1);
      expect(now().expanded, {1});
    });

    test('a search without a slipcase hit leaves them closed', () async {
      await loaded();

      cubit.find('nichts');

      expect(now().expanded, isEmpty);
    });
  });

  test(
    'a burst of changes (e.g. a cover search) is rebuilt in few steps',
    () async {
      locations.controller.add(const []);
      books.controller.add([book(0, 'Start')]);
      await cubit.stream.firstWhere((s) => s is ShelfWallLoaded);
      var rebuilds = 0;
      final sub = cubit.stream.listen((_) => rebuilds++);
      addTearDown(sub.cancel);

      for (var i = 1; i <= 40; i++) {
        books.controller.add([for (var b = 0; b <= i; b++) book(b, 'B$b')]);
      }
      final last = await cubit.stream.firstWhere(
        (s) => s is ShelfWallLoaded && s.wall.rows.single.spines.length == 41,
      );

      expect(last, isA<ShelfWallLoaded>());
      expect(
        rebuilds,
        lessThanOrEqualTo(4),
        reason: '40 changes, few rebuilds',
      );
    },
  );
}
