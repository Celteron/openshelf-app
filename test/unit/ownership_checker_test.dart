import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/database/daos/series_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/data/repositories/series_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/services/ownership_checker.dart';

void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late LocationRepositoryImpl locations;
  late SeriesRepositoryImpl series;
  late OwnershipChecker checker;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    locations = LocationRepositoryImpl(LocationsDao(db));
    series = SeriesRepositoryImpl(SeriesDao(db));
    checker = OwnershipChecker(books, locations, series);
  });

  tearDown(() => db.close());

  Future<int> add(
    String title, {
    String? isbn13,
    BookStatus status = BookStatus.unread,
    int? locationId,
    int? seriesId,
    double? volume,
  }) => books.insertBook(
    BooksCompanion.insert(
      title: title,
      authors: const ['A'],
      editedFields: const [],
      isbn13: Value(isbn13),
      status: Value(status),
      locationId: Value(locationId),
      seriesId: Value(seriesId),
      seriesVolume: Value(volume),
    ),
  );

  test('an unknown ISBN is new', () async {
    expect(await checker.check('9783866801929'), isA<NewVerdict>());
  });

  test('an owned book names its place on the shelf', () async {
    final room = await locations.createLocation(
      name: 'Wohnzimmer',
      type: LocationType.room,
    );
    final shelf = await locations.createLocation(
      name: 'Regal 2',
      type: LocationType.shelf,
      parentId: room,
    );
    final slot = await locations.createLocation(
      name: 'Fach 3',
      type: LocationType.compartment,
      parentId: shelf,
    );
    await add('Der Vorleser', isbn13: '9783866801929', locationId: slot);

    final verdict = await checker.check('9783866801929');

    expect(verdict, isA<OwnedVerdict>());
    verdict as OwnedVerdict;
    expect(verdict.book.title, 'Der Vorleser');
    expect(verdict.locationPath, 'Wohnzimmer › Regal 2 › Fach 3');
    expect(verdict.series, isNull);
  });

  test('an owned book without a location has no path', () async {
    await add('Ohne Ort', isbn13: '9783866801929');

    final verdict = await checker.check('9783866801929') as OwnedVerdict;

    expect(verdict.locationPath, isNull);
  });

  test('a wishlist book is not owned yet', () async {
    await add('Wunsch', isbn13: '9783866801929', status: BookStatus.wishlist);

    final verdict = await checker.check('9783866801929');

    expect(verdict, isA<WishlistVerdict>());
    expect((verdict as WishlistVerdict).book.title, 'Wunsch');
  });

  test('a trashed book is told apart from a new one', () async {
    final id = await add('Weg', isbn13: '9783866801929');
    await books.deleteBook(id);

    expect(await checker.check('9783866801929'), isA<TrashedVerdict>());
  });

  test('a series volume names the volumes that are missing', () async {
    final s = await series.findOrCreate('Krimi-Reihe');
    await series.setTotalVolumes(s.id, 6);
    for (final v in [1, 2, 3, 5]) {
      await add(
        'Band $v',
        isbn13: '978000000000$v',
        seriesId: s.id,
        volume: v.toDouble(),
      );
    }

    final verdict = await checker.check('9780000000001') as OwnedVerdict;

    expect(verdict.series?.name, 'Krimi-Reihe');
    expect(verdict.series?.total, 6);
    expect(verdict.series?.missing, [4, 6]);
  });

  test('a wishlist volume does not count as owned', () async {
    final s = await series.findOrCreate('Reihe');
    await series.setTotalVolumes(s.id, 3);
    await add('Band 1', isbn13: '9783866801929', seriesId: s.id, volume: 1);
    await add(
      'Band 2',
      isbn13: '9783866801936',
      seriesId: s.id,
      volume: 2,
      status: BookStatus.wishlist,
    );

    final verdict = await checker.check('9783866801929') as OwnedVerdict;

    expect(verdict.series?.missing, [2, 3]);
  });

  test('a series without a planned total reports no gaps', () async {
    final s = await series.findOrCreate('Offen');
    await add('Band 1', isbn13: '9783866801929', seriesId: s.id, volume: 1);

    final verdict = await checker.check('9783866801929') as OwnedVerdict;

    expect(verdict.series?.total, isNull);
    expect(verdict.series?.missing, isEmpty);
  });
}
