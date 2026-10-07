import 'package:openreads/data/database/app_database.dart';

abstract class SeriesRepository {
  Future<Series?> findByName(String name);

  Future<Series> findOrCreate(String name);
}
