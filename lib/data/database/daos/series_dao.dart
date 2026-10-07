import 'package:drift/drift.dart';
import 'package:openreads/data/database/app_database.dart';

class SeriesDao {
  final AppDatabase db;
  SeriesDao(this.db);

  Future<List<Series>> getAll() => db.select(db.seriesTable).get();

  Future<Series?> getById(int id) => (db.select(
    db.seriesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Series?> findByName(String name) {
    final trimmed = name.trim();
    return (db.select(db.seriesTable)
          ..where((t) => t.name.lower().equals(trimmed.toLowerCase())))
        .getSingleOrNull();
  }

  Future<Series> findOrCreate(String name) async {
    final existing = await findByName(name);
    if (existing != null) return existing;
    final id = await db
        .into(db.seriesTable)
        .insert(SeriesTableCompanion.insert(name: name.trim()));
    return (await getById(id))!;
  }
}
