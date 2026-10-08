import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/data_reset_repository.dart';
import 'package:openreads/domain/repositories/settings_repository.dart';

/// The destructive "start over" actions of the settings screen.
///
/// Callers confirm with the user first; nothing here asks.
class DataWipeService {
  final BookRepository _books;
  final DataResetRepository _reset;
  final SettingsRepository _settings;
  final CoverCacheService _covers;

  DataWipeService({
    required BookRepository books,
    required DataResetRepository reset,
    required SettingsRepository settings,
    required CoverCacheService covers,
  }) : _books = books,
       _reset = reset,
       _settings = settings,
       _covers = covers;

  /// Moves every book to the trash (restorable); returns how many.
  Future<int> trashLibrary() => _books.trashAllBooks();

  /// Deletes every book for good, incl. the trash, and its cover files.
  /// Locations, tags, goals and settings stay.
  Future<int> deleteLibrary() async {
    final count = await _books.deleteAllBooksPermanently();
    await _covers.deleteAll();
    return count;
  }

  /// Deletes all local app data: database, covers and settings.
  Future<void> deleteAllData() async {
    await _reset.deleteAllData();
    await _covers.deleteAll();
    await _settings.clearAll();
  }
}
