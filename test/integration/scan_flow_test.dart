import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';

class _FakeSource implements MetadataSourceStrategy {
  @override
  MetadataSource get id => MetadataSource.dnb;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async =>
      BookMetadata(title: 'Title $isbn13', isbn13: isbn13);
}

class _GatedSource implements MetadataSourceStrategy {
  final Future<void> gate;
  _GatedSource(this.gate);

  @override
  MetadataSource get id => MetadataSource.dnb;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async {
    await gate;
    return BookMetadata(
      title: 'Online-Titel',
      authors: const ['Online'],
      isbn13: isbn13,
      pageCount: 300,
    );
  }
}

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late LocationRepositoryImpl locations;
  late ScannerCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    locations = LocationRepositoryImpl(LocationsDao(db));
    final queue = MetadataLookupQueue(
      MetadataAggregatorService([_FakeSource()]),
      minInterval: Duration.zero,
    );
    cubit = ScannerCubit(books, queue);
  });

  tearDown(() async {
    cubit.close();
    await db.close();
  });

  test('a failed save keeps the staged books and can be retried', () async {
    cubit.start();
    await cubit.onScanned('978-3-86680-192-9');
    // A location deleted on the shelf tab: the insert hits the foreign key.
    cubit.setShared(const StagedDefaults(locationId: 999));

    await cubit.saveAll();

    final failed = cubit.state as ScannerActive;
    expect(failed.saving, isFalse);
    expect(failed.saveFailed, isTrue);
    expect(failed.staged, hasLength(1));
    expect(await books.getAllBooks(), isEmpty);

    cubit.setShared(const StagedDefaults());
    await cubit.saveAll();
    expect(await books.getAllBooks(), hasLength(1));
    expect((cubit.state as ScannerActive).saveFailed, isFalse);
  });

  test('a new batch starts from the defaults it is given', () async {
    const defaults = StagedDefaults(
      format: BookFormat.hardcover,
      status: BookStatus.wishlist,
    );
    cubit.start(defaults: defaults);
    expect((cubit.state as ScannerActive).shared, same(defaults));

    // A running batch keeps what the user chose.
    cubit.setShared(const StagedDefaults(format: BookFormat.ebook));
    cubit.start(defaults: defaults);
    expect((cubit.state as ScannerActive).shared.format, BookFormat.ebook);
  });

  test('scan → stage → assign → save persists staged books', () async {
    final locationId = await locations.createLocation(
      name: 'Wohnzimmer',
      type: LocationType.room,
    );

    cubit.start();
    await cubit.onScanned('978-3-86680-192-9');
    await cubit.onScanned('978-0-306-40615-7');
    await cubit.onScanned('978-3-16-148410-0');

    final active = cubit.state as ScannerActive;
    expect(active.staged, hasLength(3));

    cubit.setShared(StagedDefaults(locationId: locationId));
    await cubit.saveAll();

    final after = cubit.state as ScannerActive;
    expect(after.staged, isEmpty);

    final persisted = await books.searchLocal('');
    expect(persisted, hasLength(3));
    for (final book in persisted) {
      expect(book.locationId, locationId);
    }
  });

  test('a saved batch triggers the cover search once (P1)', () async {
    var calls = 0;
    final queue = MetadataLookupQueue(
      MetadataAggregatorService([_FakeSource()]),
      minInterval: Duration.zero,
    );
    final hooked = ScannerCubit(books, queue, onBooksAdded: () => calls++);
    addTearDown(hooked.close);

    hooked.start();
    await hooked.onScanned('978-3-86680-192-9');
    await hooked.saveAll();
    expect(calls, 1);

    // Nothing staged, nothing added: no search.
    await hooked.saveAll();
    expect(calls, 1);
  });

  test('dedupes an already-owned ISBN', () async {
    await books.addBook(
      const BookDraft(isbn13: '978-3-86680-192-9', title: 'Owned'),
    );

    cubit.start();
    await cubit.onScanned('978-3-86680-192-9');

    final active = cubit.state as ScannerActive;
    expect(active.staged, hasLength(1));
    expect(active.staged.single.duplicate, isTrue);
  });

  group('editing the staging shelf (FR-R2-12)', () {
    const isbn = '9783866801929';

    test('an edit survives a late lookup and is saved as edited', () async {
      final gate = Completer<void>();
      final gated = ScannerCubit(
        books,
        MetadataLookupQueue(
          MetadataAggregatorService([_GatedSource(gate.future)]),
          minInterval: Duration.zero,
        ),
      );
      addTearDown(gated.close);
      gated.start();
      final scanning = gated.onScanned(isbn);
      await pumpEventQueue();
      // The user edits while the lookup is still running.
      gated.editStaged(
        isbn,
        const BookMetadata(title: 'Mein Titel', authors: ['Ich']),
        {'title', 'authors'},
      );
      gate.complete();
      await scanning;

      final staged = (gated.state as ScannerActive).staged.single;
      expect(staged.metadata!.title, 'Mein Titel');
      expect(staged.metadata!.pageCount, 300, reason: 'the rest comes in');

      await gated.saveAll();
      final saved = (await books.searchLocal('')).single;
      expect(saved.title, 'Mein Titel');
      expect(saved.authors, ['Ich']);
      expect(saved.pageCount, 300);
      expect(saved.editedFields, containsAll(['title', 'authors']));
    });

    test('a staged book can be removed', () async {
      cubit.start();
      await cubit.onScanned(isbn);

      cubit.removeStaged(isbn);

      expect((cubit.state as ScannerActive).staged, isEmpty);
    });

    test('"save all" applies the shared values to every book', () async {
      cubit.start();
      await cubit.onScanned(isbn);
      await cubit.onScanned('978-0-306-40615-7');

      cubit.setShared(
        const StagedDefaults(
          format: BookFormat.hardcover,
          status: BookStatus.read,
          receivedAs: ReceivedAs.gift,
        ),
      );
      await cubit.saveAll();

      final saved = await books.searchLocal('');
      expect(saved, hasLength(2));
      for (final book in saved) {
        expect(book.format, BookFormat.hardcover);
        expect(book.status, BookStatus.read);
        expect(book.receivedAs, ReceivedAs.gift);
      }
      expect(
        (cubit.state as ScannerActive).shared.status,
        BookStatus.read,
        reason: 'kept for the next batch',
      );
    });
  });
}
