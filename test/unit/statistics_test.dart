import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/statistics.dart';

Book _book(
  int id, {
  required BookStatus status,
  int? pages,
  int? locationId,
  List<String> authors = const ['Author'],
}) {
  return Book(
    id: id,
    isbn13: null,
    isbn10: null,
    title: 'Book $id',
    subtitle: null,
    authors: authors,
    publisher: null,
    publishedYear: null,
    pageCount: pages,
    format: null,
    language: null,
    status: status,
    rating: 0.0,
    locationId: locationId,
    seriesId: null,
    seriesVolume: null,
    currentPage: 0,
    finishedAt: null,
    isFavorite: false,
    review: null,
    description: null,
    coverUrl: null,
    coverLocalPath: null,
    metadataSource: null,
    editedFields: const [],
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );
}

void main() {
  test('computes totals, status breakdown, and pages read', () {
    final books = [
      _book(1, status: BookStatus.read, pages: 200),
      _book(2, status: BookStatus.read, pages: 350),
      _book(3, status: BookStatus.reading, pages: 120),
      _book(4, status: BookStatus.wishlist),
    ];

    final stats = BookStatistics.compute(books, const []);

    expect(stats.totalBooks, 4);
    expect(stats.statusCounts[BookStatus.read], 2);
    expect(stats.statusCounts[BookStatus.reading], 1);
    expect(stats.statusCounts[BookStatus.wishlist], 1);
    expect(stats.statusCounts[BookStatus.unread], 0);
    expect(stats.pagesRead, 550);
  });

  test('ranks top locations and top authors by count', () {
    final books = [
      _book(1, status: BookStatus.unread, locationId: 1, authors: ['Ann']),
      _book(2, status: BookStatus.unread, locationId: 1, authors: ['Ann']),
      _book(3, status: BookStatus.unread, locationId: 2, authors: ['Bob']),
    ];
    final locations = [
      const Location(
        id: 1,
        name: 'Living Room',
        type: LocationType.room,
        parentId: null,
        sortOrder: 0,
      ),
      const Location(
        id: 2,
        name: 'Office',
        type: LocationType.room,
        parentId: null,
        sortOrder: 0,
      ),
    ];

    final stats = BookStatistics.compute(books, locations);

    expect(stats.topLocations.first.name, 'Living Room');
    expect(stats.topLocations.first.count, 2);
    expect(stats.topAuthors.first.name, 'Ann');
    expect(stats.topAuthors.first.count, 2);
  });

  test('counts a co-author for each book they appear in', () {
    final books = [
      _book(1, status: BookStatus.unread, authors: ['Grebe, Camilla', 'Haefs']),
      _book(2, status: BookStatus.unread, authors: ['Grebe, Camilla']),
    ];

    final stats = BookStatistics.compute(books, const []);

    expect(stats.topAuthors.first.name, 'Grebe, Camilla');
    expect(stats.topAuthors.first.count, 2);
  });
}
