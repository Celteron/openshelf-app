import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/library_sort.dart';

Book book(
  int id,
  String title, {
  List<String> authors = const ['Anna Autor'],
  double rating = 0,
  DateTime? createdAt,
  BookStatus status = BookStatus.unread,
  int? pages,
  int currentPage = 0,
}) => Book(
  id: id,
  title: title,
  authors: authors,
  status: status,
  rating: rating,
  pageCount: pages,
  currentPage: currentPage,
  editedFields: const [],
  isFavorite: false,
  createdAt: createdAt ?? DateTime(2026),
  updatedAt: DateTime(2026),
);

List<String> sorted(LibrarySort sort, List<Book> books) =>
    sort.apply(books).map((b) => b.title).toList();

void main() {
  test('the default shows the most recently added book first', () {
    final books = [
      book(1, 'Alt', createdAt: DateTime(2020)),
      book(2, 'Neu', createdAt: DateTime(2026)),
      book(3, 'Mittel', createdAt: DateTime(2023)),
    ];
    expect(sorted(const LibrarySort(), books), ['Neu', 'Mittel', 'Alt']);
  });

  test('sorts by title case-insensitively in both directions', () {
    final books = [book(1, 'beta'), book(2, 'Alpha'), book(3, 'Gamma')];
    const asc = LibrarySort(field: LibrarySortField.title, ascending: true);
    expect(sorted(asc, books), ['Alpha', 'beta', 'Gamma']);
    expect(
      sorted(
        const LibrarySort(field: LibrarySortField.title, ascending: false),
        books,
      ),
      ['Gamma', 'beta', 'Alpha'],
    );
  });

  test('sorts by surname of the first author', () {
    final books = [
      book(1, 'A', authors: ['Günter Grass']),
      book(2, 'B', authors: ['Ava Reed']),
      book(3, 'C', authors: ['Franz Kafka']),
      book(4, 'D', authors: ['Grass, Alt']),
      book(5, 'E', authors: const []),
    ];
    const sort = LibrarySort(field: LibrarySortField.author, ascending: true);
    expect(sorted(sort, books), ['E', 'D', 'A', 'C', 'B']);
  });

  test('sorts by rating, best first when descending', () {
    final books = [
      book(1, 'Mäßig', rating: 2.5),
      book(2, 'Top', rating: 5),
      book(3, 'Unbewertet'),
    ];
    const sort = LibrarySort(field: LibrarySortField.rating, ascending: false);
    expect(sorted(sort, books), ['Top', 'Mäßig', 'Unbewertet']);
  });

  test('sorts by reading progress; finished books count as 100 %', () {
    final books = [
      book(1, 'Halb', pages: 200, currentPage: 100),
      book(2, 'Fertig', status: BookStatus.read),
      book(3, 'Neu', pages: 200),
      book(4, 'Fast', pages: 200, currentPage: 180),
      book(5, 'OhneSeiten', currentPage: 50),
    ];
    const sort = LibrarySort(
      field: LibrarySortField.progress,
      ascending: false,
    );
    expect(sorted(sort, books), [
      'Fertig',
      'Fast',
      'Halb',
      'Neu',
      'OhneSeiten',
    ]);
  });

  test('ties fall back to title then id so the order is stable', () {
    final books = [
      book(2, 'Zwilling', rating: 4),
      book(1, 'Zwilling', rating: 4),
      book(3, 'Anfang', rating: 4),
    ];
    const sort = LibrarySort(field: LibrarySortField.rating, ascending: true);
    final ids = sort.apply(books).map((b) => b.id).toList();
    expect(ids, [3, 1, 2]);
  });

  test('select flips the active field and picks a natural start otherwise', () {
    const start = LibrarySort(); // added, descending
    final flipped = start.select(LibrarySortField.added);
    expect(flipped.field, LibrarySortField.added);
    expect(flipped.ascending, isTrue);

    final title = start.select(LibrarySortField.title);
    expect(title.field, LibrarySortField.title);
    expect(title.ascending, isTrue, reason: 'text starts A→Z');

    final rating = title.select(LibrarySortField.rating);
    expect(rating.ascending, isFalse, reason: 'numbers start high→low');
  });

  test('does not mutate the input list', () {
    final books = [book(1, 'b'), book(2, 'a')];
    const LibrarySort(
      field: LibrarySortField.title,
      ascending: true,
    ).apply(books);
    expect(books.map((b) => b.title), ['b', 'a']);
  });
}
