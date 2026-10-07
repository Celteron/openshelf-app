import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:openreads/domain/models/enums.dart';

/// Stores `List<String>` (e.g. authors, edited fields) as a JSON text column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <String>[];
    return (jsonDecode(fromDb) as List<dynamic>).cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

@TableIndex(name: 'idx_books_isbn10', columns: {#isbn10})
@TableIndex(name: 'idx_books_location', columns: {#locationId})
@TableIndex(name: 'idx_books_status', columns: {#status})
@TableIndex(name: 'idx_books_series', columns: {#seriesId})
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get isbn13 => text().nullable().unique()();
  TextColumn get isbn10 => text().nullable()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get authors => text().map(const StringListConverter())();
  TextColumn get publisher => text().nullable()();
  IntColumn get publishedYear => integer().nullable()();
  IntColumn get pageCount => integer().nullable()();
  TextColumn get format => textEnum<BookFormat>().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get status =>
      textEnum<BookStatus>().withDefault(const Constant('unread'))();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get locationId => integer().nullable().references(
    Locations,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get seriesId => integer().nullable().references(
    SeriesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get seriesVolume => real().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get coverLocalPath => text().nullable()();
  TextColumn get metadataSource => textEnum<MetadataSource>().nullable()();
  TextColumn get editedFields => text().map(const StringListConverter())();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<LocationType>()();
  IntColumn get parentId => integer().nullable().references(Locations, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('Series')
class SeriesTable extends Table {
  @override
  String? get tableName => 'series';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get totalPlannedVolumes => integer().nullable()();
}

@TableIndex(name: 'idx_lending_book', columns: {#bookId})
class Lending extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get borrowerName => text()();
  DateTimeColumn get lentAt => dateTime()();
  DateTimeColumn get expectedReturn => dateTime().nullable()();
  DateTimeColumn get returnedAt => dateTime().nullable()();
}
