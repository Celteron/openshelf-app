@Tags(['live-network'])
library;

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:openreads/data/metadata/dnb_client.dart';
import 'package:openreads/data/metadata/google_books_client.dart';
import 'package:openreads/data/metadata/open_library_client.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:test/test.dart';

/// Live API integration tests against the real metadata sources.
///
/// These tests perform real network requests and are OFF by default so they do
/// not run in CI or offline environments. To run them:
///
///     LIVE_NETWORK=1 dart test test/integration/live_api_integration_test.dart
///
/// Known DACH ISBNs used (all confirmed present in the DNB catalogue):
///   - 9783442719255  "Wenn das Eis bricht" (Camilla Grebe, btb)
///   - 9783462033748  "Der Schwarm"         (Frank Schätzing, Kiepenheuer & Witsch)
const _grebeIsbn = '9783442719255';

/// Optional, for development only: `export GOOGLE_BOOKS_API_KEY=...` in your
/// shell. Never commit a key. The app itself runs without one.
final _googleKey = Platform.environment['GOOGLE_BOOKS_API_KEY'];
const _schwarmIsbn = '9783462033748';

void main() {
  final enabled = Platform.environment['LIVE_NETWORK'] == '1';
  const skipReason = 'Set LIVE_NETWORK=1 to run live API tests';

  group('Live metadata API integration', () {
    test('DNB SRU returns authoritative MARC21 metadata', () async {
      final client = DnbClient();
      final metadata = await client.lookupByIsbn(_grebeIsbn);

      expect(metadata, isNotNull, reason: 'DNB should resolve $_grebeIsbn');
      _print('DNB', metadata);

      expect(metadata!.title, isNotEmpty);
      expect(metadata.authors, isNotEmpty);
      expect(metadata.publisher, isNotEmpty);
      // DNB is authoritative: title/subtitle/author/publisher/year/pages.
      expect(metadata.publishedYear, isNotNull);
      expect(metadata.pageCount, isNotNull);
    }, skip: enabled ? false : skipReason);

    test('Google Books cover lookup degrades gracefully', () async {
      final client = GoogleBooksClient(apiKey: _googleKey);
      final metadata = await client.lookupByIsbn(_grebeIsbn);

      // Google Books anonymous quota may be exhausted (HTTP 429) or the edition
      // may be absent; the client must never throw and may return null.
      _print('Google Books', metadata);

      if (metadata != null) {
        expect(metadata.coverUrl, startsWith('https://'));
      }
    }, skip: enabled ? false : skipReason);

    test('Open Library lookup degrades gracefully', () async {
      final client = OpenLibraryClient();
      final metadata = await client.lookupByIsbn(_grebeIsbn);

      // German editions are frequently absent from Open Library; the client
      // must never throw.
      _print('Open Library', metadata);

      if (metadata != null) {
        expect(metadata.title, isNotEmpty);
        expect(metadata.authors, isNotEmpty);
      }
    }, skip: enabled ? false : skipReason);

    test('Aggregator: DNB is primary and merges deterministically', () async {
      final aggregator = MetadataAggregatorService([
        DnbClient(),
        GoogleBooksClient(apiKey: _googleKey),
        OpenLibraryClient(),
      ]);

      final result = await aggregator.enrich(
        const BookMetadata(isbn13: _grebeIsbn),
      );

      final metadata = result.metadata;
      _print('Aggregated', metadata);
      print('primarySource: ${result.primarySource}');
      print(
        'DNB-verified badge: ${result.primarySource == MetadataSource.dnb}',
      );

      // Core bibliographic fields come from DNB (authoritative).
      expect(result.primarySource, MetadataSource.dnb);
      expect(metadata.title, isNotEmpty);
      expect(metadata.authors, isNotEmpty);
      expect(metadata.publisher, isNotEmpty);
      expect(metadata.publishedYear, isNotNull);

      // Cover/description are Google Books enrichment and may be absent when
      // the Google Books quota is exhausted; only validate the format.
      if (metadata.coverUrl != null) {
        expect(metadata.coverUrl, startsWith('https://'));
      }
    }, skip: enabled ? false : skipReason);

    test(
      'Aggregator resolves "Der Schwarm" and preserves a user-edited title',
      () async {
        final aggregator = MetadataAggregatorService([
          DnbClient(),
          GoogleBooksClient(apiKey: _googleKey),
          OpenLibraryClient(),
        ]);

        final result = await aggregator.enrich(
          const BookMetadata(isbn13: _schwarmIsbn),
        );
        _print('Der Schwarm', result.metadata);
        expect(result.metadata.title, isNotEmpty);
        expect(result.metadata.authors, isNotEmpty);

        // User-edited title must never be overwritten (Constitution Article III).
        final preserved = await aggregator.enrich(
          const BookMetadata(isbn13: _schwarmIsbn, title: 'Mein eigener Titel'),
          editedFields: const {'title'},
        );
        expect(preserved.metadata.title, 'Mein eigener Titel');
      },
      skip: enabled ? false : skipReason,
    );
  });
}

void _print(String source, BookMetadata? m) {
  if (m == null) {
    print('[$source] (null)');
    return;
  }
  print('[$source]');
  print('  title:       ${m.title}');
  print('  subtitle:    ${m.subtitle}');
  print('  authors:     ${m.authors.join('; ')}');
  print('  publisher:   ${m.publisher}');
  print('  year:        ${m.publishedYear}');
  print('  pages:       ${m.pageCount}');
  print('  language:    ${m.language}');
  print('  series:      ${m.seriesName} (vol ${m.seriesVolume})');
  print('  isbn13:      ${m.isbn13}');
  print('  isbn10:      ${m.isbn10}');
  print('  coverUrl:    ${m.coverUrl}');
  print(
    '  description: ${m.description == null ? '' : '(${m.description!.length} chars)'}',
  );
}
