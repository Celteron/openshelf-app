import 'package:openreads/domain/models/book_metadata.dart';
import 'package:xml/xml.dart';

/// Parses a MARC21-XML record (or a full SRU response wrapping one) into a
/// [BookMetadata].
///
/// The DNB SRU response is wrapped in `zs:searchRetrieveResponse` envelopes and
/// uses the `http://www.loc.gov/MARC21/slim` namespace. This parser is
/// namespace-agnostic: it matches elements by their local name so it accepts a
/// bare `<record>` as well as a full SRU document.
class Marc21Parser {
  const Marc21Parser();

  /// MARC21/ISO 6630 non-sorting control characters. DNB wraps non-filing
  /// articles (e.g. the "Der" in "Der Schwarm") in `\u0098`…`\u009C` and uses
  /// `\u0088`/`\u0089` as subdivision delimiters. These are markup, not content.
  static final RegExp _controlChars = RegExp(r'[\u0088\u0089\u0098\u009C]');

  /// Returns `null` when the XML is malformed or contains no data fields.
  BookMetadata? parse(String xml) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException {
      return null;
    } catch (_) {
      return null;
    }

    final datafields = _localElements(document, 'datafield');
    final controlfields = _localElements(document, 'controlfield');
    if (datafields.isEmpty && controlfields.isEmpty) return null;

    final byTag = <String, List<XmlElement>>{};
    for (final field in datafields) {
      final tag = field.getAttribute('tag');
      if (tag == null) continue;
      byTag.putIfAbsent(tag, () => []).add(field);
    }

    final isbns = _subfields(byTag, '020', 'a');
    String? isbn13;
    String? isbn10;
    for (final raw in isbns) {
      final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '');
      if (cleaned.length == 13) {
        isbn13 ??= cleaned;
      } else if (cleaned.length == 10) {
        isbn10 ??= cleaned;
      }
    }

    final authors = <String>[
      ..._subfields(byTag, '100', 'a'),
      ..._subfields(byTag, '700', 'a'),
    ];

    final publisher =
        _first(_subfields(byTag, '264', 'b')) ??
        _first(_subfields(byTag, '260', 'b'));

    final yearText =
        _first(_subfields(byTag, '264', 'c')) ??
        _first(_subfields(byTag, '260', 'c'));
    final publishedYear = _leadingYear(yearText);

    final pageCount = _leadingInt(_first(_subfields(byTag, '300', 'a')));

    // 830 is authoritative over 490 when both are present.
    final seriesName =
        _first(_subfields(byTag, '830', 'a')) ??
        _first(_subfields(byTag, '490', 'a'));
    final seriesVolume = _leadingDouble(
      _first(_subfields(byTag, '830', 'v')) ??
          _first(_subfields(byTag, '490', 'v')),
    );

    final language = _controlfieldLanguage(controlfields);

    final metadata = BookMetadata(
      isbn13: isbn13,
      isbn10: isbn10,
      title: _first(_subfields(byTag, '245', 'a')),
      subtitle: _first(_subfields(byTag, '245', 'b')),
      authors: authors,
      publisher: publisher,
      publishedYear: publishedYear,
      pageCount: pageCount,
      language: language,
      seriesName: seriesName,
      seriesVolume: seriesVolume,
    );

    return metadata.isEmpty ? null : metadata;
  }

  Iterable<XmlElement> _localElements(XmlNode root, String localName) => root
      .descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == localName);

  List<String> _subfields(
    Map<String, List<XmlElement>> byTag,
    String tag,
    String code,
  ) {
    final fields = byTag[tag];
    if (fields == null) return const [];
    final values = <String>[];
    for (final field in fields) {
      for (final subfield in field.children.whereType<XmlElement>()) {
        if (subfield.name.local == 'subfield' &&
            subfield.getAttribute('code') == code) {
          final text = subfield.innerText.replaceAll(_controlChars, '').trim();
          if (text.isNotEmpty) values.add(text);
        }
      }
    }
    return values;
  }

  String? _first(List<String> values) => values.isEmpty ? null : values.first;

  int? _leadingYear(String? text) {
    if (text == null) return null;
    final match = RegExp(r'\d{4}').firstMatch(text);
    if (match == null) return null;
    final year = int.tryParse(match.group(0)!);
    if (year == null || year < 1000 || year > 2100) return null;
    return year;
  }

  int? _leadingInt(String? text) {
    if (text == null) return null;
    final match = RegExp(r'\d+').firstMatch(text);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  double? _leadingDouble(String? text) {
    if (text == null) return null;
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text);
    return match == null
        ? null
        : double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  /// Extracts the ISO 639-2 language code from controlfield `008`,
  /// positions 35–37 (0-indexed).
  String? _controlfieldLanguage(Iterable<XmlElement> controlfields) {
    for (final field in controlfields) {
      if (field.getAttribute('tag') != '008') continue;
      final text = field.innerText;
      if (text.length >= 38) {
        final code = text.substring(35, 38).trim();
        if (code.isNotEmpty && code != '|||') return code;
      }
    }
    return null;
  }
}
