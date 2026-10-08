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

  /// Last page the reader reached (Phase 2, schema v2).
  IntColumn get currentPage => integer().withDefault(const Constant(0))();

  /// When the book last transitioned into `read` (Phase 2, schema v2).
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Favourite flag (Openreads `favourite`, Phase 2 schema v2).
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// The reader's own review text (Openreads `my_review`, schema v2).
  TextColumn get review => text().nullable()();

  /// Open Library ID (Openreads `olid`, schema v3).
  TextColumn get olid => text().nullable()();

  /// When the book was moved to the trash; `null` = in the library
  /// (Openreads soft delete, schema v3).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Free-text genre; user-editable and never overwritten by imports
  /// (schema v4).
  TextColumn get genre => text().nullable()();

  /// Purchase price in euro cents (integer, so no float rounding); a currency
  /// column can be added later (schema v4).
  IntColumn get priceCents => integer().nullable()();

  /// When the book was bought or received (schema v4).
  DateTimeColumn get receivedAt => dateTime().nullable()();

  /// Reading time entered without any dated session (e.g. imported from a
  /// source that only knows a total). Added to the sessions' time (schema v5).
  IntColumn get readingSeconds => integer().nullable()();
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

/// A reading session (Phase 2). A row with a null [endedAt] is the book's
/// currently running timer, so an active session survives app restarts.
@TableIndex(name: 'idx_reading_sessions_book', columns: {#bookId})
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get startPage => integer().withDefault(const Constant(0))();
  IntColumn get endPage => integer().nullable()();
}

/// A note or a quote attached to a book (Phase 2).
@TableIndex(name: 'idx_book_notes_book', columns: {#bookId})
class BookNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<NoteKind>()();
  TextColumn get content => text()();
  IntColumn get pageNumber => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class BookTags extends Table {
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {bookId, tagId};
}

/// One reading goal per calendar year (Phase 2).
class ReadingGoals extends Table {
  IntColumn get year => integer()();
  IntColumn get targetBooks => integer()();

  /// Optional page goal (Openreads `YearlyChallenge.pages`).
  IntColumn get targetPages => integer().nullable()();

  @override
  Set<Column> get primaryKey => {year};
}
