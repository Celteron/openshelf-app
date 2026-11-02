import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/export/export_file_saver.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/features/statistics/year_review_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _Books implements BookRepository {
  final List<Book> books;
  _Books(this.books);

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Reading implements ReadingRepository {
  @override
  Stream<List<ReadingSession>> watchAllSessions() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Saver implements ExportFileSaver {
  final saved = <(String, int, String)>[];

  @override
  Future<String?> saveBytes(
    String fileName,
    Uint8List bytes, {
    required String mimeType,
  }) async {
    saved.add((fileName, bytes.length, mimeType));
    return fileName;
  }

  @override
  Future<String?> save(String fileName, String content) async => null;
}

Book _book(
  int id,
  String title,
  DateTime finished, {
  int pages = 200,
  double rating = 0,
}) => Book(
  id: id,
  title: title,
  authors: const ['Autorin'],
  status: BookStatus.read,
  rating: rating,
  pageCount: pages,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  finishedAt: finished,
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);

void main() {
  late _Saver saver;

  Future<void> pump(WidgetTester tester, List<Book> books) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    saver = _Saver();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BookRepository>.value(value: _Books(books)),
          RepositoryProvider<ReadingRepository>.value(value: _Reading()),
          RepositoryProvider<ExportFileSaver>.value(value: saver),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: YearReviewScreen(year: 2026),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the first card names the year and the numbers', (tester) async {
    await pump(tester, [
      _book(1, 'A', DateTime(2026, 2, 1), pages: 300),
      _book(2, 'B', DateTime(2026, 3, 1), pages: 200),
    ]);

    expect(find.text('Dein Lesejahr 2026'), findsOneWidget);
    expect(find.text('2 Bücher'), findsOneWidget);
    expect(find.text('500 Seiten'), findsOneWidget);
  });

  testWidgets('swiping shows the highlights', (tester) async {
    await pump(tester, [
      _book(1, 'Das dicke Buch', DateTime(2026, 2, 1), pages: 900, rating: 4),
      _book(2, 'Das beste Buch', DateTime(2026, 3, 1), pages: 100, rating: 5),
    ]);

    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(find.text('Dickstes Buch'), findsOneWidget);
    expect(find.text('Das dicke Buch'), findsOneWidget);
    expect(find.text('Dein Highlight'), findsOneWidget);
    expect(find.text('Das beste Buch'), findsOneWidget);
  });

  testWidgets('a year without finished books says so', (tester) async {
    await pump(tester, [_book(1, 'Alt', DateTime(2020, 1, 1))]);

    expect(
      find.text('Für 2026 gibt es noch keine beendeten Bücher.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('review-save')), findsNothing);
  });

  testWidgets('saving writes the current card as a PNG', (tester) async {
    await pump(tester, [_book(1, 'A', DateTime(2026, 2, 1))]);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('review-save')));
      // Rendering the card needs the real engine; wait for the save to land.
      for (var i = 0; i < 50 && saver.saved.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();

    expect(saver.saved, hasLength(1));
    final (name, size, mime) = saver.saved.single;
    expect(name, 'openshelf-2026-1.png');
    expect(size, greaterThan(100));
    expect(mime, 'image/png');
    expect(
      find.textContaining('Gespeichert: openshelf-2026-1.png'),
      findsOneWidget,
    );
  });
}
