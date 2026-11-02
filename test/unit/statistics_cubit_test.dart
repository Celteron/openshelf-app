import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/goals_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/goal_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';

void main() {
  late AppDatabase db;
  late StatisticsCubit cubit;
  late BookRepositoryImpl books;
  late GoalRepositoryImpl goals;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    books = BookRepositoryImpl(BooksDao(db));
    goals = GoalRepositoryImpl(GoalsDao(db));
    cubit = StatisticsCubit(
      books,
      LocationRepositoryImpl(LocationsDao(db)),
      goalRepository: goals,
      readingRepository: ReadingRepositoryImpl(ReadingDao(db)),
      clock: () => DateTime(2026, 6, 15),
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<int> addRead(String title, DateTime finished, int pages) =>
      books.insertBook(
        BooksCompanion.insert(
          title: title,
          authors: const ['A'],
          editedFields: const [],
          status: const Value(BookStatus.read),
          pageCount: Value(pages),
          finishedAt: Value(finished),
        ),
      );

  Future<StatisticsLoaded> next(bool Function(StatisticsLoaded) test) async {
    final state = await cubit.stream.firstWhere(
      (s) => s is StatisticsLoaded && test(s),
    );
    return state as StatisticsLoaded;
  }

  test('shows the whole library until a year is selected', () async {
    await addRead('Alt', DateTime(2024, 3, 1), 100);
    await addRead('Neu', DateTime(2026, 2, 1), 300);

    cubit.load();
    final all = await next((s) => s.statistics.totalBooks == 2);

    expect(all.statistics.year, isNull);
    expect(all.statistics.years, [2026, 2024]);
    expect(cubit.selectedYear, isNull);
    expect(cubit.goalYear, 2026, reason: 'the current year without selection');
  });

  test('selecting a year narrows every figure to that year', () async {
    await addRead('Alt', DateTime(2024, 3, 1), 100);
    await addRead('Neu', DateTime(2026, 2, 1), 300);
    cubit.load();
    await next((s) => s.statistics.totalBooks == 2);

    cubit.selectYear(2024);
    final state = await next((s) => s.statistics.year == 2024);

    expect(state.statistics.totalBooks, 1);
    expect(state.statistics.pagesRead, 100);
    expect(state.statistics.monthly[2].books, 1, reason: 'March');
    expect(cubit.selectedYear, 2024);

    cubit.selectYear(null);
    final all = await next((s) => s.statistics.year == null);
    expect(all.statistics.totalBooks, 2);
  });

  test('the goal card follows the selected year', () async {
    await addRead('Alt', DateTime(2024, 3, 1), 100);
    await goals.setGoal(2024, 10, targetPages: 2000);
    await goals.setGoal(2026, 20);
    cubit.load();
    final current = await next((s) => s.statistics.goal?.year == 2026);
    expect(current.statistics.goal!.target, 20);

    cubit.selectYear(2024);
    final past = await next((s) => s.statistics.goal?.year == 2024);

    expect(past.statistics.goal!.target, 10);
    expect(past.statistics.goal!.targetPages, 2000);
    expect(past.statistics.goal!.completed, 1);
    expect(past.statistics.goal!.pagesRead, 100);
    expect(cubit.goalYear, 2024);
  });

  test('setGoal stores the goal for the year on screen', () async {
    await addRead('Alt', DateTime(2024, 3, 1), 100);
    cubit.load();
    await next((s) => s.statistics.totalBooks == 1);
    cubit.selectYear(2024);
    await next((s) => s.statistics.year == 2024);

    await cubit.setGoal(12, targetPages: 3000);

    final state = await next((s) => s.statistics.goal != null);
    expect(state.statistics.goal!.year, 2024);
    expect((await goals.watchGoal(2024).first)!.targetBooks, 12);
    expect(await goals.watchGoal(2026).first, isNull);
  });

  test('a pages-only goal is accepted and has no book target', () async {
    await addRead('Buch', DateTime(2026, 1, 1), 250);
    cubit.load();
    await next((s) => s.statistics.totalBooks == 1);

    await cubit.setGoal(0, targetPages: 1000);

    final goal = (await next(
      (s) => s.statistics.goal != null,
    )).statistics.goal!;
    expect(goal.hasBookGoal, isFalse);
    expect(goal.hasPageGoal, isTrue);
    expect(goal.pagesFraction, 0.25);
    expect(goal.reached, isFalse);
  });

  test('trashed books are not counted', () async {
    final id = await addRead('Weg', DateTime(2026, 1, 1), 500);
    await addRead('Bleibt', DateTime(2026, 1, 2), 100);
    cubit.load();
    await next((s) => s.statistics.totalBooks == 2);

    await books.deleteBook(id);

    final state = await next((s) => s.statistics.totalBooks == 1);
    expect(state.statistics.pagesRead, 100);
  });

  test('the sessions of other years do not leak into a year', () async {
    final old = await addRead('Alt', DateTime(2024, 3, 1), 100);
    final fresh = await addRead('Neu', DateTime(2026, 2, 1), 300);
    final reading = ReadingRepositoryImpl(ReadingDao(db));
    await reading.logSession(
      old,
      startedAt: DateTime(2024, 2, 1),
      duration: const Duration(hours: 1),
      startPage: 0,
      endPage: 100,
    );
    await reading.logSession(
      fresh,
      startedAt: DateTime(2026, 1, 1),
      duration: const Duration(hours: 3),
      startPage: 0,
      endPage: 300,
    );
    cubit.load();
    await next((s) => s.statistics.reading.sessionCount == 2);

    cubit.selectYear(2024);
    final state = await next((s) => s.statistics.year == 2024);

    expect(state.statistics.reading.sessionCount, 1);
    expect(state.statistics.reading.totalSeconds, 3600);
    expect(state.statistics.fastestBook!.name, 'Alt');
  });

  test('manual reading time counts for its year only (FR-R2-16)', () async {
    final old = await addRead('Alt', DateTime(2024, 3, 1), 100);
    final fresh = await addRead('Neu', DateTime(2026, 2, 1), 300);
    for (final (id, seconds) in [(old, 1800), (fresh, 7200)]) {
      await (db.update(db.books)..where((b) => b.id.equals(id))).write(
        BooksCompanion(readingSeconds: Value(seconds)),
      );
    }
    cubit.load();
    final all = await next((s) => s.statistics.reading.totalSeconds > 0);
    expect(all.statistics.reading.totalSeconds, 9000);

    cubit.selectYear(2024);
    final state = await next((s) => s.statistics.year == 2024);
    expect(state.statistics.reading.totalSeconds, 1800);
  });
}
