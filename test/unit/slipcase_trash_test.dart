import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';

/// Trash semantics of slipcases (ADR-0003): an active volume implies an
/// active slipcase.
void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late int box, vol1, vol2, single;

  Future<int> add(String title, {int? parentId}) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
      parentId: Value(parentId),
    ),
  );

  Future<Map<int, DateTime?>> deletedAt() async => {
    for (final b in await db.select(db.books).get()) b.id: b.deletedAt,
  };

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    books = BookRepositoryImpl(BooksDao(db));
    box = await add('Schuber');
    vol1 = await add('Band 1', parentId: box);
    vol2 = await add('Band 2', parentId: box);
    single = await add('Einzeln');
  });
  tearDown(() => db.close());

  test('trashing a slipcase trashes its volumes at the same moment', () async {
    await books.deleteBook(box);

    final at = await deletedAt();
    expect(at[box], isNotNull);
    expect(at[vol1], at[box]);
    expect(at[vol2], at[box]);
    expect(at[single], isNull);
  });

  test('bulk trash includes the volumes of a selected slipcase', () async {
    await books.deleteBooks([box, single]);

    expect((await deletedAt()).values.every((d) => d != null), isTrue);
  });

  test('a volume alone goes to the trash, its slipcase stays', () async {
    await books.deleteBook(vol1);

    final at = await deletedAt();
    expect(at[vol1], isNotNull);
    expect(at[box], isNull);
    expect(at[vol2], isNull);
  });

  test(
    'restoring a slipcase brings back the volumes trashed with it',
    () async {
      await books.deleteBook(vol1); // removed earlier, on its own
      // Deletion times are stored to the second.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await books.deleteBook(box);

      await books.restoreBook(box);

      final at = await deletedAt();
      expect(at[box], isNull);
      expect(at[vol2], isNull);
      expect(at[vol1], isNotNull, reason: 'trashed separately, stays there');
    },
  );

  test('restoring a volume restores its slipcase too', () async {
    await books.deleteBook(box);

    await books.restoreBook(vol1);

    final at = await deletedAt();
    expect(at[vol1], isNull);
    expect(at[box], isNull, reason: 'an active volume needs its slipcase');
  });

  test('purging a slipcase purges its trashed volumes', () async {
    await books.deleteBook(box);

    await books.purgeBook(box);

    expect((await deletedAt()).keys, [single]);
  });

  test('purging a slipcase keeps a volume trashed on its own', () async {
    await books.deleteBook(vol1);
    // Deletion times are stored to the second.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await books.deleteBook(box);

    await books.purgeBook(box);

    final left = await deletedAt();
    expect(left.keys, unorderedEquals([vol1, single]));
    expect(left[vol1], isNotNull, reason: 'still in the trash, now alone');
  });
}
