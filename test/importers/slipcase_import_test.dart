import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/json_backup_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';

/// Slipcases survive export and import (ADR-0003, Constitution I.3).
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

  Future<int> add(AppDatabase db, String title, {String? isbn13}) =>
      BookRepositoryImpl(BooksDao(db)).insertBook(
        BooksCompanion.insert(
          title: title,
          authors: const ['Suzanne Collins'],
          editedFields: const [],
          isbn13: Value(isbn13),
        ),
      );

  Future<void> boxWithVolumes(AppDatabase db, String box, String isbn) async {
    final id = await add(db, box, isbn13: isbn);
    await BookRepositoryImpl(BooksDao(db)).splitIntoVolumes(id, const [
      // Same volume titles in every box: matching must not merge them.
      VolumeDraft(title: 'Band 1', pageCount: 414),
      VolumeDraft(title: 'Band 2', pageCount: 432),
    ]);
  }

  /// slipcase title → its volume titles, as stored in [db].
  Future<Map<String, List<String>>> slipcases(AppDatabase db) async {
    final books = await db.select(db.books).get();
    final byId = {for (final b in books) b.id: b};
    final result = <String, List<String>>{};
    for (final b in books) {
      final parent = b.parentId;
      if (parent != null) (result[byId[parent]!.title] ??= []).add(b.title);
    }
    return result;
  }

  Future<ImportResult> importInto(AppDatabase db, Stream<ImportRow> rows) =>
      ImportService(BookRepositoryImpl(BooksDao(db))).import(rows);

  const expected = {
    'Panem-Schuber': ['Band 1', 'Band 2'],
    'Other-Schuber': ['Band 1', 'Band 2'],
  };

  test('a JSON backup restores slipcases and their volumes', () async {
    await boxWithVolumes(source, 'Panem-Schuber', '9783789132100');
    await boxWithVolumes(source, 'Other-Schuber', '9783789132117');
    final json = await ExportService(source).exportJson();

    final result = await importInto(
      target,
      JsonBackupImporter().parse(
        ImportFile(name: 'b.json', content: json, type: ImportFileType.json),
      ),
    );

    expect(result.imported, 6);
    expect(await slipcases(target), expected);
  });

  test('the CSV export carries the relation in id/slipcase_id', () async {
    await boxWithVolumes(source, 'Panem-Schuber', '9783789132100');
    await boxWithVolumes(source, 'Other-Schuber', '9783789132117');
    final csv = await ExportService(source).exportBooksCsv();
    expect(ExportService.csvColumns, containsAll(['id', 'slipcase_id']));

    await importInto(
      target,
      OpenreadsCsvImporter().parse(
        ImportFile(name: 'b.csv', content: csv, type: ImportFileType.csv),
      ),
    );

    expect(await slipcases(target), expected);
  });

  test('the relation resolves across import batches', () async {
    Stream<ImportRow> rows() async* {
      var n = 0;
      yield ImportRow(
        rowNumber: ++n,
        book: const BookImport(title: 'Schuber', sourceKey: '1'),
      );
      // More than one batch (100 rows) between slipcase and volume.
      for (var i = 0; i < 150; i++) {
        yield ImportRow(
          rowNumber: ++n,
          book: BookImport(title: 'Füller $i', sourceKey: '${i + 10}'),
        );
      }
      yield ImportRow(
        rowNumber: ++n,
        book: const BookImport(
          title: 'Band',
          sourceKey: '2',
          parentSourceKey: '1',
        ),
      );
    }

    await importInto(target, rows());

    expect(await slipcases(target), {
      'Schuber': ['Band'],
    });
  });

  test(
    'a volume whose slipcase is missing imports alone, with a warning',
    () async {
      final result = await importInto(
        target,
        Stream.value(
          const ImportRow(
            rowNumber: 7,
            book: BookImport(
              title: 'Band',
              sourceKey: '2',
              parentSourceKey: '1',
            ),
          ),
        ),
      );

      expect(result.imported, 1);
      expect((await target.select(target.books).getSingle()).parentId, isNull);
      expect(result.errors.single.rowNumber, 7);
    },
  );

  test('re-importing a backup into the same library changes nothing', () async {
    await boxWithVolumes(source, 'Panem-Schuber', '9783789132100');
    final json = await ExportService(source).exportJson();

    final result = await importInto(
      source,
      JsonBackupImporter().parse(
        ImportFile(name: 'b.json', content: json, type: ImportFileType.json),
      ),
    );

    expect(result.imported, 0);
    expect(await source.select(source.books).get(), hasLength(3));
  });
}
