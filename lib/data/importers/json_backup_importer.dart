import 'dart:convert';

import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/import_parsing.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/import.dart';

/// Restores an OpenShelf JSON backup (the file written by
/// `ExportService.exportJson`, schema v1 or v2/v3).
///
/// Everything the backup holds comes back: books with all their fields,
/// tags, notes and quotes, reading sessions, lending records, series, the
/// room → shelf → compartment hierarchy (also empty shelves), yearly goals and
/// the trash state. Rows are restored *exactly* as written — no derived
/// progress — and flow through the normal import pipeline, so restoring into a
/// library that already has some of the books merges instead of duplicating.
///
/// Local cover files are not part of a JSON backup; covers that were known by
/// URL are downloaded again on demand.
class JsonBackupImporter implements BookImporter {
  @override
  String get formatName => 'OpenShelf JSON backup';

  @override
  ImportFileType get supportedType => ImportFileType.json;

  @override
  bool canParse(ImportFile file) {
    try {
      final decoded = jsonDecode(file.content);
      return decoded is Map<String, dynamic> &&
          decoded['books'] is List &&
          decoded['locations'] is List &&
          decoded.containsKey('exportedAt');
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<ImportRow> parse(ImportFile file) async* {
    final Map<String, dynamic> root;
    try {
      root = jsonDecode(file.content) as Map<String, dynamic>;
    } catch (_) {
      yield const ImportRow(rowNumber: 0, error: 'Malformed JSON');
      return;
    }

    final locations = _byId(_maps(root['locations']));
    final series = _byId(_maps(root['series']));
    final tagNames = {
      for (final t in _maps(root['tags'])) _int(t['id']): _str(t['name']),
    };
    final tagsByBook = <int, List<String>>{};
    for (final link in _maps(root['bookTags'])) {
      final name = tagNames[_int(link['tagId'])];
      final bookId = _int(link['bookId']);
      if (name != null && bookId != null) {
        (tagsByBook[bookId] ??= []).add(name);
      }
    }
    final notesByBook = _group(_maps(root['notes']), 'bookId');
    final sessionsByBook = _group(_maps(root['readingSessions']), 'bookId');
    final lendingByBook = _group(_maps(root['lending']), 'bookId');

    var row = 0;

    // Every location, so empty shelves survive the round trip.
    final emittedPaths = <String>{};
    for (final id in locations.keys) {
      final path = _locationPath(id, locations);
      if (path.isEmpty) continue;
      if (emittedPaths.add(path.map((p) => p.name).join('\u0000'))) {
        yield ImportRow(rowNumber: ++row, location: path);
      }
    }

    // Every tag, so tags that no book uses survive the round trip too.
    for (final name in tagNames.values) {
      if (name != null) yield ImportRow(rowNumber: ++row, tag: name);
    }

    final books = _maps(root['books']);
    for (var i = 0; i < books.length; i++) {
      final map = books[i];
      row++;
      try {
        final id = _int(map['id']);
        final seriesRow = series[_int(map['seriesId'])];
        yield ImportRow(
          rowNumber: row,
          book: BookImport(
            title: _str(map['title']),
            subtitle: _str(map['subtitle']),
            authors: [
              for (final a in (map['authors'] as List? ?? const []))
                if (a is String && a.trim().isNotEmpty) a,
            ],
            isbn13: _str(map['isbn13']),
            isbn10: _str(map['isbn10']),
            publisher: _str(map['publisher']),
            publishedYear: _int(map['publishedYear']),
            pageCount: _int(map['pageCount']),
            format: _enum(BookFormat.values, map['format']),
            language: _str(map['language']),
            description: _str(map['description']),
            coverUrl: _str(map['coverUrl']),
            rating: (map['rating'] as num?)?.toDouble(),
            status: _enum(BookStatus.values, map['status']),
            isFavorite: map['isFavorite'] == true,
            review: _str(map['review']),
            olid: _str(map['olid']),
            genre: _str(map['genre']),
            priceCents: _int(map['priceCents']),
            receivedAt: _date(map['receivedAt']),
            receivedAs: parseReceivedAs(switch (map['receivedAs']) {
              final String s => s,
              _ => null,
            }),
            readingSeconds: _int(map['readingSeconds']),
            seriesName: _str(seriesRow?['name']),
            seriesTotalVolumes: _int(seriesRow?['totalPlannedVolumes']),
            seriesVolume: (map['seriesVolume'] as num?)?.toDouble(),
            locationPath: _locationPath(_int(map['locationId']), locations),
            metadataSource: _enum(MetadataSource.values, map['metadataSource']),
            editedFields: [
              for (final f in (map['editedFields'] as List? ?? const []))
                if (f is String) f,
            ],
            currentPage: _int(map['currentPage']) ?? 0,
            finishedAt: _date(map['finishedAt']),
            addedAt: _date(map['createdAt']),
            updatedAt: _date(map['updatedAt']),
            deletedAt: _date(map['deletedAt']),
            tags: tagsByBook[id] ?? const [],
            notes: [
              for (final n in notesByBook[id] ?? const <Map<String, dynamic>>[])
                if (_str(n['content']) != null)
                  NoteImport(
                    kind: _enum(NoteKind.values, n['kind']) ?? NoteKind.note,
                    content: _str(n['content'])!,
                    pageNumber: _int(n['pageNumber']),
                    createdAt: _date(n['createdAt']),
                    updatedAt: _date(n['updatedAt']),
                  ),
            ],
            readings: [
              for (final s
                  in sessionsByBook[id] ?? const <Map<String, dynamic>>[])
                if (_date(s['startedAt']) != null)
                  ReadingImport(
                    startedAt: _date(s['startedAt']),
                    finishedAt: _date(s['endedAt']),
                    duration: Duration(
                      seconds: _int(s['durationSeconds']) ?? 0,
                    ),
                    startPage: _int(s['startPage']) ?? 0,
                    endPage: _int(s['endPage']),
                    open: s['endedAt'] == null,
                  ),
            ],
            lendings: [
              for (final l
                  in lendingByBook[id] ?? const <Map<String, dynamic>>[])
                if (_str(l['borrowerName']) != null &&
                    _date(l['lentAt']) != null)
                  LendingImport(
                    borrowerName: _str(l['borrowerName'])!,
                    lentAt: _date(l['lentAt'])!,
                    expectedReturn: _date(l['expectedReturn']),
                    returnedAt: _date(l['returnedAt']),
                  ),
            ],
            exact: true,
          ),
        );
      } catch (e) {
        yield ImportRow(rowNumber: row, error: e.toString());
      }
    }

    for (final goal in _maps(root['readingGoals'])) {
      final year = _int(goal['year']);
      final target = _int(goal['targetBooks']);
      if (year == null || target == null) continue;
      yield ImportRow(
        rowNumber: ++row,
        goal: GoalImport(
          year: year,
          targetBooks: target,
          targetPages: _int(goal['targetPages']),
        ),
      );
    }
  }

  // ---- helpers -------------------------------------------------------------

  static List<Map<String, dynamic>> _maps(Object? value) => [
    for (final item in (value is List ? value : const []))
      if (item is Map<String, dynamic>) item,
  ];

  static Map<int, Map<String, dynamic>> _byId(List<Map<String, dynamic>> rows) {
    final result = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = _int(row['id']);
      if (id != null) result[id] = row;
    }
    return result;
  }

  static Map<int?, List<Map<String, dynamic>>> _group(
    List<Map<String, dynamic>> rows,
    String key,
  ) {
    final result = <int?, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      (result[_int(row[key])] ??= []).add(row);
    }
    return result;
  }

  /// Names (and types) from the room down to [id], following `parentId`.
  static List<LocationRef> _locationPath(
    int? id,
    Map<int, Map<String, dynamic>> locations,
  ) {
    final path = <LocationRef>[];
    var current = id == null ? null : locations[id];
    var guard = 0;
    while (current != null && guard++ < 16) {
      final name = _str(current['name']);
      if (name != null) {
        path.insert(
          0,
          LocationRef(
            name,
            _enum(LocationType.values, current['type']) ?? LocationType.room,
          ),
        );
      }
      final parent = _int(current['parentId']);
      current = parent == null ? null : locations[parent];
    }
    return path;
  }

  static String? _str(Object? v) {
    if (v is! String) return null;
    final trimmed = v.trim();
    return trimmed.isEmpty ? null : v;
  }

  static int? _int(Object? v) => v is num ? v.toInt() : null;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static T? _enum<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
