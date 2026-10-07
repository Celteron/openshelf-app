import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class LocationsDao {
  final AppDatabase db;
  LocationsDao(this.db);

  Future<List<Location>> getAll() => db.select(db.locations).get();

  Stream<List<Location>> watchAll() => db.select(db.locations).watch();

  Future<Location?> getById(int id) => (db.select(
    db.locations,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insert(LocationsCompanion location) =>
      db.into(db.locations).insert(location);

  Future<int> update(int id, LocationsCompanion location) =>
      (db.update(db.locations)..where((t) => t.id.equals(id))).write(location);

  Future<int> delete(int id) =>
      (db.delete(db.locations)..where((t) => t.id.equals(id))).go();

  Future<bool> hasChildren(int id) async {
    final children = await (db.select(
      db.locations,
    )..where((t) => t.parentId.equals(id))).get();
    return children.isNotEmpty;
  }

  Future<int> countBooksAt(int id) async {
    final count = db.books.id.count();
    final query = db.selectOnly(db.books)
      ..addColumns([count])
      ..where(db.books.locationId.equals(id));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
