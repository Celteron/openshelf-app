import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/data_reset_repository.dart';

class DataResetRepositoryImpl implements DataResetRepository {
  final AppDatabase _db;

  DataResetRepositoryImpl(this._db);

  @override
  Future<void> deleteAllData() => _db.transaction(() async {
    // Foreign keys are on: children cascade or are set to null, so the table
    // order does not matter.
    for (final table in _db.allTables) {
      await _db.delete(table).go();
    }
    // Restart AUTOINCREMENT so new rows begin at id 1 again.
    await _db.customStatement('DELETE FROM sqlite_sequence');
  });
}
