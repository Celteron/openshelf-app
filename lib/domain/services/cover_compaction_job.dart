import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/domain/repositories/settings_repository.dart';

/// Settings key and version of the one-off compaction of stored covers.
/// Raising the version runs it again after a change to the cover format.
const coverCompactionKey = 'coverCompactionVersion';
const coverCompactionVersion = 1;

/// Compacts the covers stored before ADR-0004, once per device and version.
///
/// The version is only recorded after a complete run, so an app closed midway
/// simply continues on the next start; already compact files are skipped.
Future<void> compactStoredCoversOnce(
  SettingsRepository settings,
  CoverCacheService covers,
) async {
  if (await settings.getValue(coverCompactionKey) ==
      '$coverCompactionVersion') {
    return;
  }
  await covers.compactStored();
  await settings.setValue(coverCompactionKey, '$coverCompactionVersion');
}
