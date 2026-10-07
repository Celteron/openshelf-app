import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
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

  test('updates an existing book and records edited fields', () async {
    final id = await repository.insertBook(
      BooksCompanion.insert(
        title: 'Alter Titel',
        authors: const ['Autor'],
        editedFields: const [],
        metadataSource: const Value(MetadataSource.dnb),
      ),
    );

    await repository.updateBookDraft(
      id,
      const BookDraft(
        title: 'Neuer Titel',
        authors: ['Neuer Autor'],
        publisher: 'Verlag',
        status: BookStatus.read,
        editedFields: {'title', 'authors'},
      ),
    );

    final book = await repository.getBook(id);
    expect(book!.title, 'Neuer Titel');
    expect(book.authors, ['Neuer Autor']);
    expect(book.publisher, 'Verlag');
    expect(book.status, BookStatus.read);
    expect(book.editedFields, containsAll(['title', 'authors']));
  });

  test('getAllBooks returns every inserted book', () async {
    await repository.insertBook(
      BooksCompanion.insert(
        title: 'A',
        authors: const [],
        editedFields: const [],
      ),
    );
    await repository.insertBook(
      BooksCompanion.insert(
        title: 'B',
        authors: const [],
        editedFields: const [],
      ),
    );

    final all = await repository.getAllBooks();
    expect(all, hasLength(2));
  });
}
