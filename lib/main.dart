import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/dependency_injection.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/bookstats_csv_importer.dart';
import 'package:openreads/data/importers/bookstats_json_importer.dart';
import 'package:openreads/data/importers/goodreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/importers/storygraph_csv_importer.dart';
import 'package:openreads/data/metadata/dnb_client.dart';
import 'package:openreads/data/metadata/google_books_client.dart';
import 'package:openreads/data/metadata/open_library_client.dart';
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

  final aggregator = MetadataAggregatorService([
    DnbClient(),
    GoogleBooksClient(),
    OpenLibraryClient(),
  ]);

  final importers = [
    OpenreadsCsvImporter(),
    OpenreadsJsonImporter(),
    GoodreadsCsvImporter(),
    StoryGraphCsvImporter(),
    BookstatsCsvImporter(),
    BookstatsJsonImporter(),
  ];

  final importService = ImportService(deps.bookRepository);
  final lookupQueue = MetadataLookupQueue(aggregator);
  final settingsCubit = SettingsCubit(deps.settingsRepository);
  await settingsCubit.load();

  runApp(
    OpenShelfApp(
      deps: deps,
      aggregator: aggregator,
      importers: importers,
      importService: importService,
      lookupQueue: lookupQueue,
      settingsCubit: settingsCubit,
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

  const OpenShelfApp({
    super.key,
    required this.deps,
    required this.aggregator,
    required this.importers,
    required this.importService,
    required this.lookupQueue,
    required this.settingsCubit,
  });

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LibraryCubit(
              deps.bookRepository,
              tagRepository: deps.tagRepository,
            ),
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
            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              locale: Locale(state.localeCode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              themeMode: state.themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              home: const HomeShell(),
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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const LibraryScreen(),
      const LocationTreeScreen(),
      const ScannerScreen(),
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
