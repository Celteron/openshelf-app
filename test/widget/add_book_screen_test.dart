import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/cover/cover_picker.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/features/library/add_book_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/metadata/metadata_cubit.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/fake_settings_repository.dart';
import '../helpers/test_images.dart';

class _Books implements BookRepository {
  final added = <BookDraft>[];
  final updated = <(int, BookDraft)>[];

  /// Makes saving fail, like a database that is out of date.
  Object? failWith;

  @override
  Future<int> addBook(BookDraft draft) async {
    if (failWith != null) throw failWith!;
    added.add(draft);
    return 77;
  }

  @override
  Future<void> updateBookDraft(int id, BookDraft draft) async =>
      updated.add((id, draft));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Locations implements LocationRepository {
  @override
  Future<List<Location>> getLocations() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Tags implements TagRepository {
  final assigned = <(int, Set<int>)>[];

  @override
  Future<void> setBookTags(int bookId, Set<int> tagIds) async =>
      assigned.add((bookId, tagIds));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Picker implements CoverPicker {
  Uint8List? next;
  Object? error;
  final requested = <CoverPickSource>[];

  @override
  Future<Uint8List?> pick(CoverPickSource source) async {
    requested.add(source);
    if (error != null) throw error!;
    return next;
  }
}

Book existing({
  String? coverUrl,
  String? coverLocalPath,
  String? genre,
  int? priceCents,
  DateTime? receivedAt,
  int? readingSeconds,
}) => Book(
  id: 5,
  title: 'Bestehend',
  authors: const ['Autorin'],
  status: BookStatus.read,
  rating: 3,
  seriesId: 9,
  olid: 'OL1M',
  genre: genre,
  priceCents: priceCents,
  receivedAt: receivedAt,
  readingSeconds: readingSeconds,
  coverUrl: coverUrl,
  coverLocalPath: coverLocalPath,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late Directory dir;
  late _Books books;
  late _Tags tags;
  late _Picker picker;
  late FakeSettingsRepository settings;
  late CoverCacheService cache;
  late http.Client olHttp;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('add_book_test');
    books = _Books();
    tags = _Tags();
    picker = _Picker();
    settings = FakeSettingsRepository();
    cache = CoverCacheService(
      baseDirectory: dir,
      client: MockClient((_) async => http.Response('x', 404)),
    );
    olHttp = MockClient((_) async => http.Response('{}', 404));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(
    WidgetTester tester, {
    Book? book,
    bool withPicker = true,
    MetadataAggregatorService aggregator = const MetadataAggregatorService([]),
  }) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The app loads the settings before it starts.
    final settingsCubit = SettingsCubit(settings);
    await settingsCubit.load();
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LocationRepository>.value(value: _Locations()),
          RepositoryProvider<TagRepository>.value(value: tags),
          RepositoryProvider<CoverCacheService>.value(value: cache),
          RepositoryProvider<OpenLibrarySearchClient>.value(
            value: OpenLibrarySearchClient(client: olHttp),
          ),
          if (withPicker) RepositoryProvider<CoverPicker>.value(value: picker),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LibraryCubit(books)),
            BlocProvider(create: (_) => MetadataCubit(aggregator)),
            BlocProvider.value(value: settingsCubit),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AddBookScreen(book: book),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterTitle(WidgetTester tester, String title) async {
    await tester.enterText(find.widgetWithText(TextField, 'Titel'), title);
  }

  group('defaults for new books', () {
    testWidgets('start from the format and status chosen in the settings', (
      tester,
    ) async {
      settings
        ..values['defaultFormat'] = 'hardcover'
        ..values['defaultStatus'] = 'wishlist';
      await pump(tester);

      expect(
        tester
            .widget<DropdownButton<BookFormat>>(
              find.byType(DropdownButton<BookFormat>),
            )
            .value,
        BookFormat.hardcover,
      );
      expect(
        tester
            .widget<DropdownButton<BookStatus>>(
              find.byType(DropdownButton<BookStatus>),
            )
            .value,
        BookStatus.wishlist,
      );
    });

    testWidgets('the default tags are assigned to the saved book', (
      tester,
    ) async {
      settings.values['defaultTags'] = '2,5';
      await pump(tester);
      await enterTitle(tester, 'Mit Tags');

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(books.added.single.title, 'Mit Tags');
      expect(tags.assigned.single.$1, 77);
      expect(tags.assigned.single.$2, {2, 5});
    });

    testWidgets('no tag assignment without default tags', (tester) async {
      await pump(tester);
      await enterTitle(tester, 'Ohne Tags');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(books.added, hasLength(1));
      expect(tags.assigned, isEmpty);
    });

    testWidgets('editing a book does not apply the defaults', (tester) async {
      settings.values['defaultStatus'] = 'wishlist';
      await pump(tester, book: existing());

      expect(
        tester
            .widget<DropdownButton<BookStatus>>(
              find.byType(DropdownButton<BookStatus>),
            )
            .value,
        BookStatus.read,
      );
    });
  });

  group('cover', () {
    testWidgets('picking from the gallery shows and saves the cover', (
      tester,
    ) async {
      picker.next = testPng(seed: 5);
      await pump(tester);
      expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('cover-gallery')));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pump();
      });
      expect(picker.requested, [CoverPickSource.gallery]);
      expect(find.byKey(const ValueKey('cover-placeholder')), findsNothing);
      expect(find.byKey(const ValueKey('cover-remove')), findsOneWidget);

      await enterTitle(tester, 'Mit Cover');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final path = books.added.single.coverLocalPath!;
      expect(path.startsWith('${dir.path}/covers/manual-'), isTrue);
      expect(File(path).readAsBytesSync(), testPng(seed: 5));
    });

