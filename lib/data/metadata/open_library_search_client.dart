import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/data/metadata/http_config.dart';
import 'package:openreads/domain/models/book_metadata.dart';

/// What the user types into the Open Library search.
enum OlSearchType { general, title, author, isbn, olid }

/// One work (or one edition, for an OLID lookup) found on Open Library.
class OlSearchResult {
  /// `/works/OL…W` or `/books/OL…M`.
  final String key;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final int? firstPublishYear;
  final int? pages;
  final String? isbn13;
  final String? isbn10;
  final String? publisher;
  final String? language;
  final int? coverId;

  /// The edition to use as `olid` (the cover edition, else the first one).
  final String? editionOlid;

  const OlSearchResult({
    required this.key,
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.firstPublishYear,
    this.pages,
    this.isbn13,
    this.isbn10,
    this.publisher,
    this.language,
    this.coverId,
    this.editionOlid,
  });

  bool get isWork => key.startsWith('/works/');

  /// The id without the path: `OL123W`.
  String get id => key.split('/').last;

  String? get coverUrl =>
      coverId == null ? null : OpenLibrarySearchClient.coverUrlForId(coverId!);

  BookMetadata toMetadata() => BookMetadata(
    title: title,
    subtitle: subtitle,
    authors: authors,
    publishedYear: firstPublishYear,
    pageCount: pages,
    isbn13: isbn13,
    isbn10: isbn10,
    publisher: publisher,
    language: language,
    coverUrl: coverUrl,
  );
}

/// One edition of a work.
class OlEdition {
  final String olid;
  final String title;
  final String? subtitle;
  final String? publisher;
  final int? publishYear;
  final int? pages;
  final String? isbn13;
  final String? isbn10;
  final String? language;
  final int? coverId;

  const OlEdition({
    required this.olid,
    required this.title,
    this.subtitle,
    this.publisher,
    this.publishYear,
    this.pages,
    this.isbn13,
    this.isbn10,
    this.language,
    this.coverId,
  });

  String? get coverUrl =>
      coverId == null ? null : OpenLibrarySearchClient.coverUrlForId(coverId!);
}

/// Free-text search on Open Library (general, title, author, ISBN, OLID),
/// plus the editions of a work — the Openreads "search Open Library" screens.
class OpenLibrarySearchClient {
  static const _base = 'https://openlibrary.org';
  static const _searchFields =
      'key,title,subtitle,author_name,first_publish_year,'
      'number_of_pages_median,isbn,edition_key,cover_edition_key,cover_i,'
      'publisher,language';

  /// `OL123M`, `OL123W`, `OL123A`.
  static final olidPattern = RegExp(r'^OL\d+[MWA]$', caseSensitive: false);

  final http.Client _client;
  final Duration _timeout;

