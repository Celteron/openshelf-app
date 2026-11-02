import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';

void main() {
  test('fresh install creates every table', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Trigger onCreate by executing a statement.
    await db.customSelect('SELECT 1').get();

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    final names = tables.map((r) => r.read<String>('name')).toList();
    expect(names, [
      'book_notes',
      'book_tags',
      'books',
      'lending',
      'locations',
      'reading_goals',
      'reading_sessions',
      'series',
      'stat_tiles',
      'tags',
    ]);
  });

  test(
    'migration strategy runs PRAGMA foreign_keys = ON before open',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final rows = await db.customSelect('PRAGMA foreign_keys').get();
      final enabled = rows.single.data.values.single as int;
      expect(enabled, 1);
    },
  );
}
