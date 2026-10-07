import 'package:csv/csv.dart';

/// Parses CSV content into rows, normalizing `\r\n` line endings to `\n` and
/// keeping all values as strings (so leading-zero ISBNs are preserved).
List<List<dynamic>> parseCsvRows(String content) => const CsvToListConverter(
  eol: '\n',
  shouldParseNumbers: false,
).convert(content.replaceAll('\r\n', '\n'));
