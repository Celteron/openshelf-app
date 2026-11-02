import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:openreads/data/cover/spine_color_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/spine_color.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/locations/shelf_wall_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _Books implements BookRepository {
  final BehaviorSubject<List<Book>> _books;
  final moves = <String>[];
  Object? moveError;

  _Books(List<Book> books) : _books = BehaviorSubject.seeded(books);

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => _books.stream;

  /// Like the database: the change comes back through the stream.
  @override
  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId) async {
    if (moveError != null) throw moveError!;
    moves.add('${bookIds.join(',')}->$locationId');
    _books.add([
      for (final b in _books.value)
        bookIds.contains(b.id) ? b.copyWith(locationId: Value(locationId)) : b,
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Locations implements LocationRepository {
  final List<Location> locations;
  _Locations(this.locations);

  @override
  Stream<List<Location>> watchLocations() => Stream.value(locations);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Colors extends SpineColorService {
  final asked = <String>[];
  int? color = 0xFF2244AA;

  @override
  Future<int?> colorFor(String path) async {
    asked.add(path);
    return color;
  }
}

Book book(
  int id,
  String title, {
  int? location,
  int? pages,
  int? parent,
  String? cover,
}) => Book(
  id: id,
  title: title,
  authors: const ['Autorin'],
  status: BookStatus.unread,
  rating: 0,
  pageCount: pages,
  locationId: location,
  coverLocalPath: cover,
  parentId: parent,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const room = Location(
  id: 1,
  name: 'Wohnzimmer',
  type: LocationType.room,
  sortOrder: 0,
);
const slot = Location(
  id: 2,
  name: 'Fach 1',
  type: LocationType.compartment,
  parentId: 1,
  sortOrder: 0,
);

void main() {
  final opened = <int>[];
  late _Books repo;

  Future<void> pump(
    WidgetTester tester,
    List<Book> books, {
    List<Location> locations = const [room, slot],
    SpineColorService? colors,
  }) async {
    opened.clear();
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BookRepository>.value(value: repo = _Books(books)),
          RepositoryProvider<LocationRepository>.value(
            value: _Locations(locations),
          ),
          if (colors != null)
            RepositoryProvider<SpineColorService>.value(value: colors),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShelfWallScreen(onOpenBook: opened.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the compartment with its path and its spines', (
    tester,
  ) async {
    await pump(tester, [book(1, 'Der Vorleser', location: 2, pages: 200)]);

    expect(find.text('Wohnzimmer › Fach 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('spine-1')), findsOneWidget);
    expect(find.text('Der Vorleser'), findsOneWidget);
  });

  testWidgets('an empty compartment says so', (tester) async {
    await pump(tester, const []);

    expect(find.text('Leer'), findsOneWidget);
  });

  testWidgets('books without a location sit in their own row', (tester) async {
    await pump(tester, [book(1, 'Lose', location: null)]);

    expect(find.text('Ohne Standort'), findsOneWidget);
    expect(find.byKey(const ValueKey('spine-1')), findsOneWidget);
  });

  testWidgets('tapping a spine opens the book', (tester) async {
    await pump(tester, [book(7, 'Der Vorleser', location: 2)]);

    await tester.tap(find.byKey(const ValueKey('spine-7')));

    expect(opened, [7]);
  });

  testWidgets('a slipcase shows how many volumes it holds', (tester) async {
    await pump(tester, [
      book(1, 'Schuber', location: 2),
      book(2, 'Band 1', location: 2, parent: 1),
      book(3, 'Band 2', location: 2, parent: 1),
    ]);

    expect(find.text('2 Bände'), findsOneWidget);
    expect(find.byKey(const ValueKey('spine-2')), findsNothing);
  });

  testWidgets('each spine has a label and meets the tap target size', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, [book(1, 'Der Vorleser', location: 2, pages: 207)]);

    expect(
      find.bySemanticsLabel('Der Vorleser, Autorin, 207 Seiten'),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('the location management stays reachable', (tester) async {
    await pump(tester, const []);

    expect(find.byKey(const ValueKey('shelf-manage')), findsOneWidget);
  });

  group('cover colours', () {
    Color? colorOf(WidgetTester tester, int id) =>
        tester.widget<Material>(find.byKey(ValueKey('spine-$id'))).color;

    testWidgets('a spine takes the colour of its cover', (tester) async {
      final colors = _Colors();
      await pump(tester, [
        book(1, 'A', location: 2, cover: '/c/a.jpg'),
      ], colors: colors);

      expect(colors.asked, ['/c/a.jpg']);
      expect(colorOf(tester, 1), const Color(0xFF2244AA));
    });

    testWidgets('without a cover the title decides, and nobody is asked', (
      tester,
    ) async {
      final colors = _Colors();
      await pump(tester, [
        book(1, 'Der Vorleser', location: 2),
      ], colors: colors);

      expect(colors.asked, isEmpty);
      expect(colorOf(tester, 1), Color(placeholderSpineColor('Der Vorleser')));
    });

    testWidgets('a cover without a usable colour falls back to the title', (
      tester,
    ) async {
      final colors = _Colors()..color = null;
      await pump(tester, [
        book(1, 'Weiß', location: 2, cover: '/c/w.jpg'),
      ], colors: colors);

      expect(colorOf(tester, 1), Color(placeholderSpineColor('Weiß')));
    });

    testWidgets('the title stays readable on a bright cover colour', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final colors = _Colors()..color = 0xFFFFD54F;
      await pump(tester, [
        book(1, 'Gelb', location: 2, cover: '/c/y.jpg'),
      ], colors: colors);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('find it', () {
    final books = [
      book(1, 'Roman A', location: 2, pages: 200),
      book(2, 'Gedichte', location: 2, pages: 200),
      book(3, 'Roman B', location: 2, pages: 200),
    ];

    Future<void> search(WidgetTester tester, String text) async {
      await tester.tap(find.byKey(const ValueKey('shelf-find')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('shelf-find-field')),
        text,
      );
      await tester.pumpAndSettle();
    }

    Color? colorOf(WidgetTester tester, int id) =>
        tester.widget<Material>(find.byKey(ValueKey('spine-$id'))).color;

    testWidgets('typing marks the hits and counts them', (tester) async {
      await pump(tester, books);

      await search(tester, 'roman');

      expect(find.text('1 von 2'), findsOneWidget);
    });

    testWidgets('books that do not match are dimmed', (tester) async {
      await pump(tester, books);
      final before = colorOf(tester, 2);

      await search(tester, 'roman');

      expect(colorOf(tester, 2), isNot(before), reason: 'dimmed');
      expect(colorOf(tester, 1), Color(placeholderSpineColor('Roman A')));
    });

    testWidgets('next steps through the hits', (tester) async {
      await pump(tester, books);
      await search(tester, 'roman');

      await tester.tap(find.byKey(const ValueKey('shelf-find-next')));
      await tester.pumpAndSettle();
      expect(find.text('2 von 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('shelf-find-next')));
      await tester.pumpAndSettle();
      expect(find.text('1 von 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('shelf-find-previous')));
      await tester.pumpAndSettle();
      expect(find.text('2 von 2'), findsOneWidget);
    });

    testWidgets('no hit says so', (tester) async {
      await pump(tester, books);

      await search(tester, 'xyz');

      expect(find.text('Nichts gefunden'), findsOneWidget);
    });

    testWidgets('closing the search brings the colours back', (tester) async {
      await pump(tester, books);
      final before = colorOf(tester, 2);
      await search(tester, 'roman');

      await tester.tap(find.byKey(const ValueKey('shelf-find-close')));
      await tester.pumpAndSettle();

      expect(colorOf(tester, 2), before);
      expect(find.byKey(const ValueKey('shelf-find')), findsOneWidget);
    });

    testWidgets('the wall scrolls to a hit far down', (tester) async {
      final many = [
        for (var i = 0; i < 20; i++)
          Location(
            id: 100 + i,
            name: 'Fach $i',
            type: LocationType.compartment,
            sortOrder: i,
          ),
      ];
      await pump(tester, [
        for (var i = 0; i < 20; i++)
          book(
            10 + i,
            i == 19 ? 'Gesuchtes Buch' : 'Buch $i',
            location: 100 + i,
          ),
      ], locations: many);
      expect(
        find.byKey(const ValueKey('spine-29')).hitTestable(),
        findsNothing,
      );

      await search(tester, 'gesucht');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spine-29')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('the search controls meet the tap target size', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, books);
      await search(tester, 'roman');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('moving a book', () {
    const slot2 = Location(
      id: 3,
      name: 'Fach 2',
      type: LocationType.compartment,
      parentId: 1,
      sortOrder: 1,
    );
    final books = [book(1, 'Der Vorleser', location: 2, pages: 200)];

    Future<void> openPicker(WidgetTester tester, int id) async {
      await tester.tap(
        find.byKey(ValueKey('spine-$id')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the picker lists the other places and moves the book', (
      tester,
    ) async {
      await pump(tester, books, locations: const [room, slot, slot2]);

      await openPicker(tester, 1);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Wohnzimmer › Fach 1'),
        ),
        findsNothing,
        reason: 'the book is there already',
      );
      await tester.tap(find.text('Wohnzimmer › Fach 2').last);
      await tester.pumpAndSettle();

      expect(repo.moves, ['1->3']);
      expect(find.text('Verschoben nach Wohnzimmer › Fach 2'), findsOneWidget);
    });

    testWidgets('"no location" is always an option', (tester) async {
      await pump(tester, books, locations: const [room, slot, slot2]);

      await openPicker(tester, 1);
      await tester.tap(find.text('Ohne Standort').last);
      await tester.pumpAndSettle();

      expect(repo.moves, ['1->null']);
    });

    testWidgets('undo puts the book back', (tester) async {
      await pump(tester, books, locations: const [room, slot, slot2]);
      await openPicker(tester, 1);
      await tester.tap(find.text('Wohnzimmer › Fach 2').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();

      expect(repo.moves, ['1->3', '1->2']);
    });

    testWidgets('a failing save says so', (tester) async {
      await pump(tester, books, locations: const [room, slot, slot2]);
      repo.moveError = StateError('db');

      await openPicker(tester, 1);
      await tester.tap(find.text('Wohnzimmer › Fach 2').last);
      await tester.pumpAndSettle();

      expect(find.text('Verschieben fehlgeschlagen'), findsOneWidget);
    });

    testWidgets('a screen reader gets the same action', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, books, locations: const [room, slot, slot2]);

      final data = tester
          .getSemantics(find.byKey(const ValueKey('spine-1')))
          .getSemanticsData();
      final labels = [
        for (final id in data.customSemanticsActionIds ?? <int>[])
          CustomSemanticsAction.getAction(id)?.label,
      ];

      expect(labels, contains('Verschieben nach …'));
      handle.dispose();
    });

    testWidgets('dragging a spine onto another row moves it', (tester) async {
      await pump(tester, books, locations: const [room, slot, slot2]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('spine-1'))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final second = tester.getCenter(find.text('Leer'));
      await gesture.moveTo(second);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repo.moves, ['1->3']);
    });

    testWidgets('dropping it back on its own row does nothing', (tester) async {
      await pump(tester, books, locations: const [room, slot, slot2]);

      final start = tester.getCenter(find.byKey(const ValueKey('spine-1')));
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(start + const Offset(120, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repo.moves, isEmpty);
    });
  });

  group('slipcases', () {
    final slipcase = [
      book(1, 'Schuber', location: 2),
      book(2, 'Band 1', location: 2, parent: 1, pages: 300),
      book(3, 'Band 2', location: 2, parent: 1, pages: 300),
    ];

    testWidgets('tapping a slipcase opens it onto its volumes', (tester) async {
      await pump(tester, slipcase);
      expect(find.byKey(const ValueKey('spine-2')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('spine-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('spine-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('spine-3')), findsOneWidget);
      expect(
        opened,
        isEmpty,
        reason: 'tap opens the case, not the detail page',
      );
    });

    testWidgets('tapping again closes it', (tester) async {
      await pump(tester, slipcase);
      await tester.tap(find.byKey(const ValueKey('spine-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('spine-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('spine-2')), findsNothing);
    });

    testWidgets('a volume opens its own page', (tester) async {
      await pump(tester, slipcase);
      await tester.tap(find.byKey(const ValueKey('spine-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('spine-3')));

      expect(opened, [3]);
    });

    testWidgets('the slipcase itself stays reachable while open', (
      tester,
    ) async {
      await pump(tester, slipcase);
      await tester.tap(find.byKey(const ValueKey('spine-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('slipcase-open-1')));

      expect(opened, [1]);
    });

    testWidgets('a volume cannot be moved away from its slipcase', (
      tester,
    ) async {
      await pump(tester, slipcase, locations: const [room, slot]);
      await tester.tap(find.byKey(const ValueKey('spine-1')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('spine-2')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('finding a volume opens its slipcase', (tester) async {
      await pump(tester, slipcase);

      await tester.tap(find.byKey(const ValueKey('shelf-find')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('shelf-find-field')),
        'band 2',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('spine-3')), findsOneWidget);
    });
  });
}
