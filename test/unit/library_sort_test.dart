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
  DateTime? updatedAt,
  BookStatus status = BookStatus.unread,
  int? pages,
  int currentPage = 0,
  int? year,
  DateTime? finishedAt,
}) => Book(
  id: id,
  title: title,
  authors: authors,
  status: status,
  rating: rating,
  pageCount: pages,
  publishedYear: year,
  finishedAt: finishedAt,
  currentPage: currentPage,
  editedFields: const [],
  isFavorite: false,
  createdAt: createdAt ?? DateTime(2026),
  updatedAt: updatedAt ?? DateTime(2026),
);

List<String> sorted(LibrarySort sort, List<Book> books) =>
    sort.apply(books).map((b) => b.title).toList();

void main() {
  test('the default sorts by title A→Z', () {
    final books = [
      book(1, 'Mittel', createdAt: DateTime(2020)),
      book(2, 'Zuletzt', createdAt: DateTime(2026)),
      book(3, 'anfang', createdAt: DateTime(2023)),
    ];
    expect(sorted(const LibrarySort(), books), ['anfang', 'Mittel', 'Zuletzt']);
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

  test('umlauts and ß sort like their base letters (DIN 5007)', () {
    final books = [
      book(1, 'Zorn'),
      book(2, 'Über Menschen'),
      book(3, 'Ärztin'),
      book(4, 'Apfel'),
      book(5, 'Straße'),
      book(6, 'Strand'),
    ];
    expect(sorted(const LibrarySort(), books), [
      'Apfel',
      'Ärztin',
      'Strand',
      'Straße',
      'Über Menschen',
      'Zorn',
    ]);
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
    expect(sorted(sort, books), [
      'D',
      'A',
      'C',
      'B',
      'E',
    ], reason: 'books without author sort last');
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
    const start = LibrarySort(); // title, A→Z
    final flipped = start.select(LibrarySortField.title);
    expect(flipped.field, LibrarySortField.title);
    expect(flipped.ascending, isFalse);

    final author = start.select(LibrarySortField.author);
    expect(author.field, LibrarySortField.author);
    expect(author.ascending, isTrue, reason: 'text starts A→Z');

    final rating = author.select(LibrarySortField.rating);
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

  group('all twelve criteria', () {
    test('there are twelve', () {
      expect(LibrarySortField.values, hasLength(12));
    });

    test('pages: unknown page counts always sort last', () {
      final books = [
        book(1, 'Kurz', pages: 100),
        book(2, 'Ohne'),
        book(3, 'Lang', pages: 900),
      ];
      expect(
        sorted(
          const LibrarySort(field: LibrarySortField.pages, ascending: false),
          books,
        ),
        ['Lang', 'Kurz', 'Ohne'],
      );
      expect(
        sorted(
          const LibrarySort(field: LibrarySortField.pages, ascending: true),
          books,
        ),
        ['Kurz', 'Lang', 'Ohne'],
        reason: 'still last when ascending',
      );
    });

    test('publication year', () {
      final books = [
        book(1, 'Alt', year: 1950),
        book(2, 'Neu', year: 2024),
        book(3, 'Unbekannt'),
      ];
      expect(
        sorted(
          const LibrarySort(
            field: LibrarySortField.publicationYear,
            ascending: false,
          ),
          books,
        ),
        ['Neu', 'Alt', 'Unbekannt'],
      );
    });

    test('date modified', () {
      final books = [
        book(1, 'A', updatedAt: DateTime(2020)),
        book(2, 'B', updatedAt: DateTime(2026)),
        book(3, 'C', updatedAt: DateTime(2023)),
      ];
      expect(
        sorted(
          const LibrarySort(field: LibrarySortField.modified, ascending: false),
          books,
        ),
        ['B', 'C', 'A'],
      );
    });

    test('status: reading first, finished and abandoned last', () {
      final books = [
        book(1, 'Fertig', status: BookStatus.read),
        book(2, 'Läuft', status: BookStatus.reading),
        book(3, 'Offen', status: BookStatus.unread),
        book(4, 'Abbruch', status: BookStatus.dnf),
        book(5, 'Wunsch', status: BookStatus.wishlist),
        book(6, 'Nochmal', status: BookStatus.reReading),
      ];
      expect(
        sorted(
          const LibrarySort(field: LibrarySortField.status, ascending: true),
          books,
        ),
        ['Läuft', 'Nochmal', 'Offen', 'Wunsch', 'Fertig', 'Abbruch'],
      );
    });

    test('start date, finish date and last read use the sessions', () {
      final books = [
        book(1, 'A', status: BookStatus.read, finishedAt: DateTime(2024, 5)),
        book(2, 'B', status: BookStatus.read),
        book(3, 'C', status: BookStatus.reading),
        book(4, 'D'),
      ];
      final spans = {
        1: ReadingSpan(
          firstStart: DateTime(2024, 4),
          lastEnd: DateTime(2024, 5),
        ),
        2: ReadingSpan(
          firstStart: DateTime(2025, 1),
          lastEnd: DateTime(2025, 2),
        ),
        3: ReadingSpan(
          firstStart: DateTime(2026, 3),
          lastEnd: DateTime(2026, 3),
        ),
      };

      List<String> by(LibrarySortField f) => const LibrarySort()
          .select(f)
          .apply(books, spans: spans)
          .map((b) => b.title)
          .toList();
      // select() starts numbers/dates high → low.
      expect(by(LibrarySortField.startDate), ['C', 'B', 'A', 'D']);
      expect(
        by(LibrarySortField.finishDate),
        ['B', 'A', 'C', 'D'],
        reason:
            'B has no finishedAt: a read book falls back to its last '
            'session; C is not finished',
      );
      expect(by(LibrarySortField.lastRead), ['C', 'B', 'A', 'D']);
    });

    test('lastReadAt takes the later of finish date and last session', () {
      final b = book(1, 'A', finishedAt: DateTime(2024, 6));
      expect(
        lastReadAt(b, ReadingSpan(lastEnd: DateTime(2024, 8))),
        DateTime(2024, 8),
      );
      expect(
        lastReadAt(b, ReadingSpan(lastEnd: DateTime(2024, 1))),
        DateTime(2024, 6),
      );
      expect(lastReadAt(b, null), DateTime(2024, 6));
      expect(lastReadAt(book(2, 'B'), null), isNull);
    });

    test('readingSpans groups sessions per book', () {
      final spans = readingSpans([
        ReadingSession(
          id: 1,
          bookId: 7,
          startedAt: DateTime(2026, 1, 5),
          endedAt: DateTime(2026, 1, 6),
          durationSeconds: 60,
          startPage: 0,
        ),
        ReadingSession(
          id: 2,
          bookId: 7,
          startedAt: DateTime(2026, 1, 1),
          endedAt: DateTime(2026, 1, 2),
          durationSeconds: 60,
          startPage: 0,
        ),
        ReadingSession(
          id: 3,
          bookId: 8,
          startedAt: DateTime(2026, 3, 1),
          durationSeconds: 0,
          startPage: 0,
        ),
      ]);
      expect(spans[7]!.firstStart, DateTime(2026, 1, 1));
      expect(spans[7]!.lastEnd, DateTime(2026, 1, 6));
      expect(spans[8]!.firstStart, DateTime(2026, 3, 1));
      expect(spans[8]!.lastEnd, DateTime(2026, 3, 1), reason: 'running');
    });

    test('select(): text fields start A→Z, status too, dates high→low', () {
      expect(
        const LibrarySort().select(LibrarySortField.status).ascending,
        isTrue,
      );
      expect(
        const LibrarySort().select(LibrarySortField.pages).ascending,
        isFalse,
      );
      expect(
        const LibrarySort().select(LibrarySortField.finishDate).ascending,
        isFalse,
      );
    });
  });
}