    testWidgets('the camera button asks for the camera', (tester) async {
      picker.next = testPng();
      await pump(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('cover-camera')));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pump();
      });

      expect(picker.requested, [CoverPickSource.camera]);
    });

    testWidgets('a denied camera says so and keeps the form', (tester) async {
      picker.error = PlatformException(code: 'camera_access_denied');
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('cover-camera')));
      await tester.pump();

      expect(find.text('Bild konnte nicht geladen werden'), findsOneWidget);
      expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      picker.next = null;
      await pump(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('cover-gallery')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('cover-remove')), findsNothing);
    });

    testWidgets('removing the cover clears both the file and the URL', (
      tester,
    ) async {
      final path = (await tester.runAsync(
        () => cache.saveCover('old', testPng()),
      ))!;
      await pump(
        tester,
        book: existing(coverUrl: 'https://x/c.jpg', coverLocalPath: path),
      );

      await tester.tap(find.byKey(const ValueKey('cover-remove')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final draft = books.updated.single.$2;
      expect(draft.coverLocalPath, isNull);
      expect(draft.coverUrl, isNull);
    });

    testWidgets('without a picker (e.g. desktop) there are no pick buttons', (
      tester,
    ) async {
      await pump(tester, withPicker: false);
      expect(find.byKey(const ValueKey('cover-gallery')), findsNothing);
      expect(find.byKey(const ValueKey('cover-camera')), findsNothing);
    });

    testWidgets(
      'editing keeps the series link, Open Library id and cover URL',
      (tester) async {
        await pump(tester, book: existing(coverUrl: 'https://x/c.jpg'));

        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();

        final (id, draft) = books.updated.single;
        expect(id, 5);
        expect(draft.seriesId, 9, reason: 'was silently dropped before');
        expect(draft.olid, 'OL1M');
        expect(draft.coverUrl, 'https://x/c.jpg');
      },
    );
  });

  group('description', () {
    testWidgets('can be entered and is saved', (tester) async {
      await pump(tester);
      await enterTitle(tester, 'Mit Text');
      await tester.enterText(
        find.widgetWithText(TextField, 'Beschreibung'),
        '  Ein langer Klappentext.  ',
      );

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(books.added.single.description, 'Ein langer Klappentext.');
    });
  });

  group('Open Library', () {
    http.Response ok(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );

    testWidgets('a picked result fills the form and is saved with its id', (
      tester,
    ) async {
      olHttp = MockClient((req) async {
        expect(req.url.path, '/search.json');
        return ok({
          'docs': [
            {
              'key': '/works/OL45W',
              'title': 'Der Vorleser',
              'author_name': ['Bernhard Schlink'],
              'first_publish_year': 1995,
              'number_of_pages_median': 207,
              'isbn': ['9783257229530'],
              'publisher': ['Diogenes'],
              'language': ['ger'],
              'cover_i': 1234,
              'cover_edition_key': 'OL99M',
            },
          ],
        });
      });
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('open-library-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ol-query')),
        'Vorleser',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('ol-search')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Der Vorleser'));
      await tester.pumpAndSettle();

      // Back on the form, prefilled.
      expect(find.byType(AddBookScreen), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Der Vorleser'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Bernhard Schlink'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, '9783257229530'), findsOneWidget);
      expect(find.widgetWithText(TextField, '1995'), findsOneWidget);
      expect(find.widgetWithText(TextField, '207'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Diogenes'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'de'), findsOneWidget);

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final draft = books.added.single;
      expect(draft.olid, 'OL99M');
      expect(draft.isbn13, '9783257229530');
      expect(draft.coverUrl, 'https://covers.openlibrary.org/b/id/1234-L.jpg');
      expect(draft.language, 'de');
    });

    testWidgets('no results shows a message', (tester) async {
      olHttp = MockClient((_) async => ok({'docs': []}));
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('open-library-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('ol-query')), 'zzz');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('ol-search')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('Keine Treffer'), findsOneWidget);
    });
  });
  group('genre, price and received date (spec 003)', () {
    testWidgets('are saved with a new book', (tester) async {
      await pump(tester);
      await enterTitle(tester, 'Neu');
      await tester.enterText(find.widgetWithText(TextField, 'Genre'), 'Krimi');
      await tester.enterText(
        find.widgetWithText(TextField, 'Preis in Euro'),
        '12,90',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final draft = books.added.single;
      expect((draft.genre, draft.priceCents), ('Krimi', 1290));
      expect(draft.receivedAt, isNull);
    });

    testWidgets('are pre-filled and kept when editing', (tester) async {
      await pump(
        tester,
        book: existing(
          genre: 'Fantasy',
          priceCents: 999,
          receivedAt: DateTime(2025, 12, 24),
        ),
      );

      expect(find.widgetWithText(TextField, 'Fantasy'), findsOneWidget);
      expect(find.widgetWithText(TextField, '9,99'), findsOneWidget);

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final draft = books.updated.single.$2;
      expect(
        (draft.genre, draft.priceCents, draft.receivedAt),
        ('Fantasy', 999, DateTime(2025, 12, 24)),
      );
      expect(
        draft.editedFields,
        isNot(contains('genre')),
        reason: 'only DNB-sourced fields drive the verification badge',
      );
    });

    testWidgets('clearing the fields removes the values', (tester) async {
      await pump(
        tester,
        book: existing(
          genre: 'Fantasy',
          priceCents: 999,
          receivedAt: DateTime(2025, 12, 24),
        ),
      );
      await tester.enterText(find.widgetWithText(TextField, 'Fantasy'), '');
      await tester.enterText(find.widgetWithText(TextField, '9,99'), '');
      await tester.tap(find.byKey(const ValueKey('received-at-clear')));
      await tester.pump();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final draft = books.updated.single.$2;
      expect(
        (draft.genre, draft.priceCents, draft.receivedAt),
        (null, null, null),
      );
    });

    testWidgets('an invalid price blocks saving and shows a hint', (
      tester,
    ) async {
      await pump(tester);
      await enterTitle(tester, 'Neu');
      await tester.enterText(
        find.widgetWithText(TextField, 'Preis in Euro'),
        'gratis',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(books.added, isEmpty);
      expect(
        find.text('Bitte einen gültigen Preis eingeben, z. B. 12,90'),
        findsOneWidget,
      );
    });

    testWidgets('the received date is picked from a date picker', (
      tester,
    ) async {
      await pump(tester);
      await enterTitle(tester, 'Neu');
      await tester.tap(find.byKey(const ValueKey('received-at-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(books.added.single.receivedAt, isNotNull);
    });
  });

  group('data the form does not show (regressions)', () {
    testWidgets('editing keeps an imported reading time', (tester) async {
      await pump(tester, book: existing(readingSeconds: 19800));

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(books.updated.single.$2.readingSeconds, 19800);
    });

    testWidgets('a metadata lookup without a real cover keeps a manual one', (
      tester,
    ) async {
      final path = (await tester.runAsync(
        () => cache.saveCover('manual-1', testPng()),
      ))!;
      await pump(
        tester,
        book: existing(coverLocalPath: path),
        aggregator: MetadataAggregatorService([_TitleOnlySource()]),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'ISBN'),
        '9783833874239',
      );
      await tester.tap(find.byTooltip('Metadaten suchen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final draft = books.updated.single.$2;
      expect(draft.coverLocalPath, path, reason: 'the user picked this cover');
      expect(draft.coverUrl, isNull);
    });
  });

  group('a failing save', () {
    testWidgets('is reported and keeps the form open', (tester) async {
      books.failWith = StateError('no such column: genre');
      await pump(tester);
      await enterTitle(tester, 'Neu');

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.byType(AddBookScreen), findsOneWidget);
      expect(
        find.textContaining('Das Buch konnte nicht gespeichert werden'),
        findsOneWidget,
      );
      expect(find.textContaining('no such column: genre'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Neu'), findsOneWidget);
    });
  });
}

/// Knows the book but has no cover, so the aggregator adds the DNB fallback URL.
class _TitleOnlySource implements MetadataSourceStrategy {
  @override
  MetadataSource get id => MetadataSource.dnb;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async =>
      const BookMetadata(title: 'Gefunden', authors: ['A']);
}
