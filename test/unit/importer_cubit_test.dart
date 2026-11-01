import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/importers.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';
import 'package:openreads/features/importer/importer_cubit.dart';

/// The column matcher step of the importer (spec 003 FR-F1-08).
void main() {
  const csv =
      '"Titel";"Autor(en)";"ISBN";"Kaufpreis";"Genre";"Lesestatus"\n'
      '"Buch";"Doe, Jane";"9783736315471";"9,99";"Krimi";"Gelesen"\n';
  const file = ImportFile(
    name: 'x.csv',
    content: csv,
    type: ImportFileType.csv,
  );

  late AppDatabase db;
  late ImporterCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cubit = ImporterCubit(
      ImportService(BookRepositoryImpl(BooksDao(db))),
      defaultImporters(),
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  ImporterMapping mapping() => cubit.state as ImporterMapping;

  String? fieldOf(String header) =>
      mapping().columns.singleWhere((c) => c.header == header).field;

  int indexOf(String header) =>
      mapping().columns.singleWhere((c) => c.header == header).index;

  test('a CSV file opens the matcher with the detected suggestion', () {
    cubit.selectFile(file);

    expect(mapping().importer.formatName, 'Bookstats CSV');
    expect(mapping().columns.map((c) => c.header), [
      'Titel',
      'Autor(en)',
      'ISBN',
      'Kaufpreis',
      'Genre',
      'Lesestatus',
    ]);
    expect(fieldOf('Titel'), ColumnMapper.fieldTitle);
    expect(fieldOf('Genre'), ColumnMapper.fieldGenre);
    expect(fieldOf('Kaufpreis'), isNull, reason: 'unknown column stays open');
  });

  test('each column carries a sample value from the first row', () {
    cubit.selectFile(file);

    final price = mapping().columns.singleWhere((c) => c.header == 'Kaufpreis');
    expect(price.sample, '9,99');
  });

  test('assigning a column changes the mapping used by the import', () async {
    cubit.selectFile(file);
    cubit.assign(indexOf('Kaufpreis'), ColumnMapper.fieldPrice);
    expect(fieldOf('Kaufpreis'), ColumnMapper.fieldPrice);

    await cubit.runImport();

    final book = await db.select(db.books).getSingle();
    expect(book.priceCents, 999);
    expect(book.genre, 'Krimi');
  });

  test('ignoring a column leaves its data out', () async {
    cubit.selectFile(file);
    cubit.assign(indexOf('Genre'), null);

    await cubit.runImport();

    final book = await db.select(db.books).getSingle();
    expect(book.genre, isNull);
    expect(book.title, 'Buch');
  });

  test('switching the format re-suggests the mapping', () {
    cubit.selectFile(file);
    final alternatives = mapping().alternatives;
    expect(alternatives.length, greaterThan(1));
    expect(alternatives, contains(mapping().importer));

    final other = alternatives.firstWhere(
      (i) => i.formatName != mapping().importer.formatName,
    );
    cubit.changeImporter(other);

    expect(mapping().importer, same(other));
  });

  test('JSON files have no columns to match', () {
    cubit.selectFile(
      const ImportFile(
        name: 'x.json',
        content: '[{"titel":"A","autor":"B","lesestatus":"Gelesen"}]',
        type: ImportFileType.json,
      ),
    );

    expect(mapping().columns, isEmpty);
    expect(mapping().alternatives, isEmpty);
  });

  test('an empty file ends in an error state', () {
    cubit.selectFile(
      const ImportFile(name: 'x.csv', content: '', type: ImportFileType.csv),
    );
    expect(cubit.state, isA<ImporterError>());
  });

  group('own CSV files', () {
    const own =
        'Buchtitel;Verfasser;Kaufpreis (€);Seiten;Notiz an mich\n'
        'Die Wand;Marlen Haushofer;9,50;288;Muss man gelesen haben\n';

    ImportFile ownFile() => const ImportFile(
      name: 'meine-buecher.csv',
      content: own,
      type: ImportFileType.csv,
    );

    test('are accepted and opened in the matcher, not rejected', () {
      cubit.selectFile(ownFile());

      expect(cubit.state, isA<ImporterMapping>());
      expect(mapping().importer.formatName, 'Custom CSV');
    });

    test('get a suggestion from common column names', () {
      cubit.selectFile(ownFile());

      expect(fieldOf('Buchtitel'), ColumnMapper.fieldTitle);
      expect(fieldOf('Verfasser'), ColumnMapper.fieldAuthors);
      expect(fieldOf('Seiten'), ColumnMapper.fieldPageCount);
      expect(fieldOf('Kaufpreis (€)'), isNull);
      expect(fieldOf('Notiz an mich'), isNull);
    });

    test('import with the columns the user matched', () async {
      cubit.selectFile(ownFile());
      cubit.assign(indexOf('Kaufpreis (€)'), ColumnMapper.fieldPrice);
      cubit.assign(indexOf('Notiz an mich'), ColumnMapper.fieldNotes);

      await cubit.runImport();

      final book = await db.select(db.books).getSingle();
      expect(book.title, 'Die Wand');
      expect(book.authors, ['Marlen Haushofer']);
      expect(book.pageCount, 288);
      expect(book.priceCents, 950);
      expect(
        (await db.select(db.bookNotes).getSingle()).content,
        'Muss man gelesen haben',
      );
    });

    test('cannot be imported before a column is the title', () {
      cubit.selectFile(
        const ImportFile(
          name: 'x.csv',
          content: 'Wort;Zahl\nHallo;5\n',
          type: ImportFileType.csv,
        ),
      );
      expect(mapping().canImport, isFalse);

      cubit.assign(indexOf('Wort'), ColumnMapper.fieldTitle);
      expect(mapping().canImport, isTrue);
    });
  });

  group('columns are matched by position', () {
    const twins =
        'Titel;Datum;Datum;\n'
        'Buch;24.03.2022;01.02.2020;Rest\n';

    test('equal and empty headers can be assigned one by one', () {
      cubit.selectFile(
        const ImportFile(
          name: 't.csv',
          content: twins,
          type: ImportFileType.csv,
        ),
      );
      final columns = mapping().columns;
      expect(columns.map((c) => c.index), [0, 1, 2, 3]);

      cubit.assign(1, ColumnMapper.fieldDateAdded);
      cubit.assign(2, ColumnMapper.fieldStartDate);
      cubit.assign(3, ColumnMapper.fieldNotes);

      expect(mapping().columns.map((c) => c.field), [
        ColumnMapper.fieldTitle,
        ColumnMapper.fieldDateAdded,
        ColumnMapper.fieldStartDate,
        ColumnMapper.fieldNotes,
      ]);
    });

    test('the import uses each column as assigned', () async {
      cubit.selectFile(
        const ImportFile(
          name: 't.csv',
          content: twins,
          type: ImportFileType.csv,
        ),
      );
      cubit.assign(1, ColumnMapper.fieldDateAdded);
      cubit.assign(2, ColumnMapper.fieldStartDate);
      cubit.assign(3, ColumnMapper.fieldNotes);

      await cubit.runImport();

      final book = await db.select(db.books).getSingle();
      expect(book.createdAt, DateTime(2022, 3, 24));
      final session = await db.select(db.readingSessions).getSingle();
      expect(session.startedAt, DateTime(2020, 2, 1));
      expect((await db.select(db.bookNotes).getSingle()).content, 'Rest');
    });
  });

  group('lifecycle', () {
    const three =
        '"Titel";"Autor(en)";"ISBN"\n'
        '"Eins";"A";"9780000000001"\n'
        '"Zwei";"A";"9780000000002"\n'
        '"Drei";"A";"9780000000003"\n';

    test('the import reports rows done out of the total', () async {
      cubit.selectFile(
        const ImportFile(
          name: 'd.csv',
          content: three,
          type: ImportFileType.csv,
        ),
      );
      final states = <ImporterState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.runImport();
      await pumpEventQueue();
      await sub.cancel();

      final progress = states.whereType<ImporterImporting>().toList();
      expect(progress.first.processed, 0);
      expect(progress.map((s) => s.total).toSet(), {3});
      expect(progress.last.processed, 3);
      expect(states.last, isA<ImporterDone>());
    });

    test('reset starts over after a result', () async {
      cubit.selectFile(file);
      await cubit.runImport();
      expect(cubit.state, isA<ImporterDone>());

      cubit.reset();

      expect(cubit.state, isA<ImporterSelecting>());
    });

    test('reset leaves a running import alone', () async {
      cubit.emit(const ImporterImporting(1, 3));

      cubit.reset();

      expect(cubit.state, isA<ImporterImporting>());
    });
  });

  test('a failing import ends in an error instead of a spinner', () async {
    final failing = ImporterCubit(_ThrowingImportService(), defaultImporters());
    addTearDown(failing.close);
    failing.selectFile(file);

    await failing.runImport();

    expect(failing.state, isA<ImporterError>());
  });
}

class _ThrowingImportService implements ImportService {
  @override
  Future<ImportResult> import(
    Stream<ImportRow> rows, {
    void Function(int processed)? onProgress,
  }) async => throw StateError('disk full');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
