import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/services/stat_query.dart';

Book _book(
  int id, {
  BookStatus status = BookStatus.read,
  int? pages,
  double rating = 0,
  String? genre,
  List<String> authors = const ['A'],
  DateTime? finishedAt,
  DateTime? createdAt,
  int? parentId,
  int? priceCents,
  ReceivedAs? receivedAs,
  int? readingSeconds,
  BookFormat? format,
}) => Book(
  id: id,
  title: 'B$id',
  authors: authors,
  status: status,
  rating: rating,
  pageCount: pages,
  genre: genre,
  finishedAt: finishedAt,
  parentId: parentId,
  priceCents: priceCents,
  receivedAs: receivedAs,
  readingSeconds: readingSeconds,
  format: format,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  updatedAt: DateTime(2026),
);

ReadingSession _session(int bookId, DateTime start, int seconds) =>
    ReadingSession(
      id: bookId * 100 + start.month,
      bookId: bookId,
      startedAt: start,
      endedAt: start.add(Duration(seconds: seconds)),
      durationSeconds: seconds,
      startPage: 0,
    );

StatDefinition _def(
  StatMeasure measure, {
  StatGrouping? grouping,
  StatPeriod period = const StatAllTime(),
  Set<BookStatus> statuses = const {},
  Set<int> tagIds = const {},
}) => StatDefinition(
  measure: measure,
  grouping: grouping,
  period: period,
  chart: StatDefinition.chartsFor(grouping).first,
  statuses: statuses,
  tagIds: tagIds,
);

double? _single(StatResult result) => switch (result) {
  StatSingle(:final value) => value,
  StatSeries() => null,
};

Map<StatKey, double> _series(StatResult result) => switch (result) {
  StatSingle() => const {},
  StatSeries(:final entries) => {for (final e in entries) e.key: e.value},
};

