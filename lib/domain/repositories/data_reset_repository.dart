/// Removes everything the app stores in its database.
abstract class DataResetRepository {
  /// Deletes every row of every table and restarts the id counters, so the
  /// database is as after a fresh install.
  Future<void> deleteAllData();
}
