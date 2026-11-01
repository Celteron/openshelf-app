import 'dart:async';

import 'package:drift/drift.dart' show Value;
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
import 'package:openreads/features/library/widgets/book_grid_tile.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/library/library_screen.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/fake_settings_repository.dart';

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

  final trashed = <int>[];
  final formatChanges = <(List<int>, BookFormat)>[];
  final authorChanges = <(List<int>, List<String>)>[];

  @override
  Future<void> deleteBooks(List<int> ids) async {
    trashed.addAll(ids);
    books.removeWhere((b) => ids.contains(b.id));
    _changes.add(null);
  }

  @override
  Future<void> bulkSetFormat(List<int> bookIds, BookFormat format) async {
    formatChanges.add((bookIds, format));
    for (final id in bookIds) {
      final i = books.indexWhere((b) => b.id == id);
      books[i] = books[i].copyWith(format: Value(format));
    }
    _changes.add(null);
  }

  @override
  Future<void> bulkSetAuthors(List<int> bookIds, List<String> authors) async {
    authorChanges.add((bookIds, authors));
    for (final id in bookIds) {
      final i = books.indexWhere((b) => b.id == id);
      books[i] = books[i].copyWith(authors: authors);
    }
    _changes.add(null);
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
  DateTime? createdAt,
}) => Book(
  id: id,
  title: title,
  authors: const ['Autor'],
  status: status,
  rating: rating,
  editedFields: const [],
  currentPage: 0,
  isFavorite: favorite,
  coverNotFound: false,
  createdAt: createdAt ?? DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<FakeBookRepository> pumpLibrary(
  WidgetTester tester, {
  List<Book>? seed,
  FakeSettingsRepository? settings,
  List<Tag> tagList = const [Tag(id: 1, name: 'Krimi')],
}) async {
  final books = FakeBookRepository(
    seed ??
        [
          book(1, 'Alpha', BookStatus.read),
          book(2, 'Beta', BookStatus.read),
          book(3, 'Wunsch', BookStatus.wishlist),
        ],
  );
  final tags = FakeTagRepository(tagList, {
    1: {1},
  });
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LibraryCubit(books, tagRepository: tags)),
        BlocProvider(create: (_) => TagsCubit(tags)..load()),
        BlocProvider(
          create: (_) =>
              SettingsCubit(settings ?? FakeSettingsRepository())..load(),
        ),
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
  group('tag filter', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tag-filter')));
      await tester.pumpAndSettle();
    }

    Future<void> closeSheet(WidgetTester tester) async {
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }

    testWidgets('picking a tag in the sheet narrows the list', (tester) async {
      await pumpLibrary(tester);
      expect(find.text('Beta'), findsOneWidget);

      await openSheet(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Krimi'));
      await tester.pumpAndSettle();
      await closeSheet(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      expect(find.text('Wunsch'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tag-filter')),
          matching: find.text('Tags (1)'),
        ),
        findsOneWidget,
        reason: 'the chip shows how many tags are active',
      );
    });

    testWidgets('an active tag shows above the list and can be removed', (
      tester,
    ) async {
      await pumpLibrary(tester);
      expect(find.byType(InputChip), findsNothing, reason: 'no empty row');

      await openSheet(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Krimi'));
      await tester.pumpAndSettle();
      await closeSheet(tester);

      final active = find.widgetWithText(InputChip, 'Krimi');
      expect(active, findsOneWidget);
      await tester.tap(
        find.descendant(of: active, matching: find.byIcon(Icons.close)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('the search narrows the tags in the sheet', (tester) async {
      await pumpLibrary(
        tester,
        tagList: const [
          Tag(id: 1, name: 'Krimi'),
          Tag(id: 2, name: 'Fantasy'),
          Tag(id: 3, name: 'Kriegsroman'),
        ],
      );
      await openSheet(tester);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(FilterChip),
        ),
        findsNWidgets(3),
      );

      await tester.enterText(find.byKey(const ValueKey('tag-search')), 'kri');
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      FinderBase<Element> chip(String name) => find.descendant(
        of: sheet,
        matching: find.widgetWithText(FilterChip, name),
      );
      expect(chip('Krimi'), findsOneWidget);
      expect(chip('Kriegsroman'), findsOneWidget);
      expect(chip('Fantasy'), findsNothing);
    });

    testWidgets('"clear selection" drops every active tag', (tester) async {
      await pumpLibrary(tester);
      await openSheet(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Krimi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auswahl aufheben'));
      await tester.pumpAndSettle();
      await closeSheet(tester);

      expect(find.byType(InputChip), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('without tags there is no tag filter', (tester) async {
      await pumpLibrary(tester, tagList: const []);

      expect(find.byKey(const ValueKey('tag-filter')), findsNothing);
    });
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

    testWidgets('offers all twelve sort fields', (tester) async {
      await pumpLibrary(tester);
      await tester.tap(find.byKey(const ValueKey('sort-menu')));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuItem<LibrarySortField>), findsNWidgets(12));
      for (final label in [
        'Titel',
        'Autor',
        'Bewertung',
        'Hinzugefügt am',
        'Geändert am',
        'Lese-Fortschritt',
        'Seitenzahl',
        'Erscheinungsjahr',
        'Status',
        'Zuletzt gelesen',
        'Lesebeginn',
        'Leseende',
      ]) {
        expect(menuItem(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('starts sorted by title and flips direction on a pick', (
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
      expect(shownTitles(tester), ['Alpha', 'Beta', 'Gamma']);

      await pick(tester, 'Titel');
      expect(shownTitles(tester), ['Gamma', 'Beta', 'Alpha']);

      await pick(tester, 'Titel');
      expect(shownTitles(tester), ['Alpha', 'Beta', 'Gamma']);
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

  group('layout', () {
    testWidgets('the toggle switches between list and grid and remembers it', (
      tester,
    ) async {
      final settings = FakeSettingsRepository();
      await pumpLibrary(tester, settings: settings);
      expect(find.byKey(const ValueKey('book-list')), findsOneWidget);
      expect(find.byType(BookListTile), findsNWidgets(3));
      expect(find.byTooltip('Rasteransicht'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('view-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('book-grid')), findsOneWidget);
      expect(find.byType(BookGridTile), findsNWidgets(3));
      expect(find.byType(BookListTile), findsNothing);
      expect(find.byTooltip('Listenansicht'), findsOneWidget);
      expect(settings.values['displayType'], 'grid');

      await tester.tap(find.byKey(const ValueKey('view-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('book-list')), findsOneWidget);
      expect(settings.values['displayType'], 'list');
    });

    testWidgets('a stored compact list is restored', (tester) async {
      final settings = FakeSettingsRepository()
        ..values['displayType'] = 'compactList';
      await pumpLibrary(tester, settings: settings);

      final tiles = tester.widgetList<BookListTile>(find.byType(BookListTile));
      expect(tiles, hasLength(3));
      expect(tiles.every((t) => t.compact), isTrue);
    });

    testWidgets('a stored detailed grid shows titles below the covers', (
      tester,
    ) async {
      final settings = FakeSettingsRepository()
        ..values['displayType'] = 'detailedGrid';
      await pumpLibrary(tester, settings: settings);

      final tiles = tester.widgetList<BookGridTile>(find.byType(BookGridTile));
      expect(tiles, hasLength(3));
      expect(tiles.every((t) => t.detailed), isTrue);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('grid tiles open and select like list tiles', (tester) async {
      final settings = FakeSettingsRepository()..values['displayType'] = 'grid';
      await pumpLibrary(tester, settings: settings);

      await tester.longPress(find.byKey(const ValueKey('book-tile:1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('grid-selected')), findsOneWidget);
      expect(find.text('1 ausgewählt'), findsOneWidget);
    });
  });

  group('year filter', () {
    testWidgets('lists the years with finished books and filters by one', (
      tester,
    ) async {
      await pumpLibrary(
        tester,
        seed: [
          book(1, 'Alt', BookStatus.read, createdAt: DateTime(2024, 5)),
          book(2, 'Neu', BookStatus.read, createdAt: DateTime(2026, 2)),
          book(3, 'Offen', BookStatus.unread, createdAt: DateTime(2023)),
        ],
      );
      expect(find.byKey(const ValueKey('year-filter')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('year-filter')));
      await tester.pumpAndSettle();
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2023'), findsNothing, reason: 'unread, not finished');

      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();
      expect(find.text('Alt'), findsOneWidget);
      expect(find.text('Neu'), findsNothing);
      expect(find.text('Offen'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('year-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alle Jahre'));
      await tester.pumpAndSettle();
      expect(find.text('Neu'), findsOneWidget);
    });

    testWidgets('hidden when no book is finished', (tester) async {
      await pumpLibrary(tester, seed: [book(1, 'Offen', BookStatus.unread)]);
      expect(find.byKey(const ValueKey('year-filter')), findsNothing);
    });
  });

  group('multi-select bulk edit', () {
    Future<void> select(WidgetTester tester, int id) async {
      await tester.longPress(find.byKey(ValueKey('book-tile:$id')));
      await tester.pumpAndSettle();
    }

    testWidgets('offers location, format, author and trash actions', (
      tester,
    ) async {
      await pumpLibrary(tester);
      await select(tester, 1);

      for (final key in [
        'bulk-location',
        'bulk-format',
        'bulk-author',
        'bulk-delete',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    });

    testWidgets('moves the selected books to the trash after confirming', (
      tester,
    ) async {
      final repo = await pumpLibrary(tester);
      await select(tester, 1);
      await tester.tap(find.byKey(const ValueKey('book-tile:2')));
      await tester.pumpAndSettle();
      expect(find.text('2 ausgewählt'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bulk-delete')));
      await tester.pumpAndSettle();
      expect(find.text('2 Bücher in den Papierkorb?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
      await tester.pumpAndSettle();

      expect(repo.trashed, unorderedEquals([1, 2]));
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);
      expect(find.text('Wunsch'), findsOneWidget);
      expect(find.text('2 Bücher im Papierkorb'), findsOneWidget);
    });

    testWidgets('cancelling the trash dialog keeps everything', (tester) async {
      final repo = await pumpLibrary(tester);
      await select(tester, 1);
      await tester.tap(find.byKey(const ValueKey('bulk-delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen').last);
      await tester.pumpAndSettle();

      expect(repo.trashed, isEmpty);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('changes the format of the selected books', (tester) async {
      final repo = await pumpLibrary(tester);
      await select(tester, 1);
      await tester.tap(find.byKey(const ValueKey('bulk-format')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('hardcover'));
      await tester.pumpAndSettle();

      expect(repo.formatChanges, hasLength(1));
      expect(repo.formatChanges.single.$1, [1]);
      expect(repo.formatChanges.single.$2, BookFormat.hardcover);
    });

    testWidgets('changes the author of the selected books', (tester) async {
      final repo = await pumpLibrary(tester);
      await select(tester, 2);
      await tester.tap(find.byKey(const ValueKey('bulk-author')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('bulk-author-field')),
        'Jane Doe, John Roe',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(repo.authorChanges.single.$1, [2]);
      expect(repo.authorChanges.single.$2, ['Jane Doe', 'John Roe']);
    });
  });

  testWidgets('select all picks every shown book and can trash them', (
    tester,
  ) async {
    final books = await pumpLibrary(tester);

    expect(find.byKey(const ValueKey('select-all')), findsNothing);
    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('1 ausgewählt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('select-all')));
    await tester.pumpAndSettle();
    expect(find.text('3 ausgewählt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bulk-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
    await tester.pumpAndSettle();

    expect(books.trashed, unorderedEquals([1, 2, 3]));
  });

  testWidgets('select all only takes the books of the active filter', (
    tester,
  ) async {
    await pumpLibrary(tester);
    final chip = find.widgetWithText(FilterChip, 'Wunschliste');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Wunsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-all')));
    await tester.pumpAndSettle();

    expect(find.text('1 ausgewählt'), findsOneWidget);
  });

  testWidgets('a filter change drops selected books that are now hidden', (
    tester,
  ) async {
    final books = await pumpLibrary(tester);
    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-all')));
    await tester.pumpAndSettle();
    expect(find.text('3 ausgewählt'), findsOneWidget);

    final chip = find.widgetWithText(FilterChip, 'Wunschliste');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('1 ausgewählt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bulk-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
    await tester.pumpAndSettle();

    expect(books.trashed, [3], reason: 'hidden books are never touched');
  });

  group('slipcases (ADR-0003)', () {
    final seed = [
      book(1, 'Alpha', BookStatus.unread),
      book(10, 'Schuber', BookStatus.unread),
      book(
        11,
        'Band Eins',
        BookStatus.read,
      ).copyWith(parentId: const Value(10)),
      book(
        12,
        'Band Zwei',
        BookStatus.unread,
      ).copyWith(parentId: const Value(10)),
    ];

    testWidgets('a slipcase is one entry that expands to its volumes', (
      tester,
    ) async {
      await pumpLibrary(tester, seed: [...seed]);

      expect(find.byKey(const ValueKey('book-tile:10')), findsOneWidget);
      expect(find.byKey(const ValueKey('book-tile:11')), findsNothing);
      expect(find.text('2 Bände · 1 von 2 gelesen'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('expand:10')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('book-tile:11')), findsOneWidget);
      expect(find.byKey(const ValueKey('book-tile:12')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('expand:10')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('book-tile:11')), findsNothing);
    });

    testWidgets('the grid marks a slipcase with its volume count', (
      tester,
    ) async {
      final settings = FakeSettingsRepository()..values['displayType'] = 'grid';
      await pumpLibrary(tester, seed: [...seed], settings: settings);

      expect(find.byType(BookGridTile), findsNWidgets(2));
      expect(find.text('2 Bände'), findsOneWidget);
    });
  });
}
