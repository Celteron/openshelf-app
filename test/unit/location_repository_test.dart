import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/location_repository.dart';

void main() {
  late AppDatabase db;
  late LocationRepositoryImpl locationRepository;
  late BookRepositoryImpl bookRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    locationRepository = LocationRepositoryImpl(LocationsDao(db));
    bookRepository = BookRepositoryImpl(BooksDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('creates and lists a room/shelf/compartment hierarchy', () async {
    final room = await locationRepository.createLocation(
      name: 'Wohnzimmer',
      type: LocationType.room,
    );
    final shelf = await locationRepository.createLocation(
      name: 'Billy Links',
      type: LocationType.shelf,
      parentId: room,
    );
    await locationRepository.createLocation(
      name: 'Fach 2',
      type: LocationType.compartment,
      parentId: shelf,
    );

    final all = await locationRepository.getLocations();
    expect(all, hasLength(3));

    final roomLoc = await locationRepository.getLocation(room);
    expect(roomLoc!.parentId, isNull);
  });

  test('blocks deletion of a location with children', () async {
    final room = await locationRepository.createLocation(
      name: 'Wohnzimmer',
      type: LocationType.room,
    );
    await locationRepository.createLocation(
      name: 'Regal',
      type: LocationType.shelf,
      parentId: room,
    );

    expect(
      () => locationRepository.deleteLocation(room),
      throwsA(isA<LocationInUseException>()),
    );
  });

  test('blocks deletion of a location with assigned books', () async {
    final room = await locationRepository.createLocation(
      name: 'Wohnzimmer',
      type: LocationType.room,
    );
    await bookRepository.insertBook(
      BooksCompanion.insert(
        title: 'Book',
        authors: const ['A'],
        editedFields: const [],
        locationId: Value(room),
      ),
    );

    expect(
      () => locationRepository.deleteLocation(room),
      throwsA(isA<LocationInUseException>()),
    );
  });

  test('deletes an empty location', () async {
    final room = await locationRepository.createLocation(
      name: 'Wohnzimmer',
      type: LocationType.room,
    );
    await locationRepository.deleteLocation(room);

    expect(await locationRepository.getLocation(room), isNull);
  });
}