/// The engine of user-defined statistics (spec 005, T5-02).
void main() {
  test('pages read in a year as one number', () {
    final books = [
      _book(1, pages: 300, finishedAt: DateTime(2026, 2, 1)),
      _book(2, pages: 200, finishedAt: DateTime(2025, 2, 1)),
      _book(3, pages: 999, status: BookStatus.reading),
    ];
    final result = StatQuery.evaluate(
      _def(StatMeasure.pagesRead, period: const StatYear(2026)),
      books: books,
    );
    expect(_single(result), 300);
  });

  test('books per month of the year, with their ids for the drill-down', () {
    final books = [
      _book(1, finishedAt: DateTime(2026, 3, 1)),
      _book(2, finishedAt: DateTime(2026, 3, 9)),
      _book(3, finishedAt: DateTime(2026, 5, 9)),
    ];
    final result = StatQuery.evaluate(
      _def(
        StatMeasure.pagesRead,
        grouping: StatGrouping.month,
        period: const StatYear(2026),
      ),
      books: [for (final b in books) b.copyWith(pageCount: const Value(10))],
    );
    expect(_series(result), {
      for (var m = 1; m <= 12; m++)
        StatMonth(m): m == 3 ? 20.0 : (m == 5 ? 10.0 : 0.0),
    });
    final march = (result as StatSeries).entries.firstWhere(
      (e) => e.key == const StatMonth(3),
    );
    expect(march.bookIds, {1, 2});
  });

  test('reading time counts sessions and manual time, nothing else', () {
    final books = [
      _book(1, readingSeconds: 600, finishedAt: DateTime(2026, 1, 5)),
      // Start and finish date but no time: no reading time.
      _book(2, finishedAt: DateTime(2026, 1, 9)),
    ];
    final result = StatQuery.evaluate(
      _def(StatMeasure.readingTime),
      books: books,
      sessions: [_session(1, DateTime(2026, 1, 2), 1200)],
    );
    expect(_single(result), 1800);
  });

  test('average rating ignores unrated books', () {
    final result = StatQuery.evaluate(
      _def(StatMeasure.averageRating, grouping: StatGrouping.genre),
      books: [
        _book(1, rating: 4, genre: 'Krimi'),
        _book(2, rating: 2, genre: 'Krimi'),
        _book(3, genre: 'Krimi'),
        _book(4, rating: 5, genre: 'Fantasy'),
      ],
    );
    expect(_series(result), {
      const StatText('Krimi'): 3.0,
      const StatText('Fantasy'): 5.0,
    });
  });

  test('spending counts a slipcase once, not its volumes (ADR-0003)', () {
    final result = StatQuery.evaluate(
      _def(StatMeasure.spending, grouping: StatGrouping.year),
      books: [
        _book(1, priceCents: 3000, createdAt: DateTime(2025, 4, 1)),
        _book(2, priceCents: 999, parentId: 1),
        _book(3, priceCents: 1500, createdAt: DateTime(2026, 4, 1)),
      ],
    );
    expect(_series(result), {
      const StatYearKey(2025): 3000.0,
      const StatYearKey(2026): 1500.0,
    });
  });

  test('reading measures count volumes, not the slipcase', () {
    final result = StatQuery.evaluate(
      _def(StatMeasure.books),
      books: [_book(1), _book(2, parentId: 1), _book(3, parentId: 1)],
    );
    expect(_single(result), 2);
  });

  test('a book counts once per tag', () {
    final result = StatQuery.evaluate(
      _def(StatMeasure.books, grouping: StatGrouping.tag),
      books: [_book(1), _book(2)],
      tagsByBook: {
        1: {10, 11},
        2: {10},
      },
    );
    expect(_series(result), {const StatTag(10): 2.0, const StatTag(11): 1.0});
  });

  test('filters narrow the books first', () {
    final result = StatQuery.evaluate(
      _def(StatMeasure.books, statuses: {BookStatus.unread}, tagIds: {10}),
      books: [
        _book(1, status: BookStatus.unread),
        _book(2, status: BookStatus.unread),
        _book(3),
      ],
      tagsByBook: {
        1: {10},
        3: {10},
      },
    );
    expect(_single(result), 1);
  });

  test('categories are sorted by value, largest first', () {
    final result = StatQuery.evaluate(
      _def(StatMeasure.books, grouping: StatGrouping.author),
      books: [
        _book(1, authors: ['Selten']),
        _book(2, authors: ['Oft']),
        _book(3, authors: ['Oft']),
      ],
    );
    expect((result as StatSeries).entries.map((e) => e.key), [
      const StatText('Oft'),
      const StatText('Selten'),
    ]);
  });

  test('no books gives zero or an empty series, never a crash', () {
    expect(_single(StatQuery.evaluate(_def(StatMeasure.books), books: [])), 0);
    expect(
      _single(StatQuery.evaluate(_def(StatMeasure.averageRating), books: [])),
      isNull,
    );
    expect(
      _series(
        StatQuery.evaluate(
          _def(StatMeasure.books, grouping: StatGrouping.genre),
          books: [],
        ),
      ),
      isEmpty,
    );
  });

  test(
    'the years a library offers, newest first, the current one included',
    () {
      final library = StatLibrary(
        books: [
          _book(1, finishedAt: DateTime(2024, 5, 1), createdAt: DateTime(2025)),
          _book(2, status: BookStatus.unread, createdAt: DateTime(2022, 3)),
        ],
        sessions: [_session(1, DateTime(2023, 2, 1), 60)],
      );
      expect(library.years(now: DateTime(2026, 6)), [
        2026,
        2025,
        2024,
        2023,
        2022,
      ]);
    },
  );

  test('a deleted tag in a filter is ignored, not a filter on nothing', () {
    final library = StatLibrary(
      books: [_book(1), _book(2)],
      tagsByBook: {
        1: {10},
      },
      tagNames: {10: 'Krimi'},
    );
    expect(_single(library.evaluate(_def(StatMeasure.books, tagIds: {99}))), 2);
    expect(
      _single(library.evaluate(_def(StatMeasure.books, tagIds: {10, 99}))),
      1,
    );
  });
}
