import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/shelf_wall.dart';
import 'package:openreads/domain/services/shelf_search.dart';

Book book(
  int id,
  String title, {
  String author = 'Autorin',
  String? subtitle,
  int? parent,
  int location = 1,
}) => Book(
  id: id,
  title: title,
  subtitle: subtitle,
  authors: [author],
  status: BookStatus.unread,
  rating: 0,
  locationId: location,
  parentId: parent,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const slot = Location(
  id: 1,
  name: 'Fach',
  type: LocationType.compartment,
  sortOrder: 0,
);
const slot2 = Location(
  id: 2,
  name: 'Fach 2',
  type: LocationType.compartment,
  sortOrder: 1,
);

void main() {
  ShelfWall wall(List<Book> books) => ShelfWall.build([slot, slot2], books);

  test('finds by title, ignoring case and umlauts', () {
    final w = wall([book(1, 'Der Vorleser'), book(2, 'Die Blechtrommel')]);

    expect(findOnShelf(w, 'VORLESER'), [1]);
    expect(findOnShelf(wall([book(3, 'Über Grenzen')]), 'uber'), [3]);
  });

  test('finds by author and by subtitle', () {
    final w = wall([
      book(1, 'A', author: 'Bernhard Müller'),
      book(2, 'B', subtitle: 'Ein Sommerroman'),
    ]);

    expect(findOnShelf(w, 'muller'), [1]);
    expect(findOnShelf(w, 'sommer'), [2]);
  });

  test('the hits come in the order of the wall', () {
    final w = wall([
      book(1, 'Roman B', location: 2, author: 'B'),
      book(2, 'Roman A', location: 1, author: 'A'),
    ]);

    expect(findOnShelf(w, 'roman'), [2, 1]);
  });

  test('every word of the query has to match', () {
    final w = wall([
      book(1, 'Der Vorleser', author: 'Schlink'),
      book(2, 'Der Besuch'),
    ]);

    expect(findOnShelf(w, 'der schlink'), [1]);
  });

  test('an empty or blank query finds nothing', () {
    final w = wall([book(1, 'A')]);

    expect(findOnShelf(w, ''), isEmpty);
    expect(findOnShelf(w, '   '), isEmpty);
  });

  test('a volume is found at its slipcase, once', () {
    final w = wall([
      book(1, 'Schuber'),
      book(2, 'Sturm', parent: 1),
      book(3, 'Sturmzeit', parent: 1),
    ]);

    expect(findOnShelf(w, 'sturm'), [1]);
  });
}
