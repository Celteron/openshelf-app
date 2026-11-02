import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationsDao _dao;

  LocationRepositoryImpl(this._dao);

  @override
  Stream<List<Location>> watchLocations() => _dao.watchAll();

  @override
  Future<List<Location>> getLocations() => _dao.getAll();

  @override
  Future<Location?> getLocation(int id) => _dao.getById(id);

  @override
  Future<int> createLocation({
    required String name,
    required LocationType type,
    int? parentId,
    int sortOrder = 0,
  }) => _dao.insert(
    LocationsCompanion.insert(
      name: name,
      type: type,
      parentId: Value(parentId),
      sortOrder: Value(sortOrder),
    ),
  );

  @override
  Future<void> moveLocation(int id, int? parentId, int sortOrder) =>
      _dao.update(
        id,
        LocationsCompanion(
          parentId: Value(parentId),
          sortOrder: Value(sortOrder),
        ),
      );

  @override
  Future<void> renameLocation(int id, String name) =>
      _dao.update(id, LocationsCompanion(name: Value(name)));

  @override
  Future<void> deleteLocation(int id) async {
    final hasChildren = await _dao.hasChildren(id);
    final bookCount = await _dao.countBooksAt(id);
    if (hasChildren || bookCount > 0) {
      throw LocationInUseException(
        'Location has $bookCount books and '
        '${hasChildren ? 'child locations' : 'no child locations'}',
      );
    }
    await _dao.delete(id);
  }
}
