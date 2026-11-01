import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/lending_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/lending/lending_cubit.dart';
import 'package:openreads/features/library/add_book_screen.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/widgets/verification_badge.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/fake_settings_repository.dart';

class FakeBookRepository implements BookRepository {
  Book? book;
  Book? trashedBook;
  final deleted = <int>[];
  final restored = <int>[];

  /// Other books by id (a volume's slipcase) and the volumes of slipcases.
  Map<int, Book> byId = {};
  List<Book> volumes = [];
  final splits = <(int, List<VolumeDraft>)>[];

  FakeBookRepository(this.book);

  @override
  Future<Book?> getBook(int id) async => byId[id] ?? book ?? trashedBook;

  @override
  Future<List<Book>> getVolumes(int id) async => [
    for (final v in volumes)
      if (v.parentId == id) v,
  ];

  @override
  Future<List<int>> splitIntoVolumes(int id, List<VolumeDraft> drafts) async {
    splits.add((id, drafts));
    volumes = [
      for (final (i, d) in drafts.indexed)
        book!.copyWith(id: 100 + i, title: d.title, parentId: Value(id)),
    ];
    return [for (final v in volumes) v.id];
  }

  @override
  Stream<List<Book>> watchBooks({
    String? query,
    BookStatus? status,
    int? locationId,
  }) => Stream.value([?book]);

  @override
  Future<void> updateFavorite(int id, bool isFavorite) async =>
      book = book!.copyWith(isFavorite: isFavorite);

  @override
  Future<void> updateRating(int id, double rating) async =>
      book = book!.copyWith(rating: rating);

  @override
  Future<void> updateStatus(int id, BookStatus status) async =>
      book = book!.copyWith(status: status);

  @override
  Future<void> updateReview(int id, String? review) async {
    final text = review?.trim();
    book = book!.copyWith(
      review: Value(text == null || text.isEmpty ? null : text),
    );
  }

  @override
  Future<void> deleteBook(int id) async {
    deleted.add(id);
    trashedBook = book;
    book = null;
  }

