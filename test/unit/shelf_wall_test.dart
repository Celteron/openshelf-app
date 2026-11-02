import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/shelf_wall.dart';

Location loc(
  int id,
  String name,
  LocationType type, {
  int? parent,
  int order = 0,
}) => Location(
  id: id,
  name: name,
  type: type,
  parentId: parent,
  sortOrder: order,
);

Book book(
  int id,
  String title, {
  int? location,
  int? pages,
  String author = 'Autorin',
  int? parentId,
  BookStatus status = BookStatus.unread,
  int? seriesId,
  double? volume,
}) => Book(
  id: id,
  title: title,
  authors: [author],
  status: status,
  rating: 0,
  pageCount: pages,
  locationId: location,
  parentId: parentId,
  seriesId: seriesId,
  seriesVolume: volume,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  final room = loc(1, 'Wohnzimmer', LocationType.room);
  final shelf = loc(2, 'Regal 2', LocationType.shelf, parent: 1);
  final slotA = loc(3, 'Fach 1', LocationType.compartment, parent: 2, order: 0);
  final slotB = loc(4, 'Fach 2', LocationType.compartment, parent: 2, order: 1);
  final locations = [room, shelf, slotB, slotA]; // deliberately unordered

  test('a row per compartment, in the order of the tree, with its path', () {
    final wall = ShelfWall.build(locations, [book(1, 'A', location: 3)]);

    expect(wall.rows.map((r) => r.locationId), [3, 4]);
    expect(wall.rows.first.pathLabel, 'Wohnzimmer › Regal 2 › Fach 1');
    expect(
      wall.rows.last.spines,
      isEmpty,
      reason: 'an empty compartment shows',
    );
  });

  test('books standing directly on a shelf or room get their own row', () {
    final wall = ShelfWall.build(locations, [
      book(1, 'Im Regal', location: 2),
      book(2, 'Im Raum', location: 1),
    ]);

    expect(wall.rows.map((r) => r.locationId), containsAll([1, 2, 3, 4]));
    final shelfRow = wall.rows.firstWhere((r) => r.locationId == 2);
    expect(shelfRow.spines.single.book.title, 'Im Regal');
    expect(shelfRow.pathLabel, 'Wohnzimmer › Regal 2');
  });

  test('books without a location come last, in their own row', () {
    final wall = ShelfWall.build(locations, [
      book(1, 'Lose'),
      book(2, 'Fach', location: 3),
    ]);

    expect(wall.rows.last.locationId, isNull);
    expect(wall.rows.last.spines.single.book.title, 'Lose');
  });

  test('no unassigned row when every book has a place', () {
    final wall = ShelfWall.build(locations, [book(1, 'A', location: 3)]);

    expect(wall.rows.any((r) => r.locationId == null), isFalse);
  });

  test('volumes stand inside their slipcase, wishlist books not at all', () {
    final wall = ShelfWall.build(locations, [
      book(1, 'Schuber', location: 3, pages: 900),
      book(2, 'Band 1', location: 3, pages: 300, parentId: 1),
      book(3, 'Band 2', location: 3, pages: 300, parentId: 1),
      book(4, 'Wunsch', location: 3, status: BookStatus.wishlist),
    ]);

    final spines = wall.rows.first.spines;
    expect(spines.map((s) => s.book.title), ['Schuber']);
    expect(spines.single.volumes.map((v) => v.title), ['Band 1', 'Band 2']);
  });

  test('spines are ordered by author, then series volume, then title', () {
    final wall = ShelfWall.build(locations, [
      book(1, 'Zebra', location: 3, author: 'Adler'),
      book(2, 'Band 2', location: 3, author: 'Brandt', seriesId: 1, volume: 2),
      book(3, 'Band 1', location: 3, author: 'Brandt', seriesId: 1, volume: 1),
      book(4, 'Ärger', location: 3, author: 'Adler'),
    ]);

    expect(wall.rows.first.spines.map((s) => s.book.title), [
      'Ärger',
      'Zebra',
      'Band 1',
      'Band 2',
    ]);
  });

  group('spine size', () {
    double widthOf(int? pages) => ShelfWall.build(locations, [
      book(1, 'A', location: 3, pages: pages),
    ]).rows.first.spines.single.width;

    test('never narrower than the tap target, never wider than 96', () {
      expect(widthOf(1), SpineMetrics.minWidth);
      expect(widthOf(100), SpineMetrics.minWidth);
      expect(widthOf(10000), SpineMetrics.maxWidth);
      expect(SpineMetrics.minWidth, greaterThanOrEqualTo(48));
    });

    test('thicker books are wider', () {
      expect(widthOf(500), greaterThan(widthOf(200)));
    });

    test('no page count, zero or negative use the default width', () {
      expect(widthOf(null), SpineMetrics.defaultWidth);
      expect(widthOf(0), SpineMetrics.defaultWidth);
      expect(widthOf(-5), SpineMetrics.defaultWidth);
    });

    test('a slipcase is as wide as its volumes, up to three spines', () {
      final wall = ShelfWall.build(locations, [
        book(1, 'Schuber', location: 3),
        for (var i = 0; i < 6; i++)
          book(10 + i, 'Band $i', location: 3, pages: 800, parentId: 1),
      ]);

      expect(wall.rows.first.spines.single.width, SpineMetrics.maxWidth * 3);
    });
  });

  test('positionOf finds a book, and a volume via its slipcase', () {
    final wall = ShelfWall.build(locations, [
      book(1, 'Schuber', location: 4),
      book(2, 'Band 1', location: 4, parentId: 1),
      book(3, 'Einzeln', location: 3),
    ]);

    expect(wall.positionOf(3), (row: 0, spine: 0));
    expect(wall.positionOf(2), wall.positionOf(1));
    expect(wall.positionOf(1)?.row, 1);
    expect(wall.positionOf(99), isNull);
  });
}
