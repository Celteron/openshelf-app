import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/notes_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/notes_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/enums.dart';

/// "Split into volumes" (ADR-0003, FR-R2-09).
void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late int box;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    books = BookRepositoryImpl(BooksDao(db));
    box = await books.insertBook(
      BooksCompanion.insert(
        title: 'Die Tribute von Panem – Schuber',
        authors: const ['Suzanne Collins'],
        editedFields: const [],
        isbn13: const Value('9783789132100'),
        publisher: const Value('Oetinger'),
        language: const Value('de'),
        publishedYear: const Value(2012),
        format: const Value(BookFormat.paperback),
        genre: const Value('Dystopie'),
        pageCount: const Value(1184),
        priceCents: const Value(3999),
        status: const Value(BookStatus.read),
        rating: const Value(4.5),
        finishedAt: Value(DateTime(2024, 3, 1)),
        review: const Value('Toll'),
        readingSeconds: const Value(3600),
        currentPage: const Value(1184),
        createdAt: Value(DateTime(2023, 1, 1)),
      ),
    );
  });
  tearDown(() => db.close());

  const drafts = [
    VolumeDraft(title: 'Tödliche Spiele', pageCount: 414),
    VolumeDraft(title: 'Gefährliche Liebe', pageCount: 432),
    VolumeDraft(title: 'Flammender Zorn'),
  ];

  test('creates the volumes with the shared data of the slipcase', () async {
    final ids = await books.splitIntoVolumes(box, drafts);

    expect(ids, hasLength(3));
    final volumes = [for (final id in ids) (await books.getBook(id))!];
    expect(volumes.map((v) => v.title), [
      'Tödliche Spiele',
      'Gefährliche Liebe',
      'Flammender Zorn',
    ]);
    expect(volumes.map((v) => v.pageCount), [414, 432, null]);
    for (final v in volumes) {
      expect(v.parentId, box);
      expect(v.authors, ['Suzanne Collins']);
      expect(v.publisher, 'Oetinger');
      expect(v.language, 'de');
      expect(v.publishedYear, 2012);
      expect(v.format, BookFormat.paperback);
      expect(v.genre, 'Dystopie');
      expect(v.status, BookStatus.read);
      expect(v.rating, 4.5);
      expect(v.finishedAt, DateTime(2024, 3, 1));
      expect(v.createdAt, DateTime(2023, 1, 1), reason: 'added with the box');
      expect(v.editedFields, containsAll(['title', 'pageCount']));
      // The physical object stays on the slipcase.
      expect(v.isbn13, isNull);
      expect(v.priceCents, isNull);
    }
  });

  test('reading data moves to volume 1, the slipcase keeps none', () async {
    await ReadingRepositoryImpl(ReadingDao(db)).logSession(
      box,
      startedAt: DateTime(2024),
      duration: const Duration(minutes: 30),
      startPage: 0,
      endPage: 40,
    );
    await NotesRepositoryImpl(
      NotesDao(db),
    ).addNote(box, kind: NoteKind.quote, content: 'Zitat');

    final ids = await books.splitIntoVolumes(box, drafts);

    final first = (await books.getBook(ids.first))!;
    expect(first.review, 'Toll');
    expect(first.readingSeconds, 3600);
    expect(first.currentPage, 1184, reason: 'the place in the box');
    expect((await db.select(db.readingSessions).get()).map((s) => s.bookId), [
      ids.first,
    ]);
    expect((await db.select(db.bookNotes).get()).map((n) => n.bookId), [
      ids.first,
    ]);
    expect((await books.getBook(ids[1]))!.review, isNull);

    final slipcase = (await books.getBook(box))!;
    expect(slipcase.review, isNull);
    expect(slipcase.readingSeconds, isNull);
    expect(slipcase.rating, 0);
    expect(slipcase.finishedAt, isNull);
    expect(slipcase.currentPage, 0);
    expect(slipcase.isbn13, '9783789132100', reason: 'physical data stays');
    expect(slipcase.priceCents, 3999);
  });

  test('needs at least two volumes and changes nothing otherwise', () async {
    await expectLater(
      books.splitIntoVolumes(box, drafts.take(1).toList()),
      throwsArgumentError,
    );
    expect(await db.select(db.books).get(), hasLength(1));
  });

  test('a volume or an already split slipcase cannot be split', () async {
    final ids = await books.splitIntoVolumes(box, drafts);

    await expectLater(
      books.splitIntoVolumes(ids.first, drafts),
      throwsStateError,
    );
    await expectLater(books.splitIntoVolumes(box, drafts), throwsStateError);
    expect(await db.select(db.books).get(), hasLength(4));
  });

  test('getVolumes lists the active volumes in order', () async {
    final ids = await books.splitIntoVolumes(box, drafts);
    await books.deleteBook(ids[1]);

    expect((await books.getVolumes(box)).map((v) => v.id), [ids[0], ids[2]]);
    expect(await books.getVolumes(ids[0]), isEmpty);
  });
}
