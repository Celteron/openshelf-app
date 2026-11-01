import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/domain/services/cover_sync_service.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/settings/settings_screen.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/features/trash/trash_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/fake_settings_repository.dart';
import '../helpers/test_images.dart';

class _Tags implements TagRepository {
  @override
  Stream<List<TagWithCount>> watchTags() => Stream.value([
    const TagWithCount(Tag(id: 1, name: 'Krimi'), 2),
    const TagWithCount(Tag(id: 2, name: 'Klassiker'), 1),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Books implements BookRepository {
  final List<Book> books;
  final paths = <int, String?>{};
  _Books([this.books = const []]);

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  Future<void> setCoverLocalPath(int id, String? path) async =>
      paths[id] = path;

  @override
  Stream<List<Book>> watchTrashedBooks() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late FakeSettingsRepository repo;
  late Directory dir;

  setUp(() {
    repo = FakeSettingsRepository();
    dir = Directory.systemTemp.createTempSync('settings_screen_test');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<SettingsCubit> pump(
    WidgetTester tester, {
    _Books? books,
    String? bakedKey,
  }) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = SettingsCubit(repo, defaultGoogleBooksApiKey: bakedKey);
    await settings.load();
    addTearDown(settings.close);
    final tags = TagsCubit(_Tags())..load();
    addTearDown(tags.close);
    final bookRepo = books ?? _Books();
    final cache = CoverCacheService(
      baseDirectory: dir,
      client: MockClient(
        (_) async => http.Response.bytes(
          testPng(),
          200,
          headers: {'content-type': 'image/png'},
        ),
      ),
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: CoverSyncService(bookRepo, cache)),
          RepositoryProvider<BookRepository>.value(value: bookRepo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settings),
            BlocProvider.value(value: tags),
            BlocProvider(create: (_) => TrashCubit(bookRepo)),
          ],
          child: const MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('shows the licence as GPL-2.0 and the credits', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('GPL-2.0'), 300);
    expect(find.text('GPL-2.0'), findsOneWidget);
    expect(find.text('Flutter, Drift, BLoC'), findsOneWidget);
    expect(find.text('Quellcode'), findsOneWidget);
    expect(find.text('Fehler melden'), findsOneWidget);
  });

  group('appearance', () {
    testWidgets('the theme mode radios update the setting', (tester) async {
      final cubit = await pump(tester);

      await tester.tap(find.text('Dunkel'));
      await tester.pumpAndSettle();

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(repo.theme, 'dark');
    });

    testWidgets(
      'the Material You switch is stored and disables the accent colour',
      (tester) async {
        final cubit = await pump(tester);
        ListTile accent() =>
            tester.widget<ListTile>(find.byKey(const ValueKey('accent-color')));
        expect(accent().enabled, isTrue);

        await tester.tap(find.byKey(const ValueKey('material-you')));
        await tester.pumpAndSettle();

        expect(cubit.state.materialYou, isTrue);
        expect(repo.values['materialYou'], 'true');
        expect(accent().enabled, isFalse);
        expect(find.text('Bei Material You nicht verfügbar'), findsOneWidget);
      },
    );

    testWidgets('the AMOLED switch is stored', (tester) async {
      final cubit = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('amoled')));
      await tester.pumpAndSettle();

      expect(cubit.state.amoled, isTrue);
      expect(repo.values['amoled'], 'true');
    });

    testWidgets('the accent colour opens a picker and can be reset', (
      tester,
    ) async {
      final cubit = await pump(tester);
      expect(find.byTooltip('Zurücksetzen'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('accent-color')));
      await tester.pumpAndSettle();
      expect(find.text('Eigene Farbe'), findsOneWidget);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(cubit.state.accentColor, isNotNull);

      await tester.tap(find.byTooltip('Zurücksetzen'));
      await tester.pumpAndSettle();
      expect(cubit.state.accentColor, isNull);
    });

    testWidgets('cancelling the colour dialog changes nothing', (tester) async {
      final cubit = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('accent-color')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(cubit.state.accentColor, isNull);
    });

    testWidgets('the font dialog offers all fonts and stores the choice', (
      tester,
    ) async {
      final cubit = await pump(tester);
      expect(find.text('Standard'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('font-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('font:default')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('font:Lora')));
      await tester.pumpAndSettle();

      expect(cubit.state.fontFamily, 'Lora');
      expect(
        find.text('Lora'),
        findsOneWidget,
        reason: 'shown as the current font',
      );

      await tester.tap(find.byKey(const ValueKey('font-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('font:default')));
      await tester.pumpAndSettle();
      expect(cubit.state.fontFamily, isNull);
    });

    testWidgets('the rating style can be switched to a number', (tester) async {
      final cubit = await pump(tester);

      await tester.tap(find.text('Zahl'));
      await tester.pumpAndSettle();

      expect(cubit.state.ratingDisplay, RatingDisplay.number);
      expect(repo.values['ratingDisplay'], 'number');
    });

    testWidgets('all four library layouts can be chosen', (tester) async {
      final cubit = await pump(tester);

      for (final (type, label) in [
        (LibraryDisplayType.compactList, 'Kompakte Liste'),
        (LibraryDisplayType.grid, 'Raster'),
        (LibraryDisplayType.detailedGrid, 'Detailliertes Raster'),
        (LibraryDisplayType.list, 'Liste'),
      ]) {
        await tester.tap(find.byKey(ValueKey('display:${type.name}')));
        await tester.pumpAndSettle();
        expect(cubit.state.displayType, type, reason: label);
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('Google Books API key', () {
    Future<void> openKeyDialog(WidgetTester tester) async {
      final tile = find.byKey(const ValueKey('google-books-key'));
      await tester.scrollUntilVisible(tile, 300);
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('a key can be entered and is shown shortened', (tester) async {
      final cubit = await pump(tester);
      expect(find.text('Nicht gesetzt (gemeinsames Kontingent)'), findsOne);

      await openKeyDialog(tester);
      await tester.enterText(
        find.byKey(const ValueKey('google-key-field')),
        'AbCdEf123456',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(cubit.state.googleBooksApiKey, 'AbCdEf123456');
      expect(repo.values['googleBooksApiKey'], 'AbCdEf123456');
      expect(find.text('Gesetzt (…3456)'), findsOneWidget);
      expect(find.textContaining('AbCdEf'), findsNothing);
    });

    testWidgets('the baked-in key is used and can be restored', (tester) async {
      final cubit = await pump(tester, bakedKey: 'baked-9876');
      expect(find.text('Gesetzt (…9876)'), findsOneWidget);

      await openKeyDialog(tester);
      await tester.enterText(
        find.byKey(const ValueKey('google-key-field')),
        '',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(cubit.state.googleBooksApiKey, isNull);

      await openKeyDialog(tester);
      await tester.tap(find.text('Zurücksetzen'));
      await tester.pumpAndSettle();
      expect(cubit.state.googleBooksApiKey, 'baked-9876');
    });

    testWidgets('the key is hidden until the eye is tapped', (tester) async {
      await pump(tester, bakedKey: 'baked-9876');
      await openKeyDialog(tester);

      EditableText field() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('google-key-field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field().obscureText, isTrue);

      await tester.tap(find.byKey(const ValueKey('google-key-visibility')));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });

    testWidgets('cancelling keeps the key', (tester) async {
      final cubit = await pump(tester, bakedKey: 'baked-9876');

      await openKeyDialog(tester);
      await tester.enterText(
        find.byKey(const ValueKey('google-key-field')),
        'other',
      );
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(cubit.state.googleBooksApiKey, 'baked-9876');
    });
  });

  group('books', () {
    testWidgets('default format and status are stored', (tester) async {
      final cubit = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('default-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('hardcover').last);
      await tester.pumpAndSettle();
      expect(cubit.state.defaultFormat, BookFormat.hardcover);

      await tester.tap(find.byKey(const ValueKey('default-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wunschliste').last);
      await tester.pumpAndSettle();
      expect(cubit.state.defaultStatus, BookStatus.wishlist);
    });

    testWidgets('default tags are chosen from the existing tags', (
      tester,
    ) async {
      final cubit = await pump(tester);
      expect(find.text('Keine für neue Bücher'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('default-tags')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('default-tag:2')));
      await tester.tap(find.byKey(const ValueKey('default-tag:1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(cubit.state.defaultTagIds, {1, 2});
      expect(find.text('2 Tags für neue Bücher'), findsOneWidget);

      // Untick one again.
      await tester.tap(find.byKey(const ValueKey('default-tags')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('default-tag:1')));
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(cubit.state.defaultTagIds, {2});
    });

    testWidgets('the trash entry opens the trash', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('open-trash')));
      await tester.pumpAndSettle();

      expect(find.text('Der Papierkorb ist leer'), findsOneWidget);
    });
  });

  group('covers', () {
    Book needsCover(int id, {String? isbn}) => Book(
      id: id,
      title: 'B$id',
      authors: const ['A'],
      status: BookStatus.unread,
      rating: 0,
      isbn13: isbn,
      coverUrl: 'https://x/$id.png',
      editedFields: const [],
      currentPage: 0,
      isFavorite: false,
      coverNotFound: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    testWidgets('reports when none are missing', (tester) async {
      await pump(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('download-covers')));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      expect(find.text('Es fehlen keine Cover'), findsOneWidget);
    });

    testWidgets('downloads the missing ones and says how many', (tester) async {
      final books = _Books([
        needsCover(1, isbn: '9783000000301'),
        needsCover(2),
      ]);
      await pump(tester, books: books);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('download-covers')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(
        find.text('2 Cover geladen, 0 ohne Online-Cover, 0 nicht erreichbar'),
        findsOneWidget,
      );
      expect(books.paths.keys, unorderedEquals([1, 2]));
    });
  });
}
