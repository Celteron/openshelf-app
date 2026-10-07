import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/series_dao.dart';
import 'package:openreads/domain/repositories/series_repository.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  final SeriesDao _dao;

  SeriesRepositoryImpl(this._dao);

  @override
  Future<Series?> findByName(String name) => _dao.findByName(name);

  @override
  Future<Series> findOrCreate(String name) => _dao.findOrCreate(name);
}
