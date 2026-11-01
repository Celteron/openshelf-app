import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/domain/models/reading_stats.dart';

/// Editing "Lesebeginn" and "Leseende" of a book (spec 004 FR-R2-22).
void main() {
  late AppDatabase db;
  late ReadingRepositoryImpl reading;
  late int book;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    reading = ReadingRepositoryImpl(ReadingDao(db));
    book = await BookRepositoryImpl(BooksDao(db)).insertBook(
      BooksCompanion.insert(
        title: 'T',
        authors: const ['A'],
        editedFields: const [],
      ),
    );
  });
  tearDown(() => db.close());

  Future<List<ReadingSession>> sessions() =>
      db.select(db.readingSessions).get();

  Future<ReadingSummary> summary() async =>
      ReadingSummary.compute(await sessions());

  Future<DateTime?> finishedAt() async =>
      (await BooksDao(db).getById(book))!.finishedAt;

  test('a book without sessions gets one dated session', () async {
    await reading.setReadingDates(
      book,
      start: DateTime(2024, 1, 5),
      end: DateTime(2024, 2, 10),
    );

    final s = (await sessions()).single;
    expect(s.startedAt, DateTime(2024, 1, 5));
    expect(s.endedAt, DateTime(2024, 2, 10));
    expect(s.durationSeconds, 0, reason: 'no reading time is invented');
    expect(await finishedAt(), DateTime(2024, 2, 10));
  });

  test('only an end date is a session on that day', () async {
    await reading.setReadingDates(book, end: DateTime(2024, 2, 10));

    final s = (await sessions()).single;
    expect(
      (s.startedAt, s.endedAt),
      (DateTime(2024, 2, 10), DateTime(2024, 2, 10)),
    );
  });

  test('existing sessions move at the edges, times stay', () async {
    await reading.logSession(
      book,
      startedAt: DateTime(2024, 3, 1, 20),
      duration: const Duration(minutes: 30),
      startPage: 0,
      endPage: 30,
    );
    await reading.logSession(
      book,
      startedAt: DateTime(2024, 3, 8, 20),
      duration: const Duration(minutes: 45),
      startPage: 30,
      endPage: 80,
    );

    await reading.setReadingDates(
      book,
      start: DateTime(2024, 2, 20),
      end: DateTime(2024, 3, 12),
    );

    final result = await summary();
    expect(result.startedAt, DateTime(2024, 2, 20));
    expect(result.finishedAt, DateTime(2024, 3, 12));
    expect(result.readingTime, const Duration(minutes: 75));
    expect(await sessions(), hasLength(2));
    expect(await finishedAt(), DateTime(2024, 3, 12));
  });

  test('an end before the last session start moves that start too', () async {
    await reading.logSession(
      book,
      startedAt: DateTime(2024, 3, 8, 20),
      duration: const Duration(minutes: 45),
      startPage: 0,
      endPage: 80,
    );

    await reading.setReadingDates(book, end: DateTime(2024, 3, 1));

    final s = (await sessions()).single;
    expect(s.endedAt, DateTime(2024, 3, 1));
    expect(s.startedAt.isAfter(s.endedAt!), isFalse);
  });

  test('a running session keeps running', () async {
    await reading.startSession(
      book,
      startedAt: DateTime(2024, 3, 8, 20),
      startPage: 0,
    );

    await reading.setReadingDates(book, start: DateTime(2024, 3, 1));

    final s = (await sessions()).single;
    expect(s.startedAt, DateTime(2024, 3, 1));
    expect(s.endedAt, isNull);
  });
}
