import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/year_review.dart';

Book book(
  int id,
  String title, {
  BookStatus status = BookStatus.read,
  DateTime? finished,
  int? pages,
  double rating = 0,
  List<String> authors = const ['Autorin'],
  int? parentId,
  int? readingSeconds,
}) => Book(
  id: id,
  title: title,
  authors: authors,
  status: status,
  rating: rating,
  pageCount: pages,
  parentId: parentId,
  readingSeconds: readingSeconds,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  finishedAt: finished,
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);

ReadingSession session(int bookId, DateTime start, int seconds) =>
    ReadingSession(
      id: start.microsecondsSinceEpoch,
      bookId: bookId,
      startedAt: start,
      endedAt: start.add(Duration(seconds: seconds)),
      durationSeconds: seconds,
      startPage: 0,
    );

void main() {
  DateTime in2026(int month, [int day = 10]) => DateTime(2026, month, day);

  test('counts only books finished in the year', () {
    final review = YearReview.of(2026, [
      book(1, 'A', finished: in2026(2), pages: 100),
      book(2, 'B', finished: in2026(3), pages: 250),
      book(3, 'Letztes Jahr', finished: DateTime(2025, 12, 30), pages: 999),
      book(4, 'Ungelesen', status: BookStatus.unread, pages: 500),
    ], const []);

    expect(review.books, 2);
    expect(review.pages, 350);
    expect(review.isEmpty, isFalse);
  });

  test('a year without finished books is empty', () {
    expect(
      YearReview.of(2026, [
        book(1, 'A', finished: DateTime(2025)),
      ], const []).isEmpty,
      isTrue,
    );
  });

  test('a slipcase is not a book read; its volumes are', () {
    final review = YearReview.of(2026, [
      book(1, 'Schuber', finished: in2026(5), pages: 1200),
      book(2, 'Band 1', finished: in2026(5), pages: 400, parentId: 1),
      book(3, 'Band 2', finished: in2026(5), pages: 300, parentId: 1),
    ], const []);

    expect(review.books, 2);
    expect(review.pages, 700);
  });

  test('longest book, best rated book (latest wins a tie)', () {
    final review = YearReview.of(2026, [
      book(1, 'Dick', finished: in2026(1), pages: 900, rating: 3),
      book(2, 'Gut früh', finished: in2026(2), pages: 100, rating: 5),
      book(3, 'Gut spät', finished: in2026(8), pages: 120, rating: 5),
    ], const []);

    expect(review.longest?.title, 'Dick');
    expect(review.best?.title, 'Gut spät');
  });

  test('no ratings means no best book; no pages no longest', () {
    final review = YearReview.of(2026, [
      book(1, 'A', finished: in2026(1)),
    ], const []);

    expect(review.best, isNull);
    expect(review.longest, isNull);
  });

  test('favourite author and strongest month', () {
    final review = YearReview.of(2026, [
      book(1, 'A', finished: in2026(4, 1), authors: const ['Eins', 'Zwei']),
      book(2, 'B', finished: in2026(4, 20), authors: const ['Eins']),
      book(3, 'C', finished: in2026(9), authors: const ['Zwei']),
    ], const []);

    expect(review.topAuthor, ('Eins', 2));
    expect(review.bestMonth, (4, 2));
  });

  test('reading time and days come from the sessions of the year', () {
    final review = YearReview.of(
      2026,
      [book(1, 'A', finished: in2026(3), readingSeconds: 600)],
      [
        session(1, DateTime(2026, 3, 1, 20), 1800),
        session(1, DateTime(2026, 3, 2, 20), 1800),
        session(1, DateTime(2025, 12, 31, 20), 3600),
      ],
    );

    expect(review.readingSeconds, 1800 + 1800 + 600);
    expect(review.readingDays, 2);
  });

  test('covers: the best rated first, at most twelve', () {
    final books = [
      for (var i = 1; i <= 15; i++)
        book(i, 'B$i', finished: in2026(1, i), rating: i == 7 ? 5 : 3),
    ];

    final review = YearReview.of(2026, books, const []);

    expect(review.covers, hasLength(12));
    expect(review.covers.first.title, 'B7');
  });
}
