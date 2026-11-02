import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/reading_tracker_service.dart';
import 'package:openreads/features/reading/reading_cubit.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late ReadingRepositoryImpl reading;
  late ReadingCubit cubit;
  late int bookId;
  late DateTime now;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    reading = ReadingRepositoryImpl(ReadingDao(db));
    now = DateTime(2026, 5, 1, 20);
    bookId = await books.insertBook(
      BooksCompanion.insert(
        title: 'Buch',
        authors: const ['A'],
        editedFields: const [],
        pageCount: const Value(200),
      ),
    );
    cubit = ReadingCubit(
      bookId: bookId,
      tracker: ReadingTrackerService(books, reading, clock: () => now),
      readingRepository: reading,
      bookRepository: books,
    )..load();
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  /// Resolves with the first loaded state satisfying [test], checking the
  /// current state first so an already-emitted state is not missed.
  Future<ReadingLoaded> loaded(bool Function(ReadingLoaded) test) async {
    bool matches(ReadingState s) => s is ReadingLoaded && test(s);
    if (matches(cubit.state)) return cubit.state as ReadingLoaded;
    return await cubit.stream.firstWhere(matches) as ReadingLoaded;
  }

  test('start → stop produces a session with speed', () async {
    await loaded((_) => true);

    await cubit.start();
    final running = await loaded((s) => s.active != null);
    expect(running.book.status, BookStatus.reading);

    now = now.add(const Duration(hours: 1));
    await cubit.stop(endPage: 30);
    final done = await loaded(
      (s) => s.active == null && s.sessions.length == 1,
    );
    expect(done.book.currentPage, 30);
    expect(done.stats.sessionCount, 1);
    expect(done.stats.pagesPerHour, closeTo(30, 1e-9));
  });

  test('setPage and manual log update the state', () async {
    await loaded((_) => true);
    await cubit.setPage(50);
    await loaded((s) => s.book.currentPage == 50);

    await cubit.logSession(
      startedAt: DateTime(2026, 4, 30, 19),
      duration: const Duration(minutes: 60),
      startPage: 50,
      endPage: 80,
    );
    final state = await loaded((s) => s.sessions.length == 1);
    expect(state.book.currentPage, 80);

    await cubit.deleteSession(state.sessions.single.id);
    await loaded((s) => s.sessions.isEmpty);
  });
}
