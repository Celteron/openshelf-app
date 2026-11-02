import 'dart:convert';

/// Decodes the raw bytes of an import file.
///
/// UTF-8 is tried first (strictly, so invalid sequences are detected). Legacy
/// German exports such as Bookstats are ISO-8859-1; those fall back to Latin-1
/// instead of producing mojibake. A UTF-8 BOM is removed.
String decodeImportBytes(List<int> bytes) {
  String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    text = latin1.decode(bytes);
  }
  return text.startsWith('\uFEFF') ? text.substring(1) : text;
}
