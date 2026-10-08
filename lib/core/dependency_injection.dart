import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/goals_dao.dart';
import 'package:openreads/data/database/daos/lending_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/database/daos/notes_dao.dart';
import 'package:openreads/data/database/daos/reading_dao.dart';
import 'package:openreads/data/database/daos/series_dao.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/data_reset_repository_impl.dart';
import 'package:openreads/data/repositories/goal_repository_impl.dart';
import 'package:openreads/data/repositories/lending_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/data/repositories/notes_repository_impl.dart';
import 'package:openreads/data/repositories/reading_repository_impl.dart';
import 'package:openreads/data/repositories/series_repository_impl.dart';
import 'package:openreads/data/repositories/settings_repository_impl.dart';
import 'package:openreads/data/repositories/tag_repository_impl.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/data_reset_repository.dart';
import 'package:openreads/domain/repositories/goal_repository.dart';
import 'package:openreads/domain/repositories/lending_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/repositories/series_repository.dart';
import 'package:openreads/domain/repositories/settings_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/domain/services/reading_tracker_service.dart';

/// Wires the persistence layer: [AppDatabase] → DAOs → repository interfaces.
///
/// The presentation layer depends only on the repository interfaces exposed
/// here, never on `package:drift` (Constitution Article II).
class AppDependencies {
  final AppDatabase database;

  late final BookRepository bookRepository;
  late final LocationRepository locationRepository;
  late final SeriesRepository seriesRepository;
  late final LendingRepository lendingRepository;
  late final SettingsRepository settingsRepository;
  late final ExportService exportService;
  late final ReadingRepository readingRepository;
  late final NotesRepository notesRepository;
  late final TagRepository tagRepository;
  late final GoalRepository goalRepository;
  late final ReadingTrackerService readingTracker;
  late final DataResetRepository dataResetRepository;

  AppDependencies(this.database) {
    bookRepository = BookRepositoryImpl(BooksDao(database));
    locationRepository = LocationRepositoryImpl(LocationsDao(database));
    seriesRepository = SeriesRepositoryImpl(SeriesDao(database));
    lendingRepository = LendingRepositoryImpl(LendingDao(database));
    settingsRepository = SettingsRepositoryImpl();
    exportService = ExportService(database);
    readingRepository = ReadingRepositoryImpl(ReadingDao(database));
    notesRepository = NotesRepositoryImpl(NotesDao(database));
    tagRepository = TagRepositoryImpl(TagsDao(database));
    goalRepository = GoalRepositoryImpl(GoalsDao(database));
    readingTracker = ReadingTrackerService(bookRepository, readingRepository);
    dataResetRepository = DataResetRepositoryImpl(database);
  }
}
