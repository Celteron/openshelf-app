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

    await cubit.saveAll(locationId: locationId);

    final after = cubit.state as ScannerActive;
    expect(after.staged, isEmpty);

    final persisted = await books.searchLocal('');
    expect(persisted, hasLength(3));
    for (final book in persisted) {
      expect(book.locationId, locationId);
    }
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
}
