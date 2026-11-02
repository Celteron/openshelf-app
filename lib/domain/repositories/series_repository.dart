import 'package:openreads/data/database/app_database.dart';

abstract class SeriesRepository {
  Future<Series?> findByName(String name);

  Future<Series> findOrCreate(String name);

  Future<List<Series>> getAll();

  /// Sets how many volumes the series is planned to have; `null` clears it.
  Future<void> setTotalVolumes(int id, int? total);
}
