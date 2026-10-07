import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';

abstract class LocationRepository {
  Stream<List<Location>> watchLocations();

  Future<List<Location>> getLocations();

  Future<Location?> getLocation(int id);

  Future<int> createLocation({
    required String name,
    required LocationType type,
    int? parentId,
    int sortOrder = 0,
  });

  Future<void> moveLocation(int id, int? parentId, int sortOrder);

  Future<void> renameLocation(int id, String name);

  /// Deletes a location. Throws [LocationInUseException] when the location
  /// still has children or assigned books (Constitution / FR-008).
  Future<void> deleteLocation(int id);
}

class LocationInUseException implements Exception {
  final String message;
  LocationInUseException(this.message);

  @override
  String toString() => 'LocationInUseException: $message';
}
