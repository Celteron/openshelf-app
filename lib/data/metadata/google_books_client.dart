import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openreads/data/metadata/http_config.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';

/// Google Books client. Fills only the high-resolution cover URL and the
/// description (enrichment after DNB). Never overwrites DNB values.
class GoogleBooksClient implements MetadataSourceStrategy {
  static const _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  final http.Client _client;
  final Duration _timeout;
  final String? _apiKey;

  /// [apiKey] is optional and meant for tests and development: the anonymous
  /// quota is shared and often exhausted (HTTP 429). The app passes none, so
  /// it works without a key.
  GoogleBooksClient({
    http.Client? client,
    Duration timeout = metadataRequestTimeout,
    String? apiKey,
  }) : _client = client ?? http.Client(),
       _timeout = timeout,
       _apiKey = apiKey == null || apiKey.trim().isEmpty ? null : apiKey.trim();

  @override
  MetadataSource get id => MetadataSource.googleBooks;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': 'isbn:$isbn13',
        if (_apiKey != null) 'key': _apiKey,
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': metadataUserAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final items = json['items'];
      if (items is! List || items.isEmpty) return null;

      final volumeInfo = (items.first as Map<String, dynamic>)['volumeInfo'];
      if (volumeInfo is! Map<String, dynamic>) return null;

      final imageLinks = volumeInfo['imageLinks'];
      String? coverUrl;
      if (imageLinks is Map<String, dynamic>) {
        coverUrl = _coverUrl(imageLinks);
      }

      final description = volumeInfo['description'] as String?;

      final metadata = BookMetadata(
        coverUrl: coverUrl,
        description: description,
      );
      return metadata.isEmpty ? null : metadata;
    } catch (_) {
      return null;
    }
  }

  /// Picks the largest available cover, upgrades `thumbnail` URLs to a higher
  /// zoom level, and skips Google's generic placeholder.
  String? _coverUrl(Map<String, dynamic> imageLinks) {
    final raw =
        imageLinks['extraLarge'] ??
        imageLinks['large'] ??
        imageLinks['medium'] ??
        imageLinks['thumbnail'] ??
        imageLinks['smallThumbnail'];
    if (raw is! String || raw.isEmpty) return null;

    var cleaned = raw.replaceFirst('http://', 'https://');
    cleaned = cleaned.replaceAll('&edge=curl', '');
    // Thumbnails default to zoom=1; request a higher-resolution render.
    cleaned = cleaned.replaceAll('zoom=1', 'zoom=3');

    if (_isPlaceholder(cleaned)) return null;
    return cleaned;
  }

  /// Google returns a generic placeholder cover when no image exists; skip it.
  bool _isPlaceholder(String url) =>
      url.contains('books.google.com/books/content') && !url.contains('id=');
}
