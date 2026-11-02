import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/features/home/home_cubit.dart';
import 'package:openreads/features/home/home_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _Books implements BookRepository {
  final List<Book> books;
  _Books(this.books);

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => Stream.value(books);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book _book(int id, String title, BookStatus status, {bool favorite = false}) =>
    Book(
      id: id,
      title: title,
      authors: const ['A'],
      status: status,
      rating: 0,
      pageCount: 200,
      editedFields: const [],
      currentPage: 50,
      isFavorite: favorite,
      coverNotFound: false,
      createdAt: DateTime(2026, 1, id),
      updatedAt: DateTime(2026),
    );

/// The home tab (FR-R2-19).
void main() {
  Future<(LibraryCubit, List<int>)> pump(
    WidgetTester tester, {
    List<Book> more = const [],
  }) async {
    final repo = _Books([
      _book(1, 'Fertig', BookStatus.read, favorite: true),
      _book(2, 'Dabei', BookStatus.reading),
      _book(3, 'Stapel', BookStatus.unread),
      ...more,
    ]);
    final shown = <int>[];
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          // Owned by the tree: closing them in a tear-down hangs.
          BlocProvider(
            create: (_) => HomeCubit(repo, now: () => DateTime(2026, 6, 15)),
          ),
          BlocProvider(create: (_) => LibraryCubit(repo)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(onShowLibrary: () => shown.add(1)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final library = tester
        .element(find.byType(HomeScreen))
        .read<LibraryCubit>();
    return (library, shown);
  }

  testWidgets('shows the donut total, reading, recent and favourites', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('home-total')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('home-total'))).data,
      '3',
    );
    expect(find.byKey(const ValueKey('home-reading')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-recent')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-favourites')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-unread-trend')), findsOneWidget);
  });

  testWidgets('a segment opens the library filtered to its status', (
    tester,
  ) async {
    final (library, shown) = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('home-segment-unread')));
    await tester.pump();

    expect(shown, [1]);
    final state = library.state;
    expect(
      state is LibraryLoaded && state.statusFilter == BookStatus.unread,
      isTrue,
    );
  });

  testWidgets('the reading segment shows re-reads too, as it counts them', (
    tester,
  ) async {
    final (library, _) = await pump(
      tester,
      more: [_book(4, 'Nochmal', BookStatus.reReading)],
    );

    await tester.tap(find.byKey(const ValueKey('home-segment-reading')));
    await tester.pump();

    final state = library.state;
    expect(state is LibraryLoaded ? state.onlyIds : null, {2, 4});
  });
}
