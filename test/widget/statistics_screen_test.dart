import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/statistics.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';
import 'package:openreads/features/statistics/statistics_books_screen.dart';
import 'package:openreads/features/statistics/statistics_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Pre-loads a fixed aggregate and disables auto-loading so the widget test is
/// deterministic and independent of database streams.
class _LoadedStatisticsCubit extends StatisticsCubit {
  _LoadedStatisticsCubit(BookStatistics stats)
    : super(_NoopBookRepository(), _NoopLocationRepository()) {
    emit(StatisticsLoaded(stats));
  }

  @override
  void load() {}
}

class _NoopBookRepository implements BookRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopLocationRepository implements LocationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('large numbers and durations are easy to read (FR-R2-24)', (
    tester,
  ) async {
    const stats = BookStatistics(
      totalBooks: 1200,
      statusCounts: {
        BookStatus.unread: 0,
        BookStatus.reading: 0,
        BookStatus.read: 1200,
        BookStatus.dnf: 0,
        BookStatus.wishlist: 0,
        BookStatus.reReading: 0,
      },
      pagesRead: 1234567,
      topLocations: [],
      topAuthors: [],
      averagePages: 12345,
      longestBook: NameCount('Dick', 23456),
      fastestBook: NameCount('Lang gelesen', 3 * 86400 + 5 * 3600),
    );
    final cubit = _LoadedStatisticsCubit(stats);
    addTearDown(cubit.close);
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<StatisticsCubit>.value(
          value: cubit,
          child: const StatisticsScreen(),
        ),
      ),
    );
    await tester.pump();

    // Grouped into sections, in this order (FR-R2-15).
    final headers = [
      'section-overview',
      'section-reading',
      'section-records',
      'section-library',
    ];
    final tops = [
      for (final key in headers)
        tester.getTopLeft(find.byKey(ValueKey(key))).dy,
    ];
    expect([...tops]..sort(), tops);

    expect(find.text('1.200'), findsOneWidget);
    expect(find.text('1.234.567'), findsOneWidget);
    expect(find.textContaining('12.345 Seiten'), findsOneWidget);
    expect(find.textContaining('23.456 Seiten'), findsOneWidget);
    expect(find.textContaining('3 T. 5 Std.'), findsOneWidget);
  });

  testWidgets('statistics screen renders totals and status breakdown', (
    tester,
  ) async {
    const stats = BookStatistics(
      totalBooks: 2,
      statusCounts: {
        BookStatus.unread: 0,
        BookStatus.reading: 0,
        BookStatus.read: 1,
        BookStatus.dnf: 0,
        BookStatus.wishlist: 0,
        BookStatus.reReading: 0,
      },
      pagesRead: 300,
      topLocations: [NameCount('Regal', 1)],
      topAuthors: [NameCount('Autor', 2)],
    );

    final cubit = _LoadedStatisticsCubit(stats);
    // Tall enough for the whole (lazily built) list.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<StatisticsCubit>.value(
          value: cubit,
          child: const StatisticsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Bücher gesamt'), findsOneWidget);
    expect(find.text('Gelesene Seiten'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('Gelesen'), findsOneWidget);
    expect(find.text('Ungelesen'), findsOneWidget);

    await cubit.close();
  });

  group('drill-down (FR-R2-17)', () {
    Book book(int id, String title, BookStatus status, {DateTime? finished}) =>
        Book(
          id: id,
          title: title,
          authors: const ['A'],
          status: status,
          rating: 0,
          finishedAt: finished,
          editedFields: const [],
          currentPage: 0,
          isFavorite: false,
          coverNotFound: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    Future<void> pumpStats(WidgetTester tester) async {
      final books = [
        book(1, 'Märzbuch', BookStatus.read, finished: DateTime(2026, 3, 2)),
        book(2, 'Stapel', BookStatus.unread),
      ];
      final stats = BookStatistics(
        totalBooks: 2,
        statusCounts: const {BookStatus.read: 1, BookStatus.unread: 1},
        pagesRead: 0,
        topLocations: const [],
        topAuthors: const [],
        year: 2026,
        years: const [2026],
        monthly: [
          for (var m = 1; m <= 12; m++) MonthStat(m, m == 3 ? 1 : 0, 0),
        ],
        books: books,
      );
      final cubit = _LoadedStatisticsCubit(stats);
      addTearDown(cubit.close);
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<StatisticsCubit>.value(
            value: cubit,
            child: const StatisticsScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a month opens its finished books', (tester) async {
      await pumpStats(tester);
      // The whole chart opens a month list with large rows.
      await tester.tap(find.byKey(const ValueKey('chart-books-months')));
      await tester.pumpAndSettle();
      final empty = tester.widget<ListTile>(
        find.byKey(const ValueKey('chart-books-month-5')),
      );
      expect(empty.enabled, isFalse, reason: 'no books in May');
      await tester.tap(find.byKey(const ValueKey('chart-books-month-3')));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsBooksScreen), findsOneWidget);
      expect(find.text('März 2026'), findsOneWidget);
      expect(find.text('Märzbuch'), findsOneWidget);
      expect(find.text('Stapel'), findsNothing);
    });

    testWidgets('a status opens its books', (tester) async {
      await pumpStats(tester);
      await tester.tap(find.byKey(const ValueKey('status-books-unread')));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsBooksScreen), findsOneWidget);
      expect(find.text('Stapel'), findsOneWidget);
      expect(find.text('Märzbuch'), findsNothing);
    });
  });

  testWidgets('collection statistics are shown (FR-R2-18)', (tester) async {
    final stats = BookStatistics(
      totalBooks: 3,
      statusCounts: const {BookStatus.unread: 3},
      pagesRead: 0,
      topLocations: const [],
      topAuthors: const [],
      monthly: [for (var m = 1; m <= 12; m++) MonthStat(m, 0, 0, added: 1)],
      unreadStack: const [3, 3, 4],
      receivedAs: const {ReceivedAs.gift: 2},
      spendingByYear: const {2025: 1000, 2026: 2550},
    );
    final cubit = _LoadedStatisticsCubit(stats);
    addTearDown(cubit.close);
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<StatisticsCubit>.value(
          value: cubit,
          child: const StatisticsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('chart-added')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-unread-stack')), findsOneWidget);
    expect(find.text('Geschenk'), findsOneWidget);
    expect(find.text('25,50\u00A0€'), findsOneWidget);
    expect(find.text('10,00\u00A0€'), findsOneWidget);
  });
}
