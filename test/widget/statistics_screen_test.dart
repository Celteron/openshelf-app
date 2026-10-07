import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/statistics.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';
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
    expect(find.text('read'), findsOneWidget);
    expect(find.text('unread'), findsOneWidget);

    await cubit.close();
  });
}
