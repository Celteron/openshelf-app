import 'package:drift_flutter/drift_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/dependency_injection.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/cover/cover_picker.dart';
import 'package:openreads/data/export/export_file_saver.dart';
import 'package:openreads/domain/services/cover_sync_service.dart';
import 'package:openreads/domain/services/data_wipe_service.dart';
import 'package:openreads/features/trash/trash_cubit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/importers.dart';
import 'package:openreads/data/metadata/dnb_client.dart';
import 'package:openreads/data/metadata/google_books_client.dart';
import 'package:openreads/data/metadata/open_library_client.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';
import 'package:openreads/domain/services/import_service.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/features/importer/importer_cubit.dart';
import 'package:openreads/features/importer/importer_screen.dart';
import 'package:openreads/features/lending/lending_cubit.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/library_screen.dart';
import 'package:openreads/features/locations/location_tree_cubit.dart';
import 'package:openreads/features/locations/location_tree_screen.dart';
import 'package:openreads/features/metadata/metadata_cubit.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';
import 'package:openreads/features/scanner/scanner_screen.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/features/statistics/statistics_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase(driftDatabase(name: 'openshelf'));
  final deps = AppDependencies(database);

  // The key is baked in at build time and never lives in the repository:
  // flutter build apk --dart-define=GOOGLE_BOOKS_API_KEY=$GOOGLE_BOOKS_API_KEY
  final settingsCubit = SettingsCubit(
    deps.settingsRepository,
    defaultGoogleBooksApiKey: const String.fromEnvironment(
      'GOOGLE_BOOKS_API_KEY',
    ),
  );
  await settingsCubit.load();

  final aggregator = MetadataAggregatorService([
    DnbClient(),
    GoogleBooksClient(apiKey: () => settingsCubit.state.googleBooksApiKey),
    OpenLibraryClient(),
  ]);

  final importers = defaultImporters();

  final coverCache = CoverCacheService(
    baseDirectory: await getApplicationDocumentsDirectory(),
  );
  final coverSync = CoverSyncService(deps.bookRepository, coverCache);
  final importService = ImportService(
    deps.bookRepository,
    coverCache: coverCache,
  );
  final dataWipe = DataWipeService(
    books: deps.bookRepository,
    reset: deps.dataResetRepository,
    settings: deps.settingsRepository,
    covers: coverCache,
  );
  final lookupQueue = MetadataLookupQueue(aggregator);

  runApp(
    OpenShelfApp(
      deps: deps,
      aggregator: aggregator,
      importers: importers,
      importService: importService,
      lookupQueue: lookupQueue,
      settingsCubit: settingsCubit,
      coverCache: coverCache,
      coverSync: coverSync,
      dataWipe: dataWipe,
    ),
  );
}

class OpenShelfApp extends StatelessWidget {
  final AppDependencies deps;
  final MetadataAggregatorService aggregator;
  final List<BookImporter> importers;
  final ImportService importService;
  final MetadataLookupQueue lookupQueue;
  final SettingsCubit settingsCubit;
  final CoverCacheService coverCache;
  final CoverSyncService coverSync;
  final DataWipeService dataWipe;
  final CoverPicker coverPicker;
  final ExportFileSaver exportFileSaver;

  OpenShelfApp({
    super.key,
    required this.deps,
    required this.aggregator,
    required this.importers,
    required this.importService,
    required this.lookupQueue,
    required this.settingsCubit,
    required this.coverCache,
    required this.coverSync,
    required this.dataWipe,
    CoverPicker? coverPicker,
    ExportFileSaver? exportFileSaver,
  }) : coverPicker = coverPicker ?? ImagePickerCoverPicker(),
       exportFileSaver = exportFileSaver ?? PlatformExportFileSaver();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: deps.bookRepository),
        RepositoryProvider.value(value: deps.locationRepository),
        RepositoryProvider.value(value: deps.seriesRepository),
        RepositoryProvider.value(value: deps.lendingRepository),
        RepositoryProvider.value(value: deps.settingsRepository),
        RepositoryProvider.value(value: deps.exportService),
        RepositoryProvider.value(value: deps.readingRepository),
        RepositoryProvider.value(value: deps.notesRepository),
        RepositoryProvider.value(value: deps.tagRepository),
        RepositoryProvider.value(value: deps.goalRepository),
        RepositoryProvider.value(value: deps.readingTracker),
        RepositoryProvider.value(value: coverCache),
        RepositoryProvider(create: (_) => OpenLibrarySearchClient()),
        RepositoryProvider.value(value: coverSync),
        RepositoryProvider.value(value: dataWipe),
        RepositoryProvider<CoverPicker>.value(value: coverPicker),
        RepositoryProvider<ExportFileSaver>.value(value: exportFileSaver),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LibraryCubit(
              deps.bookRepository,
              tagRepository: deps.tagRepository,
              readingRepository: deps.readingRepository,
            ),
          ),
          BlocProvider(
            create: (_) =>
                TrashCubit(deps.bookRepository, coverCache: coverCache),
          ),
          BlocProvider(create: (_) => TagsCubit(deps.tagRepository)..load()),
          BlocProvider(
            create: (_) => LocationTreeCubit(deps.locationRepository),
          ),
          BlocProvider(create: (_) => LendingCubit(deps.lendingRepository)),
          BlocProvider(create: (_) => MetadataCubit(aggregator)),
          BlocProvider(
            create: (_) => ScannerCubit(deps.bookRepository, lookupQueue),
          ),
          BlocProvider(create: (_) => ImporterCubit(importService, importers)),
          BlocProvider(
            create: (_) => StatisticsCubit(
              deps.bookRepository,
              deps.locationRepository,
              goalRepository: deps.goalRepository,
              readingRepository: deps.readingRepository,
            ),
          ),
          BlocProvider.value(value: settingsCubit),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            // DynamicColorBuilder yields the wallpaper colours on platforms
            // that have them (Android 12+), otherwise nulls.
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                ThemeData theme(Brightness brightness) => buildAppTheme(
                  brightness: brightness,
                  accentColor: state.accentColor,
                  materialYou: state.materialYou,
                  dynamicScheme: brightness == Brightness.light
                      ? lightDynamic
                      : darkDynamic,
                  amoled: state.amoled,
                  fontFamily: state.fontFamily,
                );
                return MaterialApp(
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context).appTitle,
                  locale: Locale(state.localeCode),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  themeMode: state.themeMode,
                  theme: theme(Brightness.light),
                  darkTheme: theme(Brightness.dark),
                  home: const HomeShell(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _scannerIndex = 2;

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const LibraryScreen(),
      const LocationTreeScreen(),
      // Built only while its tab is open: the IndexedStack would otherwise
      // start the camera (and its permission prompt) at app launch and keep it
      // running in the background. Staged scans live in the ScannerCubit.
      if (_index == _scannerIndex)
        const ScannerScreen()
      else
        const SizedBox.shrink(),
      const StatisticsScreen(),
      const ImporterScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.library_books),
            label: AppLocalizations.of(context).navLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shelves),
            label: AppLocalizations.of(context).navShelf,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            label: AppLocalizations.of(context).navScan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context).navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.import_export),
            label: AppLocalizations.of(context).navImport,
          ),
        ],
      ),
    );
  }
}