  @override
  Future<void> restoreBook(int id) async {
    restored.add(id);
    book = trashedBook;
    trashedBook = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeTagRepository implements TagRepository {
  final List<Tag> tags;
  FakeTagRepository([this.tags = const []]);

  @override
  Stream<List<Tag>> watchTagsForBook(int bookId) => Stream.value(tags);

  @override
  Stream<Set<int>> watchBookIdsWithAllTags(Set<int> tagIds) =>
      Stream.value({1});

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeNotesRepository implements NotesRepository {
  @override
  Stream<List<BookNote>> watchNotes(int bookId) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeReadingRepository implements ReadingRepository {
  final List<ReadingSession> sessions;
  FakeReadingRepository([this.sessions = const []]);

  @override
  Stream<List<ReadingSession>> watchSessions(int bookId) =>
      Stream.value(sessions);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeLendingRepository implements LendingRepository {
  final List<LendingData> history;
  FakeLendingRepository([this.history = const []]);

  @override
  Stream<LendingData?> watchActiveLending(int bookId) => Stream.value(null);

  @override
  Stream<List<LendingData>> watchHistory(int bookId) => Stream.value(history);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Lets the edit form open from the detail screen.
class _Locations implements LocationRepository {
  @override
  Future<List<Location>> getLocations() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book sampleBook({
  double rating = 0,
  bool favorite = false,
  BookStatus status = BookStatus.read,
  String? description,
  String? olid,
  String? isbn13,
  String? isbn10,
  String? genre,
  int? priceCents,
  DateTime? receivedAt,
  ReceivedAs? receivedAs,
  int? readingSeconds,
}) => Book(
  id: 1,
  title: 'Der Vorleser',
  authors: const ['Bernhard Schlink'],
  status: status,
  rating: rating,
  pageCount: 200,
  currentPage: 200,
  description: description,
  olid: olid,
  isbn13: isbn13,
  isbn10: isbn10,
  genre: genre,
  priceCents: priceCents,
  receivedAt: receivedAt,
  receivedAs: receivedAs,
  readingSeconds: readingSeconds,
  editedFields: const [],
  isFavorite: favorite,
  coverNotFound: false,
  createdAt: DateTime(2026, 1, 15),
  updatedAt: DateTime(2026, 2, 20),
);

Future<FakeBookRepository> pumpDetail(
  WidgetTester tester, {
  Book? book,
  VoidCallback? onDeleted,
  FakeSettingsRepository? settings,
  List<Tag> tags = const [],
  List<LendingData> lendingHistory = const [],
  List<ReadingSession> sessions = const [],
  List<Book> volumes = const [],
  Map<int, Book> others = const {},
}) async {
  // Tall enough that the whole (lazily built) list is on screen.
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = FakeBookRepository(book ?? sampleBook())
    ..volumes = [...volumes]
    ..byId = {...others};
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BookRepository>.value(value: repo),
        RepositoryProvider<TagRepository>.value(value: FakeTagRepository(tags)),
        RepositoryProvider<NotesRepository>.value(value: FakeNotesRepository()),
        RepositoryProvider<LocationRepository>.value(value: _Locations()),
        RepositoryProvider<OpenLibrarySearchClient>.value(
          value: OpenLibrarySearchClient(
            client: MockClient((_) async => http.Response('{}', 404)),
          ),
        ),
        RepositoryProvider<ReadingRepository>.value(
          value: FakeReadingRepository(sessions),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LibraryCubit(repo)),
          BlocProvider(
            create: (_) => LendingCubit(FakeLendingRepository(lendingHistory)),
          ),
          BlocProvider(
            lazy: false,
            create: (_) =>
                SettingsCubit(settings ?? FakeSettingsRepository())..load(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BookDetailScreen(bookId: 1, onDeleted: onDeleted),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('trash', () {
    testWidgets('asks for confirmation and keeps the book on cancel', (
      tester,
    ) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();

      expect(find.text('„Der Vorleser“ in den Papierkorb?'), findsOneWidget);
      expect(find.textContaining('wiederhergestellt'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(repo.deleted, isEmpty);
      expect(find.byType(BookDetailScreen), findsOneWidget);
    });

    testWidgets('moves the book to the trash and leaves the screen', (
      tester,
    ) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
      await tester.pumpAndSettle();

      expect(repo.deleted, [1]);
      expect(find.byType(BookDetailScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(find.text('Buch im Papierkorb'), findsOneWidget);
    });

    testWidgets('the snackbar offers to undo', (tester) async {
      final repo = await pumpDetail(tester);
      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();

      expect(repo.restored, [1]);
      expect(repo.book, isNotNull);
    });

    testWidgets('the undo snackbar goes away on its own', (tester) async {
      await pumpDetail(tester);
      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
      await tester.pumpAndSettle();
      expect(find.text('Buch im Papierkorb'), findsOneWidget);

      // A SnackBar with an action persists by default in current Flutter.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('Buch im Papierkorb'), findsNothing);
    });

    testWidgets('an embedded pane gets onDeleted instead of popping', (
      tester,
    ) async {
      var notified = 0;
      final repo = await pumpDetail(tester, onDeleted: () => notified++);

      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'In den Papierkorb'));
      await tester.pumpAndSettle();

      expect(repo.deleted, [1]);
      expect(notified, 1);
      expect(
        find.byType(BookDetailScreen),
        findsOneWidget,
        reason: 'the host decides what replaces the pane',
      );
    });
  });

  testWidgets('the favourite toggle flips the flag and its tooltip', (
    tester,
  ) async {
    final repo = await pumpDetail(tester);
    expect(find.byTooltip('Zu Favoriten hinzufügen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('favorite-toggle')));
    await tester.pumpAndSettle();

    expect(repo.book!.isFavorite, isTrue);
    expect(find.byTooltip('Aus Favoriten entfernen'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('favorite-toggle')));
    await tester.pumpAndSettle();
    expect(repo.book!.isFavorite, isFalse);
  });

  group('details', () {
    testWidgets('shows a placeholder cover when there is none', (tester) async {
      await pumpDetail(tester);
      expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
    });

    testWidgets('shows description, Open Library id and dates', (tester) async {
      await pumpDetail(
        tester,
        book: sampleBook(description: 'Ein Roman.', olid: 'OL123M'),
      );

      expect(find.byKey(const ValueKey('book-description')), findsOneWidget);
      expect(find.text('Ein Roman.'), findsOneWidget);
      expect(find.text('OL123M'), findsOneWidget);
      expect(find.text('Open-Library-ID'), findsOneWidget);
      expect(find.text('Hinzugefügt'), findsOneWidget);
      expect(find.text('Geändert'), findsOneWidget);
    });

    testWidgets('no description section for a book without one', (
      tester,
    ) async {
      await pumpDetail(tester);
      expect(find.byKey(const ValueKey('book-description')), findsNothing);
    });

    testWidgets('lists returned lendings in a history', (tester) async {
      final history = [
        LendingData(
          id: 1,
          bookId: 1,
          borrowerName: 'Anna',
          lentAt: DateTime(2026, 1, 1),
          returnedAt: DateTime(2026, 1, 20),
        ),
        LendingData(
          id: 2,
          bookId: 1,
          borrowerName: 'Ben',
          lentAt: DateTime(2026, 2, 1),
        ),
      ];
      await pumpDetail(tester, lendingHistory: history);

      expect(find.text('Frühere Leihen (1)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lending-history')));
      await tester.pumpAndSettle();
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsNothing, reason: 'still lent, not history');
    });
  });

  group('similar books', () {
    testWidgets('an author chip opens the books by that author', (
      tester,
    ) async {
      await pumpDetail(tester);

      await tester.tap(
        find.byKey(const ValueKey('author-chip:Bernhard Schlink')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('similar-books')), findsOneWidget);
      expect(find.byType(BookListTile), findsOneWidget);
    });

    testWidgets('a tag chip opens the books with that tag', (tester) async {
      await pumpDetail(tester, tags: const [Tag(id: 1, name: 'Klassiker')]);

      await tester.tap(find.byKey(const ValueKey('tag-chip:1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('similar-books')), findsOneWidget);
      expect(find.byType(BookListTile), findsOneWidget);
    });
  });

  group('rating', () {
    testWidgets('tapping a star sets the rating', (tester) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.bySemanticsLabel('4.0 stars'));
      await tester.pumpAndSettle();
      expect(repo.book!.rating, 4.0);

      await tester.tap(find.bySemanticsLabel('2.5 stars'));
      await tester.pumpAndSettle();
      expect(repo.book!.rating, 2.5);
    });

    testWidgets('tapping the current rating again clears it', (tester) async {
      final repo = await pumpDetail(tester, book: sampleBook(rating: 3.5));

      await tester.tap(find.bySemanticsLabel('3.5 stars'));
      await tester.pumpAndSettle();

      expect(repo.book!.rating, 0.0);
    });

    testWidgets('the number style steps in half points', (tester) async {
      final settings = FakeSettingsRepository()
        ..values['ratingDisplay'] = 'number';
      final repo = await pumpDetail(
        tester,
        book: sampleBook(rating: 3.5),
        settings: settings,
      );
      expect(find.text('3.5 / 5'), findsOneWidget);
      expect(find.bySemanticsLabel('4.0 stars'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('rating-plus')));
      await tester.pumpAndSettle();
      expect(repo.book!.rating, 4.0);
      expect(find.text('4 / 5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rating-minus')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rating-minus')));
      await tester.pumpAndSettle();
      expect(repo.book!.rating, 3.0);
    });
  });

  group('quick rating on finishing', () {
    Future<void> chooseRead(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButton<BookStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gelesen').last);
      await tester.pumpAndSettle();
    }

    testWidgets('an unrated book that is marked read asks for a rating', (
      tester,
    ) async {
      final repo = await pumpDetail(
        tester,
        book: sampleBook(status: BookStatus.reading),
      );

      await chooseRead(tester);
      expect(repo.book!.status, BookStatus.read);
      expect(find.byKey(const ValueKey('quick-rating')), findsOneWidget);
      expect(find.text('Wie hat dir das Buch gefallen?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('quick-rating')),
          matching: find.bySemanticsLabel('4.5 stars'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      expect(repo.book!.rating, 4.5);
    });

    testWidgets('skipping leaves the book unrated', (tester) async {
      final repo = await pumpDetail(
        tester,
        book: sampleBook(status: BookStatus.reading),
      );

      await chooseRead(tester);
      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();

      expect(repo.book!.status, BookStatus.read);
      expect(repo.book!.rating, 0.0);
    });

    testWidgets('an already rated book is not asked again', (tester) async {
      await pumpDetail(
        tester,
        book: sampleBook(status: BookStatus.reading, rating: 4),
      );

      await chooseRead(tester);

      expect(find.byKey(const ValueKey('quick-rating')), findsNothing);
    });
  });

  group('review', () {
    testWidgets('shows a placeholder, then saves the written review', (
      tester,
    ) async {
      final repo = await pumpDetail(tester);
      expect(find.text('Noch keine Rezension'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edit-review')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('review-field')),
        '  Bewegend und klug.  ',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(repo.book!.review, 'Bewegend und klug.');
      expect(find.text('Bewegend und klug.'), findsOneWidget);
      expect(find.text('Noch keine Rezension'), findsNothing);
    });

    testWidgets('cancelling leaves the review untouched', (tester) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.byKey(const ValueKey('edit-review')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('review-field')), 'x');
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(repo.book!.review, isNull);
    });
  });
  group('book data (spec 003)', () {
    testWidgets('shows genre, price and received date', (tester) async {
      await pumpDetail(
        tester,
        book: sampleBook(
          genre: 'Krimi',
          priceCents: 1290,
          receivedAt: DateTime(2025, 12, 24),
          receivedAs: ReceivedAs.reviewCopy,
        ),
      );

      expect(find.text('Erhalten als'), findsOneWidget);
      expect(find.text('Rezensionsexemplar'), findsOneWidget);
      expect(find.text('Genre'), findsOneWidget);
      expect(find.text('Krimi'), findsOneWidget);
      expect(find.text('Preis'), findsOneWidget);
      expect(find.text('12,90\u00A0€'), findsOneWidget);
      expect(find.text('Erhalten am'), findsOneWidget);
    });

    testWidgets('omits rows for fields that are empty', (tester) async {
      await pumpDetail(tester);

      expect(find.text('Genre'), findsNothing);
      expect(find.text('Preis'), findsNothing);
      expect(find.text('Erhalten am'), findsNothing);
      expect(find.text('Erhalten als'), findsNothing);
    });

    testWidgets('shows the reading period and the time read separately', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        sessions: [
          ReadingSession(
            id: 1,
            bookId: 1,
            startedAt: DateTime(2026, 3, 1, 20),
            endedAt: DateTime(2026, 3, 1, 22),
            durationSeconds: 5400,
            startPage: 0,
          ),
          ReadingSession(
            id: 2,
            bookId: 1,
            startedAt: DateTime(2026, 3, 9, 20),
            endedAt: DateTime(2026, 3, 10, 21),
            durationSeconds: 1800,
            startPage: 0,
          ),
        ],
      );

      expect(find.text('Lesebeginn'), findsOneWidget);
      expect(find.text('Leseende'), findsOneWidget);
      expect(find.text('Lesezeitraum'), findsOneWidget);
      expect(find.text('10 Tage'), findsOneWidget);
      expect(find.text('Lesezeit'), findsOneWidget);
      expect(find.text('2 Std. 0 Min.'), findsOneWidget);
    });

    testWidgets('without a recorded time only the period is shown', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        sessions: [
          ReadingSession(
            id: 1,
            bookId: 1,
            startedAt: DateTime(2026, 3, 1),
            endedAt: DateTime(2026, 3, 3),
            durationSeconds: 0,
            startPage: 0,
          ),
        ],
      );

      expect(find.text('Lesezeitraum'), findsOneWidget);
      expect(find.text('3 Tage'), findsOneWidget);
      expect(find.text('Lesezeit'), findsNothing);
    });

    testWidgets('a manual reading time counts even without sessions', (
      tester,
    ) async {
      await pumpDetail(tester, book: sampleBook(readingSeconds: 19800));

      expect(find.text('Lesezeit'), findsOneWidget);
      expect(find.text('5 Std. 30 Min.'), findsOneWidget);
      expect(find.text('Lesezeitraum'), findsNothing);
    });

    testWidgets('values are selectable and copyable', (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
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
      await pumpDetail(tester, book: sampleBook(isbn13: '9783442719255'));

      expect(
        find.widgetWithText(SelectableText, '9783442719255'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('copy:ISBN')));
      await tester.pump();

      expect(clipboard, '9783442719255');
      expect(find.text('In die Zwischenablage kopiert'), findsOneWidget);
    });

    testWidgets('shows one ISBN row: the ISBN-13, else the ISBN-10', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        book: sampleBook(isbn13: '9783442719255', isbn10: '3442719259'),
      );
      expect(find.text('ISBN'), findsOneWidget);
      expect(find.text('9783442719255'), findsOneWidget);
      expect(find.text('3442719259'), findsNothing);
      expect(find.text('ISBN-13'), findsNothing);
      expect(find.text('ISBN-10'), findsNothing);
    });

    testWidgets('falls back to the ISBN-10 when there is no ISBN-13', (
      tester,
    ) async {
      await pumpDetail(tester, book: sampleBook(isbn10: '3442719259'));
      expect(find.text('ISBN'), findsOneWidget);
      expect(find.text('3442719259'), findsOneWidget);
    });

    testWidgets('a book without ISBN offers to complete it online', (
      tester,
    ) async {
      await pumpDetail(tester);
      expect(find.text('Online vervollständigen'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('complete-online')));
      await tester.pump();
      await tester.pump();

      final form = tester.widget<AddBookScreen>(find.byType(AddBookScreen));
      expect(form.searchOnline, isTrue);
      expect(form.book?.id, 1);
    });

    testWidgets('a book with an ISBN does not offer it', (tester) async {
      await pumpDetail(tester, book: sampleBook(isbn10: '3442719259'));
      expect(find.byKey(const ValueKey('complete-online')), findsNothing);
    });

    testWidgets('the verification badge is a label, not an edit button', (
      tester,
    ) async {
      await pumpDetail(tester);

      expect(
        find.descendant(
          of: find.byType(VerificationBadge),
          matching: find.byIcon(Icons.edit),
        ),
        findsNothing,
      );
      // The one real edit action stays in the app bar.
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });

  group('slipcases (ADR-0003)', () {
    Book volume(int id, String title, BookStatus status) => sampleBook(
      status: status,
    ).copyWith(id: id, title: title, parentId: const Value(1));

    testWidgets('a single book can be split into volumes', (tester) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.byKey(const ValueKey('book-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('split-volumes')));
      await tester.pumpAndSettle();

      final save = find.byKey(const ValueKey('split-save'));
      await tester.enterText(
        find.byKey(const ValueKey('volume-title-0')),
        'Eins',
      );
      await tester.pump();
      expect(
        tester.widget<FilledButton>(save).onPressed,
        isNull,
        reason: 'a slipcase needs at least two volumes',
      );

      await tester.enterText(
        find.byKey(const ValueKey('volume-title-1')),
        'Zwei',
      );
      await tester.enterText(
        find.byKey(const ValueKey('volume-pages-1')),
        '320',
      );
      await tester.tap(find.byKey(const ValueKey('add-volume')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('volume-title-2')),
        'Drei',
      );
      await tester.tap(save);
      await tester.pumpAndSettle();

      final (id, drafts) = repo.splits.single;
      expect(id, 1);
      expect(drafts.map((d) => (d.title, d.pageCount)), [
        ('Eins', null),
        ('Zwei', 320),
        ('Drei', null),
      ]);
      // Back on the detail screen, which now shows the volumes.
      expect(find.byKey(const ValueKey('volumes-section')), findsOneWidget);
    });

    testWidgets('a slipcase lists its volumes and how many are read', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        volumes: [
          volume(2, 'Band Eins', BookStatus.read),
          volume(3, 'Band Zwei', BookStatus.unread),
        ],
      );

      expect(find.text('Band Eins'), findsOneWidget);
      expect(find.text('Band Zwei'), findsOneWidget);
      expect(find.text('1 von 2 gelesen'), findsOneWidget);
      // Status and rating belong to the volumes; the box shows the derived
      // status only.
      expect(find.byType(DropdownButton<BookStatus>), findsNothing);
      expect(find.text('Am Lesen'), findsOneWidget);

      expect(find.byKey(const ValueKey('book-menu')), findsNothing);
    });

    testWidgets('a volume links to its slipcase', (tester) async {
      await pumpDetail(
        tester,
        book: volume(
          1,
          'Band Eins',
          BookStatus.read,
        ).copyWith(parentId: const Value(7)),
        others: {7: sampleBook().copyWith(id: 7, title: 'Der Schuber')},
      );

      expect(find.text('Teil von „Der Schuber“'), findsOneWidget);
      expect(find.byKey(const ValueKey('book-menu')), findsNothing);
    });
  });
}
