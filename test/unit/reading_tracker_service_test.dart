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

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late ReadingRepositoryImpl reading;
  late ReadingTrackerService tracker;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    reading = ReadingRepositoryImpl(ReadingDao(db));
    now = DateTime(2026, 3, 1, 20);
    tracker = ReadingTrackerService(books, reading, clock: () => now);
  });

  tearDown(() => db.close());

  Future<int> addBook({
    BookStatus status = BookStatus.unread,
    int? pages = 300,
  }) => books.insertBook(
    BooksCompanion.insert(
      title: 'Buch',
      authors: const ['Autor'],
      editedFields: const [],
      status: Value(status),
      pageCount: Value(pages),
    ),
  );

  test('start promotes unread/wishlist/dnf to reading', () async {
    for (final status in [
      BookStatus.unread,
      BookStatus.wishlist,
      BookStatus.dnf,
    ]) {
      final id = await addBook(status: status);
      await tracker.start(id);
      expect((await books.getBook(id))!.status, BookStatus.reading);
    }
  });

  test('start is idempotent and allows only one active session', () async {
    final id = await addBook();
    final first = await tracker.start(id);
    final second = await tracker.start(id);
    expect(second, first);
    expect((await reading.getActiveSession(id))!.id, first);
    await expectLater(
      reading.startSession(id, startedAt: now, startPage: 0),
      throwsStateError,
    );
  });

  test('stop records duration, pages and the current page', () async {
    final id = await addBook();
    await tracker.start(id);
    now = now.add(const Duration(minutes: 30));
    await tracker.stop(id, endPage: 25);

    final sessions = await reading.watchSessions(id).first;
    expect(sessions, hasLength(1));
    expect(sessions.single.durationSeconds, 1800);
    expect(sessions.single.startPage, 0);
    expect(sessions.single.endPage, 25);
    expect(sessions.single.endedAt, isNotNull);
    expect((await books.getBook(id))!.currentPage, 25);
    expect(await reading.getActiveSession(id), isNull);
  });

  test('next session starts on the stored page', () async {
    final id = await addBook();
    await tracker.start(id);
    await tracker.stop(id, endPage: 40);
    await tracker.start(id);
    final active = (await reading.getActiveSession(id))!;
    expect(active.startPage, 40);
  });

  test('reaching the last page marks the book read with finishedAt', () async {
    final id = await addBook(pages: 100);
    await tracker.start(id);
    now = now.add(const Duration(hours: 1));
    await tracker.stop(id, endPage: 250); // clamped to pageCount

    final book = (await books.getBook(id))!;
    expect(book.currentPage, 100);
    expect(book.status, BookStatus.read);
    expect(book.finishedAt, isNotNull);
  });

  test('starting a finished book begins a re-read at page 0', () async {
    final id = await addBook(pages: 100);
    await tracker.setCurrentPage(id, 100);
    expect((await books.getBook(id))!.status, BookStatus.read);

    await tracker.start(id);
    final book = (await books.getBook(id))!;
    expect(book.status, BookStatus.reReading);
    expect(book.currentPage, 0);
    expect((await reading.getActiveSession(id))!.startPage, 0);
  });

  test('setCurrentPage promotes an unread book and clamps', () async {
    final id = await addBook(pages: 50);
    await tracker.setCurrentPage(id, 10);
    var book = (await books.getBook(id))!;
    expect(book.status, BookStatus.reading);
    expect(book.currentPage, 10);

    await tracker.setCurrentPage(id, -5);
    book = (await books.getBook(id))!;
    expect(book.currentPage, 0);
  });

  test('logManual stores a completed session and advances the page', () async {
    final id = await addBook();
    await tracker.logManual(
      id,
      startedAt: DateTime(2026, 2, 1, 19),
      duration: const Duration(minutes: 45),
      startPage: 0,
      endPage: 30,
    );
    final session = (await reading.watchSessions(id).first).single;
    expect(session.durationSeconds, 2700);
    expect(session.endedAt, DateTime(2026, 2, 1, 19, 45));
    expect((await books.getBook(id))!.currentPage, 30);
  });

  test(
    'deleting a session keeps the others; deleting a book cascades',
    () async {
      final id = await addBook();
      await tracker.logManual(
        id,
        startedAt: now,
        duration: const Duration(minutes: 5),
        startPage: 0,
        endPage: 5,
      );
      final sessionId = (await reading.watchSessions(id).first).single.id;
      await reading.deleteSession(sessionId);
      expect(await reading.watchSessions(id).first, isEmpty);

      await tracker.logManual(
        id,
        startedAt: now,
        duration: const Duration(minutes: 5),
        startPage: 0,
        endPage: 5,
      );
      await (db.delete(db.books)..where((t) => t.id.equals(id))).go();
      expect(await db.select(db.readingSessions).get(), isEmpty);
    },
  );

  test('updateStatus sets finishedAt only when entering read', () async {
    final id = await addBook();
    await books.updateStatus(id, BookStatus.read);
    final first = (await books.getBook(id))!.finishedAt;
    expect(first, isNotNull);

    await books.updateStatus(id, BookStatus.read);
    expect((await books.getBook(id))!.finishedAt, first);

    await books.updateStatus(id, BookStatus.reReading);
    expect((await books.getBook(id))!.finishedAt, first);
  });

  test('stop without a running session is a no-op', () async {
    final id = await addBook();
    await tracker.stop(id, endPage: 10);
    expect(await reading.watchSessions(id).first, isEmpty);
  });
}
