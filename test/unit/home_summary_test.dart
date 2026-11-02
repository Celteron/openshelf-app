import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/home_summary.dart';

Book _book(
  int id,
  BookStatus status, {
  DateTime? createdAt,
  bool favorite = false,
  int? parentId,
}) => Book(
  id: id,
  title: 'B$id',
  authors: const ['A'],
  status: status,
  rating: 0,
  parentId: parentId,
  editedFields: const [],
  currentPage: 0,
  isFavorite: favorite,
  coverNotFound: false,
  createdAt: createdAt ?? DateTime(2026, 1, id),
  updatedAt: DateTime(2026),
);

/// The home tab's numbers (FR-R2-19).
void main() {
  final now = DateTime(2026, 6, 15);

  test('read / reading / unread over readable books', () {
    final summary = HomeSummary.of([
      _book(1, BookStatus.read),
      _book(2, BookStatus.reading),
      _book(3, BookStatus.reReading),
      _book(4, BookStatus.unread),
      _book(5, BookStatus.wishlist),
      _book(6, BookStatus.dnf),
      // A slipcase (7) with one volume: only the volume counts.
      _book(7, BookStatus.unread),
      _book(8, BookStatus.unread, parentId: 7),
    ], now: now);
    expect(
      (summary.read, summary.reading, summary.unread, summary.total),
      (1, 2, 2, 5),
    );
  });

  test('the three most recently added physical books, newest first', () {
    final summary = HomeSummary.of([
      for (var i = 1; i <= 5; i++) _book(i, BookStatus.unread),
      _book(9, BookStatus.unread, parentId: 5, createdAt: DateTime(2026, 6)),
    ], now: now);
    expect(summary.recent.map((b) => b.id), [5, 4, 3]);
  });

  test('currently reading and favourites', () {
    final summary = HomeSummary.of([
      _book(1, BookStatus.reading),
      _book(2, BookStatus.read, favorite: true),
      _book(3, BookStatus.reReading),
    ], now: now);
    expect(summary.currentlyReading.map((b) => b.id), [1, 3]);
    expect(summary.favourites.map((b) => b.id), [2]);
  });

  test('the unread stack over the last six months', () {
    final summary = HomeSummary.of([
      _book(1, BookStatus.unread, createdAt: DateTime(2026, 3, 10)),
    ], now: now);
    expect(summary.unreadTrend, [0, 0, 1, 1, 1, 1]);
  });
}
