import 'package:csv/csv.dart';

/// Parses CSV content into rows, normalizing `\r\n` line endings to `\n` and
/// keeping all values as strings (so leading-zero ISBNs are preserved).
///
/// The field delimiter is detected from the header line (`,`, `;` or tab) so
/// German spreadsheet exports (`;`) parse like English ones (`,`). A leading
/// UTF-8 BOM is dropped.
List<List<dynamic>> parseCsvRows(String content) {
  final normalized = _stripBom(content).replaceAll('\r\n', '\n');
  return CsvToListConverter(
    fieldDelimiter: detectCsvDelimiter(normalized),
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(normalized);
}

/// Picks the delimiter that occurs most often in the header line, ignoring
/// quoted sections. Falls back to `,`.
String detectCsvDelimiter(String content) {
  final headerEnd = content.indexOf('\n');
  final header = headerEnd < 0 ? content : content.substring(0, headerEnd);
  final counts = {',': 0, ';': 0, '\t': 0};
  var inQuotes = false;
  for (final char in header.split('')) {
    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (!inQuotes && counts.containsKey(char)) {
      counts[char] = counts[char]! + 1;
    }
  }
  var best = ',';
  for (final entry in counts.entries) {
    if (entry.value > counts[best]!) best = entry.key;
  }
  return best;
}

String _stripBom(String content) =>
    content.startsWith('\uFEFF') ? content.substring(1) : content;
