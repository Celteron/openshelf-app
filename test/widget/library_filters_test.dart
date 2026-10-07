import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/library_screen.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// In-memory book store applying the same filters as the Drift DAO.
class FakeBookRepository implements BookRepository {
  final _changes = StreamController<void>.broadcast();
  final List<Book> books;

  FakeBookRepository(this.books);

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) async* {
    List<Book> current() => [
      for (final b in books)
        if ((status == null || b.status == status) &&
            (query == null ||
                query.isEmpty ||
                b.title.toLowerCase().contains(query.toLowerCase())))
          b,
    ];
    yield current();
    await for (final _ in _changes.stream) {
      yield current();
    }
  }

  @override
  Future<void> updateStatus(int id, BookStatus status) async {
    final index = books.indexWhere((b) => b.id == id);
    books[index] = books[index].copyWith(status: status);
    _changes.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeTagRepository implements TagRepository {
  final List<Tag> tags;
  final Map<int, Set<int>> bookTags;

  FakeTagRepository(this.tags, this.bookTags);

  @override
  Stream<List<TagWithCount>> watchTags() => Stream.value([
    for (final t in tags)
      TagWithCount(t, bookTags.values.where((s) => s.contains(t.id)).length),
  ]);

  @override
  Stream<Set<int>> watchBookIdsWithAllTags(Set<int> tagIds) => Stream.value({
    for (final e in bookTags.entries)
      if (e.value.containsAll(tagIds)) e.key,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book book(
  int id,
  String title,
  BookStatus status, {
  bool favorite = false,
  double rating = 0,
}) => Book(
  id: id,
  title: title,
  authors: const ['Autor'],
  status: status,
  rating: rating,
  editedFields: const [],
  currentPage: 0,
  isFavorite: favorite,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<FakeBookRepository> pumpLibrary(
  WidgetTester tester, {
  List<Book>? seed,
}) async {
  final books = FakeBookRepository(
    seed ??
        [
          book(1, 'Alpha', BookStatus.read),
          book(2, 'Beta', BookStatus.read),
          book(3, 'Wunsch', BookStatus.wishlist),
        ],
  );
  final tags = FakeTagRepository(
    [const Tag(id: 1, name: 'Krimi')],
    {
      1: {1},
    },
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LibraryCubit(books, tagRepository: tags)),
        BlocProvider(create: (_) => TagsCubit(tags)..load()),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LibraryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return books;
}

/// Wiring of the library list: tag chips, status chips and the wishlist →
/// library action (Phase 2, US-C / US-E). Query semantics against the real
/// database are covered by `library_cubit_test.dart`.
void main() {
  testWidgets('tag chips narrow the list and can be cleared', (tester) async {
    await pumpLibrary(tester);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Krimi'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Wunsch'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Krimi'));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('status chips use localized labels and filter', (tester) async {
    await pumpLibrary(tester);

    final wishlistChip = find.widgetWithText(FilterChip, 'Wunschliste');
    await tester.ensureVisible(wishlistChip);
    await tester.tap(wishlistChip);
    await tester.pumpAndSettle();

    expect(find.text('Wunsch'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('wishlist books can be moved into the library', (tester) async {
    final books = await pumpLibrary(tester);

    // Only the wishlist book offers the action.
    expect(find.byTooltip('In Bestand übernehmen'), findsOneWidget);

    await tester.tap(find.byTooltip('In Bestand übernehmen'));
    await tester.pumpAndSettle();

    expect(books.books.firstWhere((b) => b.id == 3).status, BookStatus.unread);
    expect(find.text('Zum Bestand hinzugefügt'), findsOneWidget);
    expect(find.byTooltip('In Bestand übernehmen'), findsNothing);
  });

  testWidgets('the favourites chip narrows the list to favourites', (
    tester,
  ) async {
    await pumpLibrary(
      tester,
      seed: [
        book(1, 'Alpha', BookStatus.read),
        book(2, 'Beta', BookStatus.read, favorite: true),
      ],
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget, reason: 'marker');

    await tester.tap(find.byKey(const ValueKey('favorites-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('favorites-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
  });

  group('sort menu', () {
    List<String> shownTitles(WidgetTester tester) => [
      for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
        (tile.title as Text).data!,
    ];

    // Scoped to the menu: 'Autor' is also the author text of every book.
    Finder menuItem(String label) => find.descendant(
      of: find.byType(PopupMenuItem<LibrarySortField>),
      matching: find.text(label),
    );

    Future<void> pick(WidgetTester tester, String label) async {
      await tester.tap(find.byKey(const ValueKey('sort-menu')));
      await tester.pumpAndSettle();
      await tester.tap(menuItem(label));
      await tester.pumpAndSettle();
    }

    testWidgets('offers all five sort fields', (tester) async {
      await pumpLibrary(tester);
      await tester.tap(find.byKey(const ValueKey('sort-menu')));
      await tester.pumpAndSettle();

      for (final label in [
        'Titel',
        'Autor',
        'Bewertung',
        'Hinzugefügt am',
        'Lese-Fortschritt',
      ]) {
        expect(menuItem(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('sorts by title and flips direction on a second pick', (
      tester,
    ) async {
      await pumpLibrary(
        tester,
        seed: [
          book(1, 'Beta', BookStatus.read),
          book(2, 'Gamma', BookStatus.read),
          book(3, 'Alpha', BookStatus.read),
        ],
      );

      await pick(tester, 'Titel');
      expect(shownTitles(tester), ['Alpha', 'Beta', 'Gamma']);

      await pick(tester, 'Titel');
      expect(shownTitles(tester), ['Gamma', 'Beta', 'Alpha']);
    });

    testWidgets('sorts by rating with the best book first', (tester) async {
      await pumpLibrary(
        tester,
        seed: [
          book(1, 'Mäßig', BookStatus.read, rating: 2),
          book(2, 'Top', BookStatus.read, rating: 5),
          book(3, 'Gut', BookStatus.read, rating: 4),
        ],
      );

      await pick(tester, 'Bewertung');
      expect(shownTitles(tester), ['Top', 'Gut', 'Mäßig']);
    });
  });
}
