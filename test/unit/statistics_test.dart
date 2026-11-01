import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/domain/models/statistics.dart';

Book _book(
  int id, {
  required BookStatus status,
  int? pages,
  int? locationId,
  List<String> authors = const ['Author'],
  String? title,
  double rating = 0.0,
  DateTime? finishedAt,
  DateTime? createdAt,
  int? parentId,
}) {
  return Book(
    id: id,
    isbn13: null,
    isbn10: null,
    title: title ?? 'Book $id',
    subtitle: null,
    authors: authors,
    publisher: null,
    publishedYear: null,
    pageCount: pages,
    format: null,
    language: null,
    status: status,
    rating: rating,
    locationId: locationId,
    parentId: parentId,
    seriesId: null,
    seriesVolume: null,
    currentPage: 0,
    finishedAt: finishedAt,
    isFavorite: false,
    coverNotFound: false,
    review: null,
    description: null,
    coverUrl: null,
    coverLocalPath: null,
    metadataSource: null,
    editedFields: const [],
    createdAt: createdAt ?? DateTime(2020),
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

  group('years and months', () {
    final books = [
      _book(
        1,
        status: BookStatus.read,
        pages: 100,
        finishedAt: DateTime(2024, 1, 10),
        rating: 4,
      ),
      _book(
        2,
        status: BookStatus.read,
        pages: 200,
        finishedAt: DateTime(2024, 1, 25),
        rating: 5,
      ),
      _book(
        3,
        status: BookStatus.read,
        pages: 300,
        finishedAt: DateTime(2024, 12, 31),
      ),
      _book(
        4,
        status: BookStatus.read,
        pages: 400,
        finishedAt: DateTime(2025, 6, 1),
        rating: 3,
      ),
      // No finish date: counts when it was added (the yearly-goal rule).
      _book(
        5,
        status: BookStatus.read,
        pages: 50,
        createdAt: DateTime(2025, 3, 3),
      ),
      _book(6, status: BookStatus.reading, pages: 999),
    ];

    test('lists the years with finished books, newest first', () {
      final stats = BookStatistics.compute(books, const []);
      expect(stats.years, [2025, 2024]);
      expect(stats.year, isNull);
    });

    test('without a year the whole library is counted', () {
      final stats = BookStatistics.compute(books, const []);
      expect(stats.totalBooks, 6);
      expect(stats.pagesRead, 1050);
    });

    test('a year counts only books finished in that year', () {
      final stats = BookStatistics.compute(books, const [], year: 2024);

      expect(stats.year, 2024);
      expect(stats.totalBooks, 3);
      expect(stats.pagesRead, 600);
      expect(stats.statusCounts[BookStatus.read], 3);
      expect(stats.statusCounts[BookStatus.reading], 0);
      expect(stats.years, [2025, 2024], reason: 'the selector keeps all years');
    });

    test('books without a finish date fall back to when they were added', () {
      final stats = BookStatistics.compute(books, const [], year: 2025);
      expect(stats.totalBooks, 2);
      expect(stats.pagesRead, 450);
    });

    test('the monthly breakdown has twelve months', () {
      final stats = BookStatistics.compute(books, const [], year: 2024);

      expect(stats.monthly, hasLength(12));
      expect(
        [for (final m in stats.monthly) m.month],
        [for (var i = 1; i <= 12; i++) i],
      );
      expect(stats.monthly[0].books, 2);
      expect(stats.monthly[0].pages, 300);
      expect(stats.monthly[11].books, 1);
      expect(stats.monthly[11].pages, 300);
      expect(stats.monthly.where((m) => m.books == 0), hasLength(10));
    });

    test('over all years the months add up across years', () {
      final stats = BookStatistics.compute(books, const []);
      expect(stats.monthly[0].books, 2);
      expect(stats.monthly[5].books, 1, reason: 'June 2025');
      expect(stats.monthly[2].books, 1, reason: 'March 2025, by added date');
      expect(stats.monthly.fold<int>(0, (s, m) => s + m.books), 5);
    });

    test('an empty library has twelve empty months and no years', () {
      final stats = BookStatistics.compute(const [], const []);
      expect(stats.years, isEmpty);
      expect(stats.monthly, hasLength(12));
      expect(stats.monthly.every((m) => m.books == 0 && m.pages == 0), isTrue);
    });
  });

  group('averages and records', () {
    final books = [
      _book(1, status: BookStatus.read, pages: 100, title: 'Kurz', rating: 4),
      _book(2, status: BookStatus.read, pages: 500, title: 'Lang', rating: 5),
      _book(3, status: BookStatus.read, pages: 300, title: 'Mittel'),
      _book(
        4,
        status: BookStatus.reading,
        pages: 9000,
        title: 'Läuft',
        rating: 1,
      ),
    ];

    test('average rating counts rated finished books only', () {
      final stats = BookStatistics.compute(books, const []);
      expect(stats.averageRating, 4.5);
    });

    test('average pages and the longest / shortest finished book', () {
      final stats = BookStatistics.compute(books, const []);

      expect(stats.averagePages, 300);
      expect(
        (stats.longestBook!.name, stats.longestBook!.count),
        ('Lang', 500),
      );
      expect(
        (stats.shortestBook!.name, stats.shortestBook!.count),
        ('Kurz', 100),
      );
    });

    test('nothing to average gives null', () {
      final stats = BookStatistics.compute([
        _book(1, status: BookStatus.unread),
        _book(2, status: BookStatus.read),
      ], const []);

      expect(stats.averageRating, isNull);
      expect(stats.averagePages, isNull);
      expect(stats.longestBook, isNull);
      expect(stats.fastestBook, isNull);
      expect(stats.averageReadingTime, isNull);
    });

    ReadingSession session(
      int book,
      DateTime start,
      DateTime? end,
      int seconds,
    ) => ReadingSession(
      id: book * 100 + start.day,
      bookId: book,
      startedAt: start,
      endedAt: end,
      durationSeconds: seconds,
      startPage: 0,
    );

    test('reading time comes from tracked sessions', () {
      final stats = BookStatistics.compute(
        books,
        const [],
        sessions: [
          session(1, DateTime(2026, 1, 1), DateTime(2026, 1, 1, 1), 3600),
          session(1, DateTime(2026, 1, 2), DateTime(2026, 1, 2, 1), 3600),
          session(2, DateTime(2026, 2, 1), DateTime(2026, 2, 1, 4), 14400),
        ],
      );

      expect(
        (stats.fastestBook!.name, stats.fastestBook!.count),
        ('Kurz', 7200),
      );
      expect(
        (stats.slowestBook!.name, stats.slowestBook!.count),
        ('Lang', 14400),
      );
      expect(stats.averageReadingTime, const Duration(seconds: 10800));
    });

    test('without tracked time the span of the dates is used', () {
      final stats = BookStatistics.compute(
        books,
        const [],
        sessions: [
          // Legacy reading: start and finish date, no duration.
          session(3, DateTime(2026, 1, 1), DateTime(2026, 1, 3), 0),
        ],
      );

      expect(stats.fastestBook!.name, 'Mittel');
      expect(stats.fastestBook!.count, const Duration(days: 2).inSeconds);
    });

    test('unfinished books never count for records', () {
      final stats = BookStatistics.compute(
        books,
        const [],
        sessions: [
          session(4, DateTime(2026, 1, 1), DateTime(2026, 1, 2), 90000),
        ],
      );
      expect(stats.slowestBook, isNull);
      expect(stats.longestBook!.name, 'Lang');
    });
  });

  group('slipcases (ADR-0003)', () {
    final books = [
      _book(1, status: BookStatus.read, pages: 300, locationId: 7),
      // The slipcase: the physical object with the summed page count.
      _book(
        2,
        status: BookStatus.read,
        pages: 1184,
        locationId: 7,
        title: 'Schuber',
      ),
      // A volume with its own location must not count the box twice.
      _book(3, status: BookStatus.read, pages: 500, parentId: 2, locationId: 7),
      _book(
        4,
        status: BookStatus.read,
        pages: 684,
        parentId: 2,
        title: 'Band 2',
      ),
    ];
    const locations = [
      Location(id: 7, name: 'Regal', type: LocationType.shelf, sortOrder: 0),
    ];

    test('reading statistics count the volumes, not the slipcase', () {
      final stats = BookStatistics.compute(books, locations);

      expect(stats.totalBooks, 3);
      expect(stats.statusCounts[BookStatus.read], 3);
      expect(stats.pagesRead, 300 + 500 + 684);
      expect(stats.longestBook!.name, 'Band 2');
      expect(stats.averagePages, ((300 + 500 + 684) / 3).round());
      expect(stats.monthly.fold<int>(0, (s, m) => s + m.books), 3);
    });

    test('locations count the physical objects once', () {
      final stats = BookStatistics.compute(books, locations);

      expect(stats.topLocations.single.count, 2);
    });

    test('the goal counts volumes', () {
      final goal = GoalProgress.compute(
        year: 2020,
        target: 10,
        books: books,
        now: DateTime(2020, 6),
      );

      expect(goal.completed, 3);
      expect(goal.pagesRead, 300 + 500 + 684);
    });
  });
}
