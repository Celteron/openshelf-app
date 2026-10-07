import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = BookRepositoryImpl(BooksDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addBook({
    required String title,
    String? isbn13,
    BookStatus status = BookStatus.unread,
    double rating = 0.0,
  }) => repository.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['Author'],
      editedFields: const [],
      isbn13: Value(isbn13),
      status: Value(status),
      rating: Value(rating),
    ),
  );

  test('searches books by title and ISBN', () async {
    await addBook(title: 'Der Vorleser', isbn13: '9783442719255');
    await addBook(title: 'Die Blechtrommel', isbn13: '9783446172580');

    final byTitle = await repository.searchLocal('Vorleser');
    expect(byTitle, hasLength(1));
    expect(byTitle.single.title, 'Der Vorleser');

    final byIsbn = await repository.searchLocal('9783446172580');
    expect(byIsbn, hasLength(1));
    expect(byIsbn.single.title, 'Die Blechtrommel');
  });

  test('filters books by status', () async {
    await addBook(title: 'Read Book', status: BookStatus.read);
    await addBook(title: 'Wishlist Book', status: BookStatus.wishlist);

    final read = await repository.watchBooks(status: BookStatus.read).first;
    expect(read, hasLength(1));
    expect(read.single.title, 'Read Book');
  });

  test('persists a 0.5-step rating exactly', () async {
    final id = await addBook(title: 'Rated', rating: 3.5);

    final book = await repository.getBook(id);
    expect(book!.rating, 3.5);

    await repository.updateBook(id, const BooksCompanion(rating: Value(4.0)));
    final updated = await repository.getBook(id);
    expect(updated!.rating, 4.0);
  });

  test('bulk-assigns a location in a single transaction', () async {
    final a = await addBook(title: 'A');
    final b = await addBook(title: 'B');
    final c = await addBook(title: 'C');

    final locId = await db
        .into(db.locations)
        .insert(
          LocationsCompanion.insert(name: 'Regal', type: LocationType.shelf),
        );

    await repository.bulkAssignLocation([a, b], locId);

    expect((await repository.getBook(a))!.locationId, locId);
    expect((await repository.getBook(b))!.locationId, locId);
    expect((await repository.getBook(c))!.locationId, isNull);
  });

  test('detects an existing ISBN', () async {
    await addBook(title: 'Existing', isbn13: '9780000000001');
    expect(await repository.isbnExists('9780000000001'), isTrue);
    expect(await repository.isbnExists('9780000000002'), isFalse);
  });
}
