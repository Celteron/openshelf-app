import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openreads/data/metadata/http_config.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';

/// Open Library client. Fallback source used only when DNB and Google Books
/// yield nothing.
class OpenLibraryClient implements MetadataSourceStrategy {
  static const _baseUrl = 'https://openlibrary.org/api/books';

  final http.Client _client;
  final Duration _timeout;

  OpenLibraryClient({
    http.Client? client,
    Duration timeout = metadataRequestTimeout,
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  @override
  MetadataSource get id => MetadataSource.openLibrary;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'bibkeys': 'ISBN:$isbn13',
        'format': 'json',
        'jscmd': 'data',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': metadataUserAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      final entry = json['ISBN:$isbn13'];
      if (entry is! Map<String, dynamic>) return null;

      final authors =
          (entry['authors'] as List?)
              ?.map((a) => (a as Map<String, dynamic>)['name'] as String?)
              .whereType<String>()
              .toList() ??
          const [];

      String? publisher;
      final publishers = entry['publishers'] as List?;
      if (publishers != null && publishers.isNotEmpty) {
        publisher =
            (publishers.first as Map<String, dynamic>)['name'] as String?;
      }

      int? publishedYear;
      final publishDate = entry['publish_date'] as String?;
      if (publishDate != null) {
        final match = RegExp(r'\d{4}').firstMatch(publishDate);
        if (match != null) publishedYear = int.tryParse(match.group(0)!);
      }

      String? coverUrl;
      final cover = entry['cover'] as Map<String, dynamic>?;
      if (cover != null) {
        final raw = cover['large'] ?? cover['medium'];
        if (raw is String && raw.isNotEmpty) coverUrl = raw;
      }

      final metadata = BookMetadata(
        isbn13: isbn13,
        title: entry['title'] as String?,
        authors: authors,
        publisher: publisher,
        publishedYear: publishedYear,
        coverUrl: coverUrl,
      );

      return metadata.isEmpty ? null : metadata;
    } catch (_) {
      return null;
    }
  }
}
