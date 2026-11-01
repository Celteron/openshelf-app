import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/bookstats_csv_importer.dart';
import 'package:openreads/data/importers/bookstats_json_importer.dart';
import 'package:openreads/data/importers/bookwyrm_csv_importer.dart';
import 'package:openreads/data/importers/goodreads_csv_importer.dart';
import 'package:openreads/data/importers/import_decoding.dart';
import 'package:openreads/data/importers/importers.dart';
import 'package:openreads/data/importers/json_backup_importer.dart';
import 'package:openreads/data/importers/legacy_backup_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/importers/own_csv_importer.dart';
import 'package:openreads/data/importers/storygraph_csv_importer.dart';
import 'package:openreads/domain/models/import.dart';

/// The real Bookstats export holds personal data, so it is gitignored and only
/// exists locally; without it these tests are skipped.
final _realExportMissing = File('test/Test_Export_BookStats.csv').existsSync()
    ? null
    : 'local-only fixture test/Test_Export_BookStats.csv is missing';

/// Which importer claims a file — exactly like the import screen picks it
/// (`ImporterCubit.detect`): the first importer of the right file type that
/// recognises it.
void main() {
  final importers = defaultImporters();

  BookImporter? detect(ImportFile file) {
    for (final importer in importers) {
      if (importer.supportedType == file.type && importer.canParse(file)) {
        return importer;
      }
    }
    return null;
  }

  ImportFile csv(String content) =>
      ImportFile(name: 'x.csv', content: content, type: ImportFileType.csv);
  ImportFile json(String content) =>
      ImportFile(name: 'x.json', content: content, type: ImportFileType.json);

  test('there are ten importers, each of them named differently', () {
    expect(importers, hasLength(10));
    expect(importers.map((i) => i.formatName).toSet(), hasLength(10));
  });

  test('the catch-all own-CSV importer comes last', () {
    expect(importers.last, isA<OwnCsvImporter>());
  });

  group('CSV', () {
    test('Openreads', () {
      expect(
        detect(
          csv(
            'title,subtitle,author,publication_year,status\nX,,Y,2000,finished\n',
          ),
        ),
        isA<OpenreadsCsvImporter>(),
      );
    });

    test('Goodreads is not mistaken for Openreads', () {
      expect(
        detect(
          csv(
            'Title,Author,Additional Authors,ISBN,ISBN13,My Rating\nX,Y,,,,5\n',
          ),
        ),
        isA<GoodreadsCsvImporter>(),
      );
    });

    test('StoryGraph', () {
      expect(
        detect(
          csv('Title,Authors,ISBN/UID,Format,Read Status\nX,Y,,Print,read\n'),
        ),
        isA<StoryGraphCsvImporter>(),
      );
    });

    test('Bookwyrm', () {
      expect(
        detect(csv('title,author_text,isbn_13,rating\nX,Y,,3\n')),
        isA<BookwyrmCsvImporter>(),
      );
    });

    test(
      'Bookstats, including the real ;-separated Latin-1 export',
      skip: _realExportMissing,
      () {
        final file = ImportFile(
          name: 'Test_Export_BookStats.csv',
          content: decodeImportBytes(
            File('test/Test_Export_BookStats.csv').readAsBytesSync(),
          ),
          type: ImportFileType.csv,
        );
        expect(detect(file), isA<BookstatsCsvImporter>());
      },
    );

    test('an unknown CSV falls through to the own-CSV importer', () {
      expect(detect(csv('Name,Alter\nAnna,3\n')), isA<OwnCsvImporter>());
    });

    test('an empty CSV or a header without data is claimed by no one', () {
      expect(detect(csv('')), isNull);
      expect(detect(csv('Name,Alter\n')), isNull);
    });

    test('a bare ISBN column does not make a file Bookstats', () {
      expect(
        detect(csv('isbn,notes\n9780441172719,x\n')),
        isA<OwnCsvImporter>(),
      );
    });
  });

  group('JSON', () {
    test('an OpenShelf backup', () {
      expect(
        detect(
          json(
            jsonEncode({
              'version': 2,
              'exportedAt': '2026-01-01T00:00:00.000',
              'books': [
                {
                  'id': 1,
                  'title': 'X',
                  'authors': ['Y'],
                },
              ],
              'locations': [],
            }),
          ),
        ),
        isA<JsonBackupImporter>(),
      );
    });

    test('Openreads JSON as a list or wrapped in {"books": …}', () {
      expect(
        detect(json('[{"title":"X","author":"Y","status":0}]')),
        isA<OpenreadsJsonImporter>(),
      );
      expect(
        detect(json('{"books":[{"title":"X","author":"Y"}]}')),
        isA<OpenreadsJsonImporter>(),
      );
    });

    test('a JSON that is no list of books is not claimed', () {
      expect(detect(json('{"hello": "world"}')), isNull);
      expect(detect(json('not json')), isNull);
    });

    test(
      'Bookstats JSON shares the list shape and is handled by a JSON importer',
      () {
        expect(
          detect(json('[{"titel":"X","autor":"Y"}]')),
          anyOf(isA<OpenreadsJsonImporter>(), isA<BookstatsJsonImporter>()),
        );
      },
    );
  });

  group('ZIP', () {
    test('a legacy Openreads backup', () {
      final zip = Archive()
        ..addFile(ArchiveFile('books.backup', 2, utf8.encode('{}')));
      final file = ImportFile(
        name: 'Openreads-5.zip',
        type: ImportFileType.zip,
        bytes: Uint8List.fromList(ZipEncoder().encode(zip)),
      );
      expect(detect(file), isA<LegacyBackupImporter>());
    });

    test('a ZIP without books.backup is not claimed', () {
      final zip = Archive()..addFile(ArchiveFile('other.txt', 1, [65]));
      final file = ImportFile(
        name: 'x.zip',
        type: ImportFileType.zip,
        bytes: Uint8List.fromList(ZipEncoder().encode(zip)),
      );
      expect(detect(file), isNull);
    });
  });

  test('a file is only offered to importers of its own file type', () {
    const zipAsCsv = ImportFile(
      name: 'x.csv',
      content: 'title,author_text\nX,Y\n',
      type: ImportFileType.csv,
    );
    expect(detect(zipAsCsv)!.supportedType, ImportFileType.csv);
  });
}
