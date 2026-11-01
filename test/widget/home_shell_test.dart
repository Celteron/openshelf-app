import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/dependency_injection.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/services/cover_sync_service.dart';
import 'package:openreads/domain/services/data_wipe_service.dart';
import 'package:openreads/domain/services/import_service.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/features/scanner/scanner_screen.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the whole app on an in-memory database: the shell must come up, and
/// the scanner (camera) may only be built once its tab is opened.
void main() {
  late AppDatabase database;
  late Directory dir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('home_shell_test');
  });

  tearDown(() async {
    await database.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final deps = AppDependencies(database);
    final covers = CoverCacheService(baseDirectory: dir);
    final settings = SettingsCubit(deps.settingsRepository);
    await tester.runAsync(settings.load);
    const aggregator = MetadataAggregatorService([]);

    await tester.pumpWidget(
      OpenShelfApp(
        deps: deps,
        aggregator: aggregator,
        importers: const [],
        importService: ImportService(deps.bookRepository, coverCache: covers),
        lookupQueue: MetadataLookupQueue(aggregator),
        settingsCubit: settings,
        coverCache: covers,
        coverSync: CoverSyncService(deps.bookRepository, covers),
        dataWipe: DataWipeService(
          books: deps.bookRepository,
          reset: deps.dataResetRepository,
          settings: deps.settingsRepository,
          covers: covers,
        ),
      ),
    );
    await tester.pump();
  }

  // Linux renders the scanner without a camera, so opening the tab is safe in
  // a test.
  testWidgets(
    'the camera scanner is not built while another tab is shown',
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(ScannerScreen, skipOffstage: false), findsNothing);

      await tester.tap(find.byIcon(Icons.qr_code_scanner));
      await tester.pump();
      expect(find.byType(ScannerScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pump();
      expect(find.byType(ScannerScreen, skipOffstage: false), findsNothing);

      // Drain drift's stream-close timers before the test ends.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
