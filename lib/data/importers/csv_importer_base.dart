import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/column_mapper.dart';
import 'package:openreads/data/importers/csv_utils.dart';
import 'package:openreads/domain/models/import.dart';

/// Shared base for CSV importers: detects the header row, maps each source
/// header to a canonical field via the [ColumnMapper], and lazily emits one
/// [ImportRow] per data row.
abstract class CsvImporter implements BookImporter {
  @override
  ImportFileType get supportedType => ImportFileType.csv;

  ColumnMapper get columnMapper;

  @override
  bool canParse(ImportFile file) {
    final header = _header(file);
    if (header == null) return false;
    return expectedHeaders.every(header.contains);
  }

  /// The canonical fields a column of this format can be assigned to in the
  /// matcher: everything the format maps by default.
  Set<String> get mappableFields => columnMapper.headerToField.values.toSet();

  /// The source columns of [file] with a sample from the first data row.
  List<({String header, String sample})> columns(ImportFile file) {
    try {
      final rows = parseCsvRows(file.content);
      if (rows.isEmpty) return const [];
      final first = rows.length > 1 ? rows[1] : const <dynamic>[];
      return [
        for (var i = 0; i < rows.first.length; i++)
          (
            header: rows.first[i].toString().trim(),
            sample: i < first.length ? first[i].toString().trim() : '',
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Lowercased headers that identify this format.
  Set<String> get expectedHeaders;

  /// Builds a [BookImport] from a canonical field → value map, or returns
  /// `null` for a row that must be skipped.
  BookImport? buildBook(Map<String, String> fields);

  /// Parses [file]. [columnFields] (column index → field) chosen in the
  /// matcher replaces the format's default header → field mapping.
  @override
  Stream<ImportRow> parse(
    ImportFile file, {
    Map<int, String>? columnFields,
  }) async* {
    final List<List<dynamic>> rows;
    try {
      rows = parseCsvRows(file.content);
    } catch (_) {
      yield const ImportRow(rowNumber: 0, error: 'Malformed CSV');
      return;
    }
    if (rows.isEmpty) return;

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final indexToField = columnFields ?? <int, String>{};
    if (columnFields == null) {
      for (var i = 0; i < header.length; i++) {
        final field = columnMapper.fieldForHeader(header[i]);
        if (field != null) indexToField[i] = field;
      }
    }

    for (var r = 1; r < rows.length; r++) {
      final values = rows[r];
      final fields = <String, String>{};
      indexToField.forEach((index, field) {
        final raw = index < values.length
            ? values[index].toString().trim()
            : '';
        if (raw.isNotEmpty) {
          // Merge multiple source columns into one canonical field (e.g.
          // "Author" + "Additional Authors" → authors) joined by ';'.
          fields[field] = fields.containsKey(field)
              ? '${fields[field]};$raw'
              : raw;
        }
      });

      try {
        final book = buildBook(fields);
        if (book == null || book.isEmpty) {
          yield ImportRow(rowNumber: r + 1, error: 'Empty row');
        } else {
          yield ImportRow(rowNumber: r + 1, book: book);
        }
      } catch (e) {
        yield ImportRow(
          rowNumber: r + 1,
          error: e is FormatException ? e.message : e.toString(),
        );
      }
    }
  }

  List<String>? _header(ImportFile file) {
    try {
      final rows = parseCsvRows(file.content);
      if (rows.isEmpty) return null;
      return rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    } catch (_) {
      return null;
    }
  }
}