  OpenLibrarySearchClient({
    http.Client? client,
    Duration timeout = metadataRequestTimeout,
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  static String coverUrlForId(int id) =>
      'https://covers.openlibrary.org/b/id/$id-L.jpg';

  /// Searches; an empty list when nothing matches or the request fails.
  Future<List<OlSearchResult>> search(
    String query,
    OlSearchType type, {
    int limit = 20,
    int offset = 0,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    if (type == OlSearchType.olid ||
        (type == OlSearchType.general && olidPattern.hasMatch(q))) {
      final one = await _byOlid(q.toUpperCase());
      return one == null ? const [] : [one];
    }

    final param = switch (type) {
      OlSearchType.title => 'title',
      OlSearchType.author => 'author',
      OlSearchType.isbn => 'isbn',
      _ => 'q',
    };
    final value = type == OlSearchType.isbn
        ? (cleanIsbn(q) ?? q.replaceAll(RegExp(r'[\s-]'), ''))
        : q;
    final uri = Uri.parse('$_base/search.json').replace(
      queryParameters: {
        param: value,
        'limit': '$limit',
        'offset': '$offset',
        'fields': _searchFields,
      },
    );

    final json = await _getJson(uri);
    final docs = json is Map<String, dynamic> ? json['docs'] : null;
    if (docs is! List) return const [];
    return [
      for (final doc in docs)
        if (doc is Map<String, dynamic> && doc['title'] is String)
          _fromDoc(doc),
    ];
  }

  /// The editions of a work (`/works/OL…W` or just `OL…W`).
  Future<List<OlEdition>> editions(String workKey, {int limit = 50}) async {
    final key = workKey.startsWith('/') ? workKey : '/works/$workKey';
    final json = await _getJson(
      Uri.parse(
        '$_base$key/editions.json',
      ).replace(queryParameters: {'limit': '$limit'}),
    );
    final entries = json is Map<String, dynamic> ? json['entries'] : null;
    if (entries is! List) return const [];
    return [
      for (final entry in entries)
        if (entry is Map<String, dynamic> && entry['title'] is String)
          _fromEdition(entry),
    ];
  }

  // ---- parsing -------------------------------------------------------------

  OlSearchResult _fromDoc(Map<String, dynamic> doc) {
    final isbns = [
      for (final i in (doc['isbn'] as List? ?? const []))
        if (i is String) i,
    ];
    String? isbn13;
    String? isbn10;
    for (final raw in isbns) {
      final clean = cleanIsbn(raw);
      if (clean == null) continue;
      if (clean.length == 13) {
        isbn13 ??= clean;
      } else {
        isbn10 ??= clean;
      }
    }
    final editionKeys = [
      for (final k in (doc['edition_key'] as List? ?? const []))
        if (k is String) k,
    ];
    return OlSearchResult(
      key: doc['key'] as String? ?? '',
      title: doc['title'] as String,
      subtitle: doc['subtitle'] as String?,
      authors: [
        for (final a in (doc['author_name'] as List? ?? const []))
          if (a is String) a,
      ],
      firstPublishYear: (doc['first_publish_year'] as num?)?.toInt(),
      pages: (doc['number_of_pages_median'] as num?)?.toInt(),
      isbn13: isbn13 ?? (isbn10 == null ? null : isbn10To13(isbn10)),
      isbn10: isbn10,
      publisher: ((doc['publisher'] as List?)?.firstOrNull) as String?,
      language: _language(((doc['language'] as List?)?.firstOrNull) as String?),
      coverId: (doc['cover_i'] as num?)?.toInt(),
      editionOlid:
          doc['cover_edition_key'] as String? ??
          (editionKeys.isEmpty ? null : editionKeys.first),
    );
  }

  OlEdition _fromEdition(Map<String, dynamic> entry) {
    String? first(String key) {
      final list = entry[key];
      return list is List && list.isNotEmpty && list.first is String
          ? list.first as String
          : null;
    }

    final languages = entry['languages'];
    final languageKey = languages is List && languages.isNotEmpty
        ? (languages.first as Map<String, dynamic>)['key'] as String?
        : null;
    final covers = entry['covers'];
    final date = entry['publish_date'] as String?;
    final year = date == null
        ? null
        : int.tryParse(RegExp(r'\d{4}').firstMatch(date)?.group(0) ?? '');
    final isbn13 = first('isbn_13');
    final isbn10 = first('isbn_10');
    return OlEdition(
      olid: (entry['key'] as String? ?? '').split('/').last,
      title: entry['title'] as String,
      subtitle: entry['subtitle'] as String?,
      publisher: first('publishers'),
      publishYear: year,
      pages: (entry['number_of_pages'] as num?)?.toInt(),
      isbn13: isbn13 ?? (isbn10 == null ? null : isbn10To13(isbn10)),
      isbn10: isbn10,
      language: _language(languageKey?.split('/').last),
      coverId: covers is List && covers.isNotEmpty && covers.first is num
          ? (covers.first as num).toInt()
          : null,
    );
  }

  Future<OlSearchResult?> _byOlid(String olid) async {
    final isEdition = olid.endsWith('M');
    final isWork = olid.endsWith('W');
    if (!isEdition && !isWork) return null;
    final path = isEdition ? '/books/$olid' : '/works/$olid';
    final json = await _getJson(Uri.parse('$_base$path.json'));
    if (json is! Map<String, dynamic> || json['title'] is! String) return null;

    // Authors are only keys here; resolve a few names.
    final authors = <String>[];
    for (final entry in (json['authors'] as List? ?? const []).take(3)) {
      final key = entry is Map<String, dynamic>
          ? (entry['key'] ?? (entry['author'] as Map?)?['key'])
          : null;
      if (key is! String) continue;
      final author = await _getJson(Uri.parse('$_base$key.json'));
      final name = author is Map<String, dynamic> ? author['name'] : null;
      if (name is String) authors.add(name);
    }

    final edition = isEdition ? _fromEdition(json) : null;
    final covers = json['covers'];
    return OlSearchResult(
      key: path,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      authors: authors,
      firstPublishYear: edition?.publishYear,
      pages: edition?.pages,
      isbn13: edition?.isbn13,
      isbn10: edition?.isbn10,
      publisher: edition?.publisher,
      language: edition?.language,
      coverId: covers is List && covers.isNotEmpty && covers.first is num
          ? (covers.first as num).toInt()
          : null,
      editionOlid: isEdition ? olid : null,
    );
  }

  Future<Object?> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': metadataUserAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  /// Open Library uses ISO 639-2 codes (`ger`); the app uses two letters.
  static String? _language(String? code) {
    if (code == null) return null;
    const map = {
      'ger': 'de',
      'eng': 'en',
      'fre': 'fr',
      'spa': 'es',
      'ita': 'it',
      'dut': 'nl',
      'por': 'pt',
      'pol': 'pl',
      'rus': 'ru',
      'swe': 'sv',
      'dan': 'da',
      'nor': 'no',
      'fin': 'fi',
      'tur': 'tr',
      'cze': 'cs',
      'jpn': 'ja',
      'chi': 'zh',
    };
    return map[code] ?? code;
  }
}
