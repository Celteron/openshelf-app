import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/series_repository.dart';
import 'package:openreads/features/shopping/shopping_list_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _Books implements BookRepository {
  final List<Book> books;
  _Books(this.books);

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Series implements SeriesRepository {
  final List<Series> series;
  final totals = <int, int?>{};
  _Series(this.series);

  @override
  Future<List<Series>> getAll() async => [
    for (final s in series)
      Series(
        id: s.id,
        name: s.name,
        totalPlannedVolumes: totals.containsKey(s.id)
            ? totals[s.id]
            : s.totalPlannedVolumes,
      ),
  ];

  @override
  Future<void> setTotalVolumes(int id, int? total) async => totals[id] = total;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book _book(
  int id,
  String title, {
  BookStatus status = BookStatus.read,
  int? seriesId,
  double? volume,
}) => Book(
  id: id,
  title: title,
  authors: const ['Autorin'],
  status: status,
  rating: 0,
  seriesId: seriesId,
  seriesVolume: volume,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<Book> books,
    required _Series series,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BookRepository>.value(value: _Books(books)),
          RepositoryProvider<SeriesRepository>.value(value: series),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the wishlist and the missing volumes', (tester) async {
    await pump(
      tester,
      books: [
        _book(1, 'Wunschbuch', status: BookStatus.wishlist),
        _book(2, 'Band 1', seriesId: 1, volume: 1),
      ],
      series: _Series([
        const Series(id: 1, name: 'Krimi-Reihe', totalPlannedVolumes: 3),
      ]),
    );

    expect(find.text('Wunschbuch'), findsOneWidget);
    expect(find.text('Krimi-Reihe: Bände 2, 3 fehlen'), findsOneWidget);
  });

  testWidgets('an empty list says there is nothing to buy', (tester) async {
    await pump(tester, books: [_book(1, 'Besitz')], series: _Series([]));

    expect(find.textContaining('Nichts zu kaufen'), findsOneWidget);
  });

  testWidgets('copy puts the list on the clipboard as text', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(
      tester,
      books: [
        _book(1, 'Wunschbuch', status: BookStatus.wishlist),
        _book(2, 'Band 1', seriesId: 1, volume: 1),
      ],
      series: _Series([
        const Series(id: 1, name: 'Krimi-Reihe', totalPlannedVolumes: 3),
      ]),
    );

    await tester.tap(find.byKey(const ValueKey('shopping-copy')));
    await tester.pumpAndSettle();

    expect(
      copied,
      'Wunschliste\n'
      '• Wunschbuch – Autorin\n'
      '\n'
      'Fehlende Bände\n'
      '• Krimi-Reihe: Bände 2, 3 fehlen',
    );
    expect(find.text('In die Zwischenablage kopiert'), findsOneWidget);
  });

  testWidgets('a series without length can be given one', (tester) async {
    final series = _Series([const Series(id: 7, name: 'Offene Reihe')]);
    await pump(
      tester,
      books: [_book(1, 'Band 1', seriesId: 7, volume: 1)],
      series: series,
    );

    await tester.tap(find.byKey(const ValueKey('shopping-open-7')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('shopping-length')), '4');
    await tester.pump();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(series.totals[7], 4);
    expect(find.text('Offene Reihe: Bände 2, 3, 4 fehlen'), findsOneWidget);
  });
}
