import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/openreads_book_json.dart';
import 'package:openreads/domain/models/import.dart';

/// Restores a legacy Openreads backup archive (format v4/v5): a ZIP with
/// `books.backup` (one book JSON per entry, joined by `@@@@@`), optional
/// `challenges.backup` (yearly challenges) and one `<id>.jpg` cover per book.
///
/// Books in the legacy trash come back in the trash, covers are stored on the
/// device and the yearly challenges become reading goals. Format v3 (a SQLite
/// dump from 2022) is not supported.
class LegacyBackupImporter implements BookImporter {
  static const _booksEntry = 'books.backup';
  static const _challengesEntry = 'challenges.backup';

  @override
  String get formatName => 'Openreads backup (.zip)';

  @override
  ImportFileType get supportedType => ImportFileType.zip;

  @override
  bool canParse(ImportFile file) {
    final archive = _decode(file);
    return archive?.findFile(_booksEntry) != null;
  }

  Archive? _decode(ImportFile file) {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ImportRow> parse(ImportFile file) async* {
    final archive = _decode(file);
    final booksFile = archive?.findFile(_booksEntry);
    if (archive == null || booksFile == null) {
      yield const ImportRow(rowNumber: 0, error: 'Not an Openreads backup');
      return;
    }

    // Early v2 backups separated books with ||||| (also the tag separator).
    final raw = utf8
        .decode(booksFile.readBytes() ?? Uint8List(0))
        .replaceAll('}|||||{', '}@@@@@{');
    final entries = raw
        .split('@@@@@')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    var row = 0;
    for (final entry in entries) {
      row++;
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        final book = bookImportFromOpenreadsJson(
          map,
          coverBytes: _cover(archive, map),
          keepDeleted: true,
        );
        yield book.isEmpty
            ? ImportRow(rowNumber: row, error: 'Empty row')
            : ImportRow(rowNumber: row, book: book);
      } catch (e) {
        yield ImportRow(rowNumber: row, error: e.toString());
      }
    }

    final challenges = archive.findFile(_challengesEntry);
    if (challenges != null) {
      final text = utf8.decode(challenges.readBytes() ?? Uint8List(0));
      for (final part in text.split('|||||')) {
        if (part.trim().isEmpty) continue;
        row++;
        try {
          final map = jsonDecode(part) as Map<String, dynamic>;
          final year = (map['year'] as num?)?.toInt();
          final books = (map['books'] as num?)?.toInt();
          final pages = (map['pages'] as num?)?.toInt();
          if (year == null || ((books ?? 0) <= 0 && (pages ?? 0) <= 0)) {
            continue;
          }
          yield ImportRow(
            rowNumber: row,
            goal: GoalImport(
              year: year,
              targetBooks: books != null && books > 0 ? books : 0,
              targetPages: pages != null && pages > 0 ? pages : null,
            ),
          );
        } catch (e) {
          yield ImportRow(rowNumber: row, error: 'Challenge: $e');
        }
      }
    }
  }

  /// v5 stores `<id>.jpg` next to the books; v4 embedded the bytes as a JSON
  /// number list in `cover`.
  Uint8List? _cover(Archive archive, Map<String, dynamic> map) {
    final inline = map['cover'];
    if (inline is List && inline.isNotEmpty) {
      return Uint8List.fromList(inline.cast<int>());
    }
    final hasCover = map['has_cover'] == 1 || map['has_cover'] == true;
    final id = map['id'];
    if (hasCover && id != null) {
      return archive.findFile('$id.jpg')?.readBytes();
    }
    return null;
  }
}
