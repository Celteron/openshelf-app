import 'package:drift/drift.dart';
import 'package:openreads/data/database/tables.dart';
import 'package:openreads/domain/models/enums.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Books, Locations, SeriesTable, Lending])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
