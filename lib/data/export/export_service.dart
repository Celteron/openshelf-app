import 'dart:convert';

import 'package:openreads/data/database/app_database.dart';

/// Serializes the full library (books, locations, series, lending) to portable
/// JSON/CSV so users can export all their data (Constitution Article I.3).
class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  Future<String> exportJson() async {
    final books = await _db.select(_db.books).get();
    final locations = await _db.select(_db.locations).get();
    final series = await _db.select(_db.seriesTable).get();
    final lending = await _db.select(_db.lending).get();

    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books.map(_book).toList(),
      'locations': locations.map(_location).toList(),
      'series': series.map(_series).toList(),
      'lending': lending.map(_lending).toList(),
    });
  }

  Future<String> exportBooksCsv() async {
    final books = await _db.select(_db.books).get();
    final buffer = StringBuffer(
      'Title,Subtitle,Authors,ISBN13,ISBN10,Publisher,Year,Pages,Status,Rating,Format\n',
    );
    for (final b in books) {
      buffer.writeln(
        [
          _csv(b.title),
          _csv(b.subtitle ?? ''),
          _csv(b.authors.join(';')),
          _csv(b.isbn13 ?? ''),
          _csv(b.isbn10 ?? ''),
          _csv(b.publisher ?? ''),
          b.publishedYear?.toString() ?? '',
          b.pageCount?.toString() ?? '',
          b.status.name,
          b.rating.toString(),
          b.format?.name ?? '',
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  Map<String, dynamic> _book(Book b) => {
    'id': b.id,
    'isbn13': b.isbn13,
    'isbn10': b.isbn10,
    'title': b.title,
    'subtitle': b.subtitle,
    'authors': b.authors,
    'publisher': b.publisher,
    'publishedYear': b.publishedYear,
    'pageCount': b.pageCount,
    'format': b.format?.name,
    'language': b.language,
    'status': b.status.name,
    'rating': b.rating,
    'locationId': b.locationId,
    'seriesId': b.seriesId,
    'seriesVolume': b.seriesVolume,
    'description': b.description,
    'coverUrl': b.coverUrl,
    'coverLocalPath': b.coverLocalPath,
    'metadataSource': b.metadataSource?.name,
    'editedFields': b.editedFields,
    'createdAt': b.createdAt.toIso8601String(),
    'updatedAt': b.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _location(Location l) => {
    'id': l.id,
    'name': l.name,
    'type': l.type.name,
    'parentId': l.parentId,
    'sortOrder': l.sortOrder,
  };

  Map<String, dynamic> _series(Series s) => {
    'id': s.id,
    'name': s.name,
    'totalPlannedVolumes': s.totalPlannedVolumes,
  };

  Map<String, dynamic> _lending(LendingData l) => {
    'id': l.id,
    'bookId': l.bookId,
    'borrowerName': l.borrowerName,
    'lentAt': l.lentAt.toIso8601String(),
    'expectedReturn': l.expectedReturn?.toIso8601String(),
    'returnedAt': l.returnedAt?.toIso8601String(),
  };
}
