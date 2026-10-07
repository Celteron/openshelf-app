import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/importers/bookstats_csv_importer.dart';
import 'package:openreads/data/importers/bookstats_json_importer.dart';
import 'package:openreads/data/importers/goodreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/importers/storygraph_csv_importer.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

void main() {
  ImportFile file(String name, String content, ImportFileType type) =>
      ImportFile(name: name, content: content, type: type);

  test('GoodreadsCsvImporter maps title/author/isbn/rating/status', () async {
    final importer = GoodreadsCsvImporter();
    final csv = File('test/fixtures/goodreads.csv').readAsStringSync();
    final f = file('goodreads.csv', csv, ImportFileType.csv);

    expect(importer.canParse(f), isTrue);

    final rows = await importer.parse(f).toList();
    expect(rows, hasLength(4));

    final hobbit = rows[0].book!;
    expect(hobbit.title, 'The Hobbit');
    expect(hobbit.authors, ['J.R.R. Tolkien']);
    expect(hobbit.isbn13, '9780345339683');
    expect(hobbit.isbn10, '0345339681');
    expect(hobbit.rating, 5.0);
    expect(hobbit.status, BookStatus.read);
    expect(hobbit.pageCount, 310);

    final fellowship = rows[1].book!;
    expect(fellowship.authors, ['J.R.R. Tolkien', 'Christopher Tolkien']);
    expect(fellowship.status, BookStatus.wishlist);
  });

  test('GoodreadsCsvImporter skips empty rows with an error', () async {
    final importer = GoodreadsCsvImporter();
    final csv = File('test/fixtures/goodreads.csv').readAsStringSync();
    final rows = await importer
        .parse(file('g.csv', csv, ImportFileType.csv))
        .toList();

    final empty = rows[2];
    expect(empty.book, isNull);
    expect(empty.error, isNotNull);
  });

  test('StoryGraphCsvImporter maps title/authors/isbn', () async {
    const csv =
        'Title,Authors,ISBN/UID,Rating\n'
        'Dune,Frank Herbert,9780441172719,4.5\n';
    final importer = StoryGraphCsvImporter();
    final rows = await importer
        .parse(file('s.csv', csv, ImportFileType.csv))
        .toList();

    expect(rows, hasLength(1));
    final book = rows.single.book!;
    expect(book.title, 'Dune');
    expect(book.authors, ['Frank Herbert']);
    expect(book.isbn13, '9780441172719');
    expect(book.rating, 4.5);
  });

  test('OpenreadsCsvImporter maps native columns', () async {
    const csv =
        'title,author,isbn,pages,publication_year,book_type,rating\n'
        'Vorleser,Bernhard Schlink,9783442719255,206,1997,paperback,35\n';
    final importer = OpenreadsCsvImporter();
    final rows = await importer
        .parse(file('o.csv', csv, ImportFileType.csv))
        .toList();

    final book = rows.single.book!;
    expect(book.title, 'Vorleser');
    expect(book.isbn13, '9783442719255');
    expect(book.pageCount, 206);
    expect(book.format, BookFormat.paperback);
  });

  test('OpenreadsJsonImporter maps native JSON (0-50 rating scale)', () async {
    const json =
        '[{"title":"Vorleser","author":"Schlink","isbn":"9783442719255","rating":35,"status":0}]';
    final importer = OpenreadsJsonImporter();
    final rows = await importer
        .parse(file('o.json', json, ImportFileType.json))
        .toList();

    final book = rows.single.book!;
    expect(book.title, 'Vorleser');
    expect(book.rating, 3.5);
    expect(book.status, BookStatus.read);
  });

  test('BookstatsCsvImporter maps German columns', () async {
    const csv =
        'Titel,Autor,ISBN,Bewertung,Seiten\n'
        'Die Blechtrommel,Günter Grass,9783446172580,4,780\n';
    final importer = BookstatsCsvImporter();
    final rows = await importer
        .parse(file('b.csv', csv, ImportFileType.csv))
        .toList();

    final book = rows.single.book!;
    expect(book.title, 'Die Blechtrommel');
    expect(book.authors, ['Günter Grass']);
    expect(book.isbn13, '9783446172580');
    expect(book.rating, 4.0);
    expect(book.pageCount, 780);
  });

  test('BookstatsJsonImporter maps German JSON', () async {
    const json =
        '[{"titel":"Die Blechtrommel","autor":"Grass","isbn":"9783446172580","bewertung":4}]';
    final importer = BookstatsJsonImporter();
    final rows = await importer
        .parse(file('b.json', json, ImportFileType.json))
        .toList();

    final book = rows.single.book!;
    expect(book.title, 'Die Blechtrommel');
    expect(book.rating, 4.0);
  });
}
