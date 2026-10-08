import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

/// Serializes the full library (books, locations, series, lending) to portable
/// JSON/CSV so users can export all their data (Constitution Article I.3).
class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  Future<String> exportJson() async {
    final books = await _db.select(_db.books).get();
    final locations = await _db.select(_db.locations).get();
    final series = await _db.select(_db.seriesTable).get();
    final lending = await _db.select(_db.lending).get();
    final sessions = await _db.select(_db.readingSessions).get();
    final notes = await _db.select(_db.bookNotes).get();
    final tags = await _db.select(_db.tags).get();
    final bookTags = await _db.select(_db.bookTags).get();
    final goals = await _db.select(_db.readingGoals).get();

    return jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books.map(_book).toList(),
      'locations': locations.map(_location).toList(),
      'series': series.map(_series).toList(),
      'lending': lending.map(_lending).toList(),
      'readingSessions': sessions.map(_session).toList(),
      'notes': notes.map(_note).toList(),
      'tags': tags.map((t) => {'id': t.id, 'name': t.name}).toList(),
      'bookTags': bookTags
          .map((t) => {'bookId': t.bookId, 'tagId': t.tagId})
          .toList(),
      'readingGoals': goals
          .map(
            (g) => {
              'year': g.year,
              'targetBooks': g.targetBooks,
              'targetPages': g.targetPages,
            },
          )
          .toList(),
    });
  }

  /// Separates several notes (or quotes) inside one CSV cell.
  static const noteSeparator = '\n---\n';

  /// Separates tags inside one CSV cell (Openreads convention).
  static const tagSeparator = '|||||';

  /// The CSV header: the Openreads columns (`doc/csv.md`) first — so the file
  /// can be imported by Openreads-compatible tools and by OpenShelf itself —
  /// followed by the OpenShelf additions.
  static const csvColumns = [
    'title',
    'subtitle',
    'author',
    'description',
    'status',
    'favourite',
    'deleted',
    'rating',
    'pages',
    'publication_year',
    'isbn',
    'olid',
    'tags',
    'my_review',
    'notes',
    'book_format',
    'readings',
    'date_added',
    'date_modified',
    // OpenShelf additions
    'isbn13',
    'isbn10',
    'publisher',
    'language',
    'current_page',
    'finished_at',
    'series',
    'series_volume',
    'location',
    'lending_status',
    'borrower',
    'lent_at',
    'expected_return',
    'quotes',
    'cover_url',
    'genre',
    'price',
    'received_at',
    'reading_seconds',
  ];

  /// Every book (trashed ones flagged `deleted=true`) with all of its data:
  /// tags, notes, quotes, reading dates, location path, series and the current
  /// lending status. Lossless in full only as JSON; the CSV flattens notes and
  /// sessions into single cells.
  Future<String> exportBooksCsv() async {
    final books = await _db.select(_db.books).get();
    final locations = {
      for (final l in await _db.select(_db.locations).get()) l.id: l,
    };
    final series = {
      for (final s in await _db.select(_db.seriesTable).get()) s.id: s.name,
    };
    final tagNames = {
      for (final t in await _db.select(_db.tags).get()) t.id: t.name,
    };

    final tagsByBook = <int, List<String>>{};
    for (final link in await _db.select(_db.bookTags).get()) {
      final name = tagNames[link.tagId];
      if (name != null) (tagsByBook[link.bookId] ??= []).add(name);
    }
    final notesByBook = <int, List<BookNote>>{};
    for (final n in await (_db.select(
      _db.bookNotes,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get()) {
      (notesByBook[n.bookId] ??= []).add(n);
    }
    final sessionsByBook = <int, List<ReadingSession>>{};
    for (final s in await (_db.select(
      _db.readingSessions,
    )..orderBy([(t) => OrderingTerm.asc(t.startedAt)])).get()) {
      (sessionsByBook[s.bookId] ??= []).add(s);
    }
    final lendingByBook = <int, LendingData>{};
    for (final l in await (_db.select(
      _db.lending,
    )..orderBy([(t) => OrderingTerm.asc(t.lentAt)])).get()) {
      if (l.returnedAt == null) lendingByBook[l.bookId] = l;
    }

    String locationPath(int? id) {
      final names = <String>[];
      var current = id == null ? null : locations[id];
      var guard = 0;
      while (current != null && guard++ < 16) {
        names.insert(0, current.name);
        final parent = current.parentId;
        current = parent == null ? null : locations[parent];
      }
      return names.join(' > ');
    }

    final rows = <List<String>>[csvColumns];
    for (final b in books) {
      final notes = notesByBook[b.id] ?? const <BookNote>[];
      final lending = lendingByBook[b.id];
      rows.add([
        b.title,
        b.subtitle ?? '',
        b.authors.join(', '),
        b.description ?? '',
        _status(b.status),
        b.isFavorite.toString(),
        (b.deletedAt != null).toString(),
        b.rating == 0 ? '' : b.rating.toString(),
        b.pageCount?.toString() ?? '',
        b.publishedYear?.toString() ?? '',
        b.isbn13 ?? b.isbn10 ?? '',
        b.olid ?? '',
        (tagsByBook[b.id] ?? const <String>[]).join(tagSeparator),
        b.review ?? '',
        [
          for (final n in notes)
            if (n.kind == NoteKind.note) n.content,
        ].join(noteSeparator),
        b.format?.name ?? '',
        [
          for (final s in sessionsByBook[b.id] ?? const <ReadingSession>[])
            '${s.startedAt.toIso8601String()}|'
                '${s.endedAt?.toIso8601String() ?? ''}|'
                '${s.durationSeconds > 0 ? s.durationSeconds * 1000 : ''}',
        ].join(';'),
        b.createdAt.toIso8601String(),
        b.updatedAt.toIso8601String(),
        b.isbn13 ?? '',
        b.isbn10 ?? '',
        b.publisher ?? '',
        b.language ?? '',
        b.currentPage.toString(),
        b.finishedAt?.toIso8601String() ?? '',
        b.seriesId == null ? '' : series[b.seriesId] ?? '',
        b.seriesVolume?.toString() ?? '',
        locationPath(b.locationId),
        lending == null ? 'available' : 'lent',
        lending?.borrowerName ?? '',
        lending?.lentAt.toIso8601String() ?? '',
        lending?.expectedReturn?.toIso8601String() ?? '',
        [
          for (final n in notes)
            if (n.kind == NoteKind.quote) n.content,
        ].join(noteSeparator),
        b.coverUrl ?? '',
        b.genre ?? '',
        _price(b.priceCents),
        b.receivedAt?.toIso8601String() ?? '',
        b.readingSeconds?.toString() ?? '',
      ]);
    }
    return const ListToCsvConverter(eol: '\n').convert(rows);
  }

  /// Euro cents as a plain `12.90` so spreadsheets and other tools can read it.
  static String _price(int? cents) => cents == null
      ? ''
      : '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

  /// Openreads status vocabulary where there is an equivalent.
  static String _status(BookStatus s) => switch (s) {
    BookStatus.read => 'finished',
    BookStatus.reading => 'in_progress',
    BookStatus.wishlist => 'planned',
    BookStatus.dnf => 'abandoned',
    BookStatus.unread => 'unread',
    BookStatus.reReading => 're_reading',
  };

  Map<String, dynamic> _book(Book b) => {
    'id': b.id,
    'isbn13': b.isbn13,
    'isbn10': b.isbn10,
    'title': b.title,
    'subtitle': b.subtitle,
    'authors': b.authors,
    'publisher': b.publisher,
    'publishedYear': b.publishedYear,
    'pageCount': b.pageCount,
    'format': b.format?.name,
    'language': b.language,
    'status': b.status.name,
    'rating': b.rating,
    'locationId': b.locationId,
    'seriesId': b.seriesId,
    'seriesVolume': b.seriesVolume,
    'description': b.description,
    'coverUrl': b.coverUrl,
    'coverLocalPath': b.coverLocalPath,
    'metadataSource': b.metadataSource?.name,
    'editedFields': b.editedFields,
    'currentPage': b.currentPage,
    'finishedAt': b.finishedAt?.toIso8601String(),
    'isFavorite': b.isFavorite,
    'review': b.review,
    'olid': b.olid,
    'genre': b.genre,
    'priceCents': b.priceCents,
    'receivedAt': b.receivedAt?.toIso8601String(),
    'readingSeconds': b.readingSeconds,
    'deletedAt': b.deletedAt?.toIso8601String(),
    'createdAt': b.createdAt.toIso8601String(),
    'updatedAt': b.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _location(Location l) => {
    'id': l.id,
    'name': l.name,
    'type': l.type.name,
    'parentId': l.parentId,
    'sortOrder': l.sortOrder,
  };

  Map<String, dynamic> _series(Series s) => {
    'id': s.id,
    'name': s.name,
    'totalPlannedVolumes': s.totalPlannedVolumes,
  };

  Map<String, dynamic> _lending(LendingData l) => {
    'id': l.id,
    'bookId': l.bookId,
    'borrowerName': l.borrowerName,
    'lentAt': l.lentAt.toIso8601String(),
    'expectedReturn': l.expectedReturn?.toIso8601String(),
    'returnedAt': l.returnedAt?.toIso8601String(),
  };

  Map<String, dynamic> _session(ReadingSession s) => {
    'id': s.id,
    'bookId': s.bookId,
    'startedAt': s.startedAt.toIso8601String(),
    'endedAt': s.endedAt?.toIso8601String(),
    'durationSeconds': s.durationSeconds,
    'startPage': s.startPage,
    'endPage': s.endPage,
  };

  Map<String, dynamic> _note(BookNote n) => {
    'id': n.id,
    'bookId': n.bookId,
    'kind': n.kind.name,
    'content': n.content,
    'pageNumber': n.pageNumber,
    'createdAt': n.createdAt.toIso8601String(),
    'updatedAt': n.updatedAt.toIso8601String(),
  };
}
