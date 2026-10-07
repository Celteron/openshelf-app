import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/lending_repository.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/lending/lending_cubit.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

class FakeBookRepository implements BookRepository {
  Book? book;
  final deleted = <int>[];

  FakeBookRepository(this.book);

  @override
  Future<Book?> getBook(int id) async => book;

  @override
  Future<void> updateFavorite(int id, bool isFavorite) async =>
      book = book!.copyWith(isFavorite: isFavorite);

  @override
  Future<void> updateRating(int id, double rating) async =>
      book = book!.copyWith(rating: rating);

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
    book = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeTagRepository implements TagRepository {
  @override
  Stream<List<Tag>> watchTagsForBook(int bookId) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeNotesRepository implements NotesRepository {
  @override
  Stream<List<BookNote>> watchNotes(int bookId) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeLendingRepository implements LendingRepository {
  @override
  Stream<LendingData?> watchActiveLending(int bookId) => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book sampleBook({double rating = 0, bool favorite = false}) => Book(
  id: 1,
  title: 'Der Vorleser',
  authors: const ['Bernhard Schlink'],
  status: BookStatus.read,
  rating: rating,
  pageCount: 200,
  currentPage: 200,
  editedFields: const [],
  isFavorite: favorite,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<FakeBookRepository> pumpDetail(
  WidgetTester tester, {
  Book? book,
  VoidCallback? onDeleted,
}) async {
  final repo = FakeBookRepository(book ?? sampleBook());
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BookRepository>.value(value: repo),
        RepositoryProvider<TagRepository>.value(value: FakeTagRepository()),
        RepositoryProvider<NotesRepository>.value(value: FakeNotesRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LibraryCubit(repo)),
          BlocProvider(create: (_) => LendingCubit(FakeLendingRepository())),
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
  group('delete', () {
    testWidgets('asks for confirmation and keeps the book on cancel', (
      tester,
    ) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();

      expect(find.text('„Der Vorleser“ löschen?'), findsOneWidget);
      expect(find.textContaining('endgültig gelöscht'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(repo.deleted, isEmpty);
      expect(find.byType(BookDetailScreen), findsOneWidget);
    });

    testWidgets('deletes after confirmation and leaves the screen', (
      tester,
    ) async {
      final repo = await pumpDetail(tester);

      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(repo.deleted, [1]);
      expect(find.byType(BookDetailScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(find.text('Buch gelöscht'), findsOneWidget);
    });

    testWidgets('an embedded pane gets onDeleted instead of popping', (
      tester,
    ) async {
      var notified = 0;
      final repo = await pumpDetail(tester, onDeleted: () => notified++);

      await tester.tap(find.byKey(const ValueKey('delete-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
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
  });

  group('review', () {
    testWidgets('shows a placeholder, then saves the written review', (
      tester,
    ) async {
      final repo = await pumpDetail(tester);
      expect(find.text('Noch keine Rezension'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('edit-review')));
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

      await tester.ensureVisible(find.byKey(const ValueKey('edit-review')));
      await tester.tap(find.byKey(const ValueKey('edit-review')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('review-field')), 'x');
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(repo.book!.review, isNull);
    });
  });
}
