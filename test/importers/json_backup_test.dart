import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/json_backup_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// Export → import must lose nothing: the library restored from an OpenShelf
/// JSON backup is identical to the one that was exported.
void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    await source.customSelect('select 1').get();
    await target.customSelect('select 1').get();
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<ImportResult> restore(AppDatabase into, String json) {
    final service = ImportService(BookRepositoryImpl(BooksDao(into)));
    return service.import(
      JsonBackupImporter().parse(
        ImportFile(
          name: 'backup.json',
          content: json,
          type: ImportFileType.json,
        ),
      ),
    );
  }

  /// A library that uses every table and every column.
  Future<void> fillSource() async {
    final room = await source
        .into(source.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Wohnzimmer',
            type: LocationType.room,
            sortOrder: const Value(1),
          ),
        );
    final shelf = await source
        .into(source.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Regal 1',
            type: LocationType.shelf,
            parentId: Value(room),
          ),
        );
    final compartment = await source
        .into(source.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Fach A',
            type: LocationType.compartment,
            parentId: Value(shelf),
          ),
        );
    // An empty shelf that no book stands on.
    final cellar = await source
        .into(source.locations)
        .insert(
          LocationsCompanion.insert(name: 'Keller', type: LocationType.room),
        );
    await source
        .into(source.locations)
        .insert(
          LocationsCompanion.insert(
            name: 'Kiste',
            type: LocationType.shelf,
            parentId: Value(cellar),
          ),
        );
    final series = await source
        .into(source.seriesTable)
        .insert(
          SeriesTableCompanion.insert(
            name: 'Die Reihe',
            totalPlannedVolumes: const Value(7),
          ),
        );

    final full = await source
        .into(source.books)
        .insert(
          BooksCompanion.insert(
            title: 'Der Vorleser',
            subtitle: const Value('Roman'),
            authors: const ['Bernhard Schlink', 'Zweite Autorin'],
            editedFields: const ['title', 'pageCount'],
            isbn13: const Value('9783257229530'),
            isbn10: const Value('3257229534'),
            publisher: const Value('Diogenes'),
            publishedYear: const Value(1995),
            pageCount: const Value(207),
            format: const Value(BookFormat.hardcover),
            language: const Value('de'),
            status: const Value(BookStatus.read),
            rating: const Value(4.5),
            locationId: Value(compartment),
            seriesId: Value(series),
            seriesVolume: const Value(2.5),
            description: const Value('Eine Geschichte.\nMit Zeilenumbruch.'),
            coverUrl: const Value('https://example.org/cover.jpg'),
            coverLocalPath: const Value('/device/only/cover.jpg'),
            metadataSource: const Value(MetadataSource.dnb),
            currentPage: const Value(207),
            finishedAt: Value(DateTime(2025, 3, 14, 18, 30)),
            isFavorite: const Value(true),
            review: const Value('Stark; "bewegend", und klug.'),
            olid: const Value('OL123M'),
            createdAt: Value(DateTime(2024, 1, 2, 3, 4, 5)),
            updatedAt: Value(DateTime(2025, 6, 7, 8, 9, 10)),
          ),
        );
    final reading = await source
        .into(source.books)
        .insert(
          BooksCompanion.insert(
            title: 'Laufendes Buch',
            authors: const ['A'],
            editedFields: const [],
            pageCount: const Value(300),
            status: const Value(BookStatus.reading),
            currentPage: const Value(120),
            createdAt: Value(DateTime(2026, 2, 1)),
            updatedAt: Value(DateTime(2026, 2, 2)),
          ),
        );
    await source
        .into(source.books)
        .insert(
          BooksCompanion.insert(
            title: 'Im Papierkorb',
            authors: const ['B'],
            editedFields: const [],
            deletedAt: Value(DateTime(2026, 4, 1, 12)),
            createdAt: Value(DateTime(2023, 1, 1)),
            updatedAt: Value(DateTime(2026, 4, 1, 12)),
          ),
        );
    await source
        .into(source.books)
        .insert(
          BooksCompanion.insert(
            title: 'Minimal',
            authors: const [],
            editedFields: const [],
            createdAt: Value(DateTime(2022, 5, 5)),
            updatedAt: Value(DateTime(2022, 5, 5)),
          ),
        );

    Future<void> session(
      int book, {
      required DateTime start,
      DateTime? end,
      int seconds = 0,
      int startPage = 0,
      int? endPage,
    }) => source
        .into(source.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            bookId: book,
            startedAt: start,
            endedAt: Value(end),
            durationSeconds: Value(seconds),
            startPage: Value(startPage),
            endPage: Value(endPage),
          ),
        );
    await session(
      full,
      start: DateTime(2025, 3, 10, 20),
      end: DateTime(2025, 3, 10, 21),
      seconds: 3600,
      endPage: 100,
    );
    await session(
      full,
      start: DateTime(2025, 3, 14, 17),
      end: DateTime(2025, 3, 14, 18, 30),
      seconds: 5400,
      startPage: 100,
      endPage: 207,
    );
    // The timer of the book being read is still running.
    await session(reading, start: DateTime(2026, 2, 3, 9), startPage: 120);

    await source
        .into(source.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: full,
            kind: NoteKind.quote,
            content: 'Ein Zitat, mit "Anführungszeichen".',
            pageNumber: const Value(42),
            createdAt: Value(DateTime(2025, 3, 11)),
            updatedAt: Value(DateTime(2025, 3, 12)),
          ),
        );
    await source
        .into(source.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: full,
            kind: NoteKind.note,
            content: 'Eine Notiz',
            createdAt: Value(DateTime(2025, 3, 13)),
            updatedAt: Value(DateTime(2025, 3, 13)),
          ),
        );

    final crime = await source
        .into(source.tags)
        .insert(TagsCompanion.insert(name: 'Krimi'));
    final uncanny = await source
        .into(source.tags)
        .insert(TagsCompanion.insert(name: 'Übernatürliches'));
    await source
        .into(source.tags)
        .insert(TagsCompanion.insert(name: 'Ohne Bücher'));
    await source
        .into(source.statTiles)
        .insert(
          StatTilesCompanion.insert(
            position: 0,
            title: 'Seiten 2026',
            definition: jsonEncode({
              'measure': 'pages_read',
              'grouping': 'month',
              'period': 'year:2026',
              'chart': 'bar',
              'tags': [uncanny],
            }),
            pinned: const Value(true),
            createdAt: DateTime(2026, 2, 1),
          ),
        );
    await source
        .into(source.statTiles)
        .insert(
          StatTilesCompanion.insert(
            position: 1,
            title: 'Alle Bücher',
            definition: jsonEncode({
              'measure': 'books',
              'period': 'all',
              'chart': 'number',
            }),
            createdAt: DateTime(2026, 2, 2),
          ),
        );
    for (final (book, tag) in [
      (full, crime),
      (full, uncanny),
      (reading, crime),
    ]) {
      await source
          .into(source.bookTags)
          .insert(BookTagsCompanion.insert(bookId: book, tagId: tag));
    }

    await source
        .into(source.lending)
        .insert(
          LendingCompanion.insert(
            bookId: full,
            borrowerName: 'Anna',
            lentAt: DateTime(2025, 5, 1),
            expectedReturn: Value(DateTime(2025, 5, 15)),
            returnedAt: Value(DateTime(2025, 5, 20)),
          ),
        );
    await source
        .into(source.lending)
        .insert(
          LendingCompanion.insert(
            bookId: reading,
            borrowerName: 'Ben',
            lentAt: DateTime(2026, 3, 1),
          ),
        );

    await source
        .into(source.readingGoals)
        .insert(
          ReadingGoalsCompanion.insert(
            year: const Value(2026),
            targetBooks: 24,
            targetPages: const Value(8000),
          ),
        );
    // A pages-only goal (Openreads allowed that).
    await source
        .into(source.readingGoals)
        .insert(
          ReadingGoalsCompanion.insert(
            year: const Value(2025),
            targetBooks: 0,
            targetPages: const Value(5000),
          ),
        );
  }

  /// The statistic tiles in display order, tag ids replaced by names.
  Future<List<String>> tiles(AppDatabase db) async {
    final tagName = {
      for (final t in await db.select(db.tags).get()) t.id: t.name,
    };
    final rows = await (db.select(
      db.statTiles,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    return [
      for (final r in rows)
        () {
          final definition = jsonDecode(r.definition) as Map<String, dynamic>;
          final tags = [
            for (final id in definition.remove('tags') as List? ?? const [])
              tagName[id],
          ];
          return '${r.title}|${r.pinned}|${jsonEncode(definition)}|$tags';
        }(),
    ];
  }

  /// Everything about a library, with database ids replaced by names, so that
  /// two databases can be compared for equality.
  Future<Map<String, Object?>> snapshot(AppDatabase db) async {
    final locations = {
      for (final l in await db.select(db.locations).get()) l.id: l,
    };
    String path(int? id) {
      final names = <String>[];
      var current = id == null ? null : locations[id];
      while (current != null) {
        names.insert(0, '${current.name}:${current.type.name}');
        current = current.parentId == null ? null : locations[current.parentId];
      }
      return names.join(' > ');
    }

    final series = {
      for (final s in await db.select(db.seriesTable).get()) s.id: s,
    };
    final tagName = {
      for (final t in await db.select(db.tags).get()) t.id: t.name,
    };
    final books = await db.select(db.books).get();
    final byId = {for (final b in books) b.id: b.title};

    List<Map<String, Object?>> rowsFor<T>(
      Iterable<T> rows,
      int Function(T) bookId,
      Map<String, Object?> Function(T) map,
    ) => [
      for (final r in rows) {'book': byId[bookId(r)], ...map(r)},
    ]..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));

    return {
      'books':
          [
            for (final b in books)
              {
                'title': b.title,
                'subtitle': b.subtitle,
                'authors': b.authors,
                'isbn13': b.isbn13,
                'isbn10': b.isbn10,
                'publisher': b.publisher,
                'publishedYear': b.publishedYear,
                'pageCount': b.pageCount,
                'format': b.format?.name,
                'language': b.language,
                'status': b.status.name,
                'rating': b.rating,
                'location': path(b.locationId),
                'series': series[b.seriesId]?.name,
                'seriesTotal': series[b.seriesId]?.totalPlannedVolumes,
                'seriesVolume': b.seriesVolume,
                'description': b.description,
                'coverUrl': b.coverUrl,
                'metadataSource': b.metadataSource?.name,
                'editedFields': b.editedFields,
                'currentPage': b.currentPage,
                'finishedAt': b.finishedAt?.toIso8601String(),
                'isFavorite': b.isFavorite,
                'review': b.review,
                'olid': b.olid,
                'createdAt': b.createdAt.toIso8601String(),
                'updatedAt': b.updatedAt.toIso8601String(),
                'deletedAt': b.deletedAt?.toIso8601String(),
              },
          ]..sort(
            (a, b) => (a['title']! as String).compareTo(b['title']! as String),
          ),
      'locations': [for (final id in locations.keys) path(id)]..sort(),
      'series': [
        for (final s in series.values) '${s.name}:${s.totalPlannedVolumes}',
      ]..sort(),
      'tags': [...tagName.values]..sort(),
      'bookTags': rowsFor(
        await db.select(db.bookTags).get(),
        (r) => r.bookId,
        (r) => {'tag': tagName[r.tagId]},
      ),
      'notes': rowsFor(
        await db.select(db.bookNotes).get(),
        (r) => r.bookId,
        (r) => {
          'kind': r.kind.name,
          'content': r.content,
          'page': r.pageNumber,
          'createdAt': r.createdAt.toIso8601String(),
          'updatedAt': r.updatedAt.toIso8601String(),
        },
      ),
      'sessions': rowsFor(
        await db.select(db.readingSessions).get(),
        (r) => r.bookId,
        (r) => {
          'start': r.startedAt.toIso8601String(),
          'end': r.endedAt?.toIso8601String(),
          'seconds': r.durationSeconds,
          'startPage': r.startPage,
          'endPage': r.endPage,
        },
      ),
      'lending': rowsFor(
        await db.select(db.lending).get(),
        (r) => r.bookId,
        (r) => {
          'borrower': r.borrowerName,
          'lentAt': r.lentAt.toIso8601String(),
          'expectedReturn': r.expectedReturn?.toIso8601String(),
          'returnedAt': r.returnedAt?.toIso8601String(),
        },
      ),
      'goals': [
        for (final g in await db.select(db.readingGoals).get())
          '${g.year}:${g.targetBooks}:${g.targetPages}',
      ]..sort(),
      'tiles': await tiles(db),
    };
  }

  group('round trip', () {
    test('a restored library is identical to the exported one', () async {
      await fillSource();
      final json = await ExportService(source).exportJson();

      final result = await restore(target, json);

      expect(result.errors, isEmpty);
      expect(result.imported, 4);
      expect(result.updated, 0);
      expect(result.duplicates, 0);
      final before = await snapshot(source);
      final after = await snapshot(target);
      expect(after, before);
      // Spot checks, so a broken snapshot helper cannot hide a loss.
      final books = (after['books']! as List).cast<Map<String, Object?>>();
      final full = books.firstWhere((b) => b['title'] == 'Der Vorleser');
      expect(
        full['location'],
        'Wohnzimmer:room > Regal 1:shelf > Fach A:compartment',
      );
      expect(full['series'], 'Die Reihe');
      expect(full['seriesTotal'], 7);
      expect(full['isFavorite'], isTrue);
      expect(full['olid'], 'OL123M');
      expect(full['review'], 'Stark; "bewegend", und klug.');
      expect((after['sessions']! as List), hasLength(3));
      expect((after['notes']! as List), hasLength(2));
      expect((after['lending']! as List), hasLength(2));
      expect(after['goals'], ['2025:0:5000', '2026:24:8000']);
      expect(after['tiles'], hasLength(2));
    });

    test('empty locations, unused tags and goals survive', () async {
      await fillSource();
      await restore(target, await ExportService(source).exportJson());

      final locations = [
        for (final l in await target.select(target.locations).get()) l.name,
      ];
      expect(locations, containsAll(['Keller', 'Kiste']));
      expect(
        [for (final t in await target.select(target.tags).get()) t.name],
        contains('Ohne Bücher'),
        reason: 'a tag nobody uses is still part of the backup',
      );
      expect(await target.select(target.readingGoals).get(), hasLength(2));
    });

    test('the trash stays the trash', () async {
      await fillSource();
      await restore(target, await ExportService(source).exportJson());

      final trashed = await (target.select(
        target.books,
      )..where((t) => t.deletedAt.isNotNull())).get();
      expect(trashed.map((b) => b.title), ['Im Papierkorb']);
      expect(trashed.single.deletedAt, DateTime(2026, 4, 1, 12));
    });

    test('a running timer is restored as running', () async {
      await fillSource();
      await restore(target, await ExportService(source).exportJson());

      final open = await (target.select(
        target.readingSessions,
      )..where((t) => t.endedAt.isNull())).get();
      expect(open, hasLength(1));
      expect(open.single.startPage, 120);
    });

    test('no progress is derived: a read book keeps its exact state', () async {
      // `status = read` without a finish date or current page must not be
      // "completed" by the import derivation.
      await source
          .into(source.books)
          .insert(
            BooksCompanion.insert(
              title: 'Gelesen ohne Daten',
              authors: const ['A'],
              editedFields: const [],
              status: const Value(BookStatus.read),
              pageCount: const Value(300),
            ),
          );
      await restore(target, await ExportService(source).exportJson());

      final book = (await target.select(target.books).getSingle());
      expect(book.currentPage, 0);
      expect(book.finishedAt, isNull);
    });

    test(
      'exporting the restored library gives the same JSON content',
      () async {
        await fillSource();
        await restore(target, await ExportService(source).exportJson());

        Map<String, Object?> normalised(String json) {
          final map = jsonDecode(json) as Map<String, dynamic>;
          return {
            'books': [
              for (final b in map['books'] as List)
                {
                  for (final e in (b as Map<String, dynamic>).entries)
                    if (!{
                      'id',
                      'locationId',
                      'seriesId',
                      'coverLocalPath',
                    }.contains(e.key))
                      e.key: e.value,
                },
            ]..sort((a, b) => '${a['title']}'.compareTo('${b['title']}')),
            'tags': [for (final t in map['tags'] as List) (t as Map)['name']]
              ..sort((a, b) => '$a'.compareTo('$b')),
            'readingGoals': map['readingGoals'],
          };
        }

        final first = normalised(await ExportService(source).exportJson());
        final second = normalised(await ExportService(target).exportJson());
        expect(second['books'], first['books']);
        expect(second['tags'], first['tags']);
        expect(
          [for (final g in second['readingGoals']! as List) (g as Map)['year']]
            ..sort(),
          [2025, 2026],
        );
      },
    );
  });

  group('restoring into a library that already has data', () {
    test('restoring the same backup twice changes nothing', () async {
      await fillSource();
      final json = await ExportService(source).exportJson();
      await restore(target, json);
      final once = await snapshot(target);

      final second = await restore(target, json);

      expect(second.imported, 0);
      expect(second.updated, 0);
      expect(second.duplicates, 4);
      expect(await snapshot(target), once);
    });

    test('tiles are appended and keep their tags by name', () async {
      await fillSource();
      // Shifts every tag id of the restore.
      await target
          .into(target.tags)
          .insert(TagsCompanion.insert(name: 'Vorher'));
      await target
          .into(target.statTiles)
          .insert(
            StatTilesCompanion.insert(
              position: 0,
              title: 'Eigene',
              definition: jsonEncode({
                'measure': 'books',
                'period': 'all',
                'chart': 'number',
              }),
              createdAt: DateTime(2026),
            ),
          );

      await restore(target, await ExportService(source).exportJson());

      expect(await tiles(target), [
        'Eigene|false|{"measure":"books","period":"all","chart":"number"}|[]',
        ...await tiles(source),
      ]);
    });

    test('a restored tile is not pinned beyond three', () async {
      await fillSource();
      for (var i = 0; i < 3; i++) {
        await target
            .into(target.statTiles)
            .insert(
              StatTilesCompanion.insert(
                position: i,
                title: 'Angepinnt $i',
                definition: jsonEncode({
                  'measure': 'books',
                  'period': 'all',
                  'chart': 'number',
                }),
                pinned: const Value(true),
                createdAt: DateTime(2026),
              ),
            );
      }

      await restore(target, await ExportService(source).exportJson());

      final restored = await (target.select(
        target.statTiles,
      )..where((t) => t.title.equals('Seiten 2026'))).getSingle();
      expect(restored.pinned, isFalse);
    });

    test('existing data wins; the backup only fills gaps', () async {
      await fillSource();
      final json = await ExportService(source).exportJson();
      await target
          .into(target.books)
          .insert(
            BooksCompanion.insert(
              title: 'Mein eigener Titel',
              authors: const ['Meine Autorin'],
              editedFields: const [],
              isbn13: const Value('9783257229530'),
              rating: const Value(2),
              review: const Value('Meine Meinung'),
            ),
          );

      final result = await restore(target, json);

      expect(result.imported, 3, reason: 'the other three books');
      expect(result.updated, 1);
      final book = await (target.select(
        target.books,
      )..where((t) => t.isbn13.equals('9783257229530'))).getSingle();
      expect(book.title, 'Mein eigener Titel');
      expect(book.rating, 2.0);
      expect(book.review, 'Meine Meinung');
      // ...but what it lacked is filled in.
      expect(book.publisher, 'Diogenes');
      expect(book.olid, 'OL123M');
      expect(book.isFavorite, isTrue);
      final tags = await target.select(target.bookTags).get();
      expect(tags.where((t) => t.bookId == book.id), hasLength(2));
    });
  });

  group('older and malformed backups', () {
    test('a v1 backup (no sessions, notes, tags, goals) restores', () async {
      final v1 = jsonEncode({
        'version': 1,
        'exportedAt': '2026-01-01T00:00:00.000',
        'books': [
          {
            'id': 1,
            'title': 'Altes Buch',
            'authors': ['A'],
            'status': 'read',
            'rating': 3.5,
            'locationId': 1,
            'createdAt': '2025-01-01T10:00:00.000',
            'updatedAt': '2025-01-02T10:00:00.000',
          },
        ],
        'locations': [
          {'id': 1, 'name': 'Regal', 'type': 'shelf', 'parentId': null},
        ],
        'series': [],
        'lending': [],
      });

      final result = await restore(target, v1);

      expect(result.errors, isEmpty);
      expect(result.imported, 1);
      final book = await target.select(target.books).getSingle();
      expect(book.title, 'Altes Buch');
      expect(book.rating, 3.5);
      expect(book.createdAt, DateTime(2025, 1, 1, 10));
      expect((await target.select(target.locations).getSingle()).name, 'Regal');
    });

    test('is recognised as a backup, and Openreads JSON is not', () async {
      await fillSource();
      final backup = ImportFile(
        name: 'b.json',
        content: await ExportService(source).exportJson(),
        type: ImportFileType.json,
      );
      const openreads = ImportFile(
        name: 'o.json',
        content: '[{"title":"X","author":"Y","status":0}]',
        type: ImportFileType.json,
      );
      const wrapped = ImportFile(
        name: 'w.json',
        content: '{"books":[{"title":"X","author":"Y"}]}',
        type: ImportFileType.json,
      );

      expect(JsonBackupImporter().canParse(backup), isTrue);
      expect(JsonBackupImporter().canParse(openreads), isFalse);
      expect(
        JsonBackupImporter().canParse(wrapped),
        isFalse,
        reason: '{"books": […]} alone is not an OpenShelf backup',
      );
      expect(OpenreadsJsonImporter().canParse(openreads), isTrue);
    });

    test('garbage is reported, not thrown', () async {
      const garbage = ImportFile(
        name: 'x.json',
        content: '{not json',
        type: ImportFileType.json,
      );
      expect(JsonBackupImporter().canParse(garbage), isFalse);

      final rows = await JsonBackupImporter().parse(garbage).toList();
      expect(rows.single.error, 'Malformed JSON');
    });

    test('a broken book row is skipped, the rest is restored', () async {
      final json = jsonEncode({
        'version': 2,
        'exportedAt': '2026-01-01T00:00:00.000',
        'books': [
          {
            'id': 1,
            'title': 'Gut',
            'authors': ['A'],
            'status': 'unread',
          },
          {
            'id': 2,
            'authors': ['B'],
          }, // no title
        ],
        'locations': [],
      });

      final result = await restore(target, json);

      expect(result.imported, 1);
      expect(result.skipped, 1);
      expect(result.errors.single.reason, 'Missing title');
    });

    test('broken statistic tiles are skipped, good ones restored', () async {
      String tile(Object? definition, {Object? title = 'T'}) =>
          jsonEncode({'title': title, 'definition': definition});
      final good = jsonEncode({
        'measure': 'books',
        'period': 'all',
        'chart': 'number',
      });
      final json = jsonEncode({
        'version': 2,
        'exportedAt': '2026-01-01T00:00:00.000',
        'books': [],
        'locations': [],
        'statTiles': [
          for (final raw in [
            tile(good, title: 'Gut'),
            tile(42), // not a string
            tile('{"measure":'), // broken JSON
            tile('{"measure":"future","period":"all","chart":"number"}'),
            tile(good, title: null), // no title
          ])
            jsonDecode(raw),
          'kein Objekt',
        ],
      });

      final result = await restore(target, json);

      expect(result.errors, isEmpty);
      expect(await tiles(target), [
        'Gut|false|{"measure":"books","period":"all","chart":"number"}|[]',
      ]);
    });
  });
}
