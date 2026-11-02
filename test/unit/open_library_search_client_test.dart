import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';

void main() {
  late List<Uri> requests;

  OpenLibrarySearchClient clientFor(
    Map<String, Object?> routes, {
    int status = 200,
  }) {
    requests = [];
    return OpenLibrarySearchClient(
      client: MockClient((req) async {
        requests.add(req.url);
        final body = routes[req.url.path];
        if (body == null) return http.Response('not found', 404);
        return http.Response.bytes(
          utf8.encode(jsonEncode(body)),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  final doc = {
    'key': '/works/OL45W',
    'title': 'Der Vorleser',
    'subtitle': 'Roman',
    'author_name': ['Bernhard Schlink'],
    'first_publish_year': 1995,
    'number_of_pages_median': 207,
    'isbn': ['3257229534', '9783257229530', 'garbage'],
    'publisher': ['Diogenes'],
    'language': ['ger', 'eng'],
    'cover_i': 1234,
    'cover_edition_key': 'OL99M',
    'edition_key': ['OL1M', 'OL99M'],
  };

  group('search', () {
    test('uses the right parameter for each search type', () async {
      final client = clientFor({
        '/search.json': {'docs': []},
      });

      await client.search('dune', OlSearchType.general);
      await client.search('dune', OlSearchType.title);
      await client.search('herbert', OlSearchType.author);
      await client.search('978-3-257-22953-0', OlSearchType.isbn);

      expect(requests.map((u) => u.queryParameters.keys.first), [
        'q',
        'title',
        'author',
        'isbn',
      ]);
      expect(requests[3].queryParameters['isbn'], '9783257229530');
      expect(requests.first.queryParameters['limit'], '20');
      expect(requests.first.queryParameters['fields'], contains('cover_i'));
    });

    test('maps a search document', () async {
      final client = clientFor({
        '/search.json': {
          'docs': [doc],
        },
      });

      final r = (await client.search('vorleser', OlSearchType.title)).single;

      expect(r.key, '/works/OL45W');
      expect(r.isWork, isTrue);
      expect(r.id, 'OL45W');
      expect(r.title, 'Der Vorleser');
      expect(r.subtitle, 'Roman');
      expect(r.authors, ['Bernhard Schlink']);
      expect(r.firstPublishYear, 1995);
      expect(r.pages, 207);
      expect(r.isbn13, '9783257229530');
      expect(r.isbn10, '3257229534');
      expect(r.publisher, 'Diogenes');
      expect(r.language, 'de');
      expect(r.coverId, 1234);
      expect(r.coverUrl, 'https://covers.openlibrary.org/b/id/1234-L.jpg');
      expect(r.editionOlid, 'OL99M', reason: 'the cover edition');
    });

    test('derives the ISBN-13 from an ISBN-10-only result', () async {
      final client = clientFor({
        '/search.json': {
          'docs': [
            {
              'key': '/works/OL1W',
              'title': 'X',
              'isbn': ['3257229534'],
            },
          ],
        },
      });
      final r = (await client.search('x', OlSearchType.general)).single;
      expect(r.isbn13, '9783257229530');
      expect(r.isbn10, '3257229534');
    });

    test(
      'falls back to the first edition key and skips docs without a title',
      () async {
        final client = clientFor({
          '/search.json': {
            'docs': [
              {
                'key': '/works/OL1W',
                'title': 'A',
                'edition_key': ['OL7M'],
              },
              {'key': '/works/OL2W'},
            ],
          },
        });
        final results = await client.search('a', OlSearchType.general);
        expect(results, hasLength(1));
        expect(results.single.editionOlid, 'OL7M');
      },
    );

    test('toMetadata carries everything the form needs', () async {
      final client = clientFor({
        '/search.json': {
          'docs': [doc],
        },
      });
      final m = (await client.search(
        'v',
        OlSearchType.general,
      )).single.toMetadata();

      expect(m.title, 'Der Vorleser');
      expect(m.authors, ['Bernhard Schlink']);
      expect(m.publishedYear, 1995);
      expect(m.pageCount, 207);
      expect(m.isbn13, '9783257229530');
      expect(m.publisher, 'Diogenes');
      expect(m.language, 'de');
      expect(m.coverUrl, contains('1234'));
    });

    test('blank queries and failures give an empty list', () async {
      final client = clientFor({});
      expect(await client.search('  ', OlSearchType.general), isEmpty);
      expect(requests, isEmpty);
      expect(await client.search('x', OlSearchType.general), isEmpty);

      final offline = OpenLibrarySearchClient(
        client: MockClient((_) async => throw Exception('offline')),
      );
      expect(await offline.search('x', OlSearchType.general), isEmpty);
    });

    test('a malformed response gives an empty list', () async {
      final client = clientFor({'/search.json': 'surprise'});
      expect(await client.search('x', OlSearchType.general), isEmpty);
    });
  });

  group('OLID lookup', () {
    test('an edition id is resolved with its authors', () async {
      final client = clientFor({
        '/books/OL99M.json': {
          'key': '/books/OL99M',
          'title': 'Der Vorleser',
          'publishers': ['Diogenes'],
          'publish_date': 'March 1997',
          'number_of_pages': 207,
          'isbn_13': ['9783257229530'],
          'covers': [555],
          'languages': [
            {'key': '/languages/ger'},
          ],
          'authors': [
            {'key': '/authors/OL1A'},
          ],
        },
        '/authors/OL1A.json': {'name': 'Bernhard Schlink'},
      });

      final r = (await client.search('ol99m', OlSearchType.olid)).single;

      expect(r.key, '/books/OL99M');
      expect(r.isWork, isFalse);
      expect(r.authors, ['Bernhard Schlink']);
      expect(r.firstPublishYear, 1997);
      expect(r.pages, 207);
      expect(r.isbn13, '9783257229530');
      expect(r.coverId, 555);
      expect(r.language, 'de');
      expect(r.editionOlid, 'OL99M');
    });

    test('a work id works, and general search detects OLIDs', () async {
      final client = clientFor({
        '/works/OL45W.json': {
          'title': 'Der Vorleser',
          'authors': [
            {
              'author': {'key': '/authors/OL1A'},
            },
          ],
        },
        '/authors/OL1A.json': {'name': 'Bernhard Schlink'},
      });

      final r = (await client.search('OL45W', OlSearchType.general)).single;

      expect(r.key, '/works/OL45W');
      expect(r.isWork, isTrue);
      expect(r.authors, ['Bernhard Schlink']);
      expect(r.editionOlid, isNull);
    });

    test('unknown or unsupported ids give nothing', () async {
      final client = clientFor({});
      expect(await client.search('OL1M', OlSearchType.olid), isEmpty);
      expect(
        await client.search('OL1A', OlSearchType.olid),
        isEmpty,
        reason: 'author ids are not books',
      );
    });

    test('the OLID pattern', () {
      final p = OpenLibrarySearchClient.olidPattern;
      expect(p.hasMatch('OL123M'), isTrue);
      expect(p.hasMatch('ol9w'), isTrue);
      expect(p.hasMatch('OL12'), isFalse);
      expect(p.hasMatch('Dune'), isFalse);
    });
  });

  group('editions', () {
    test('lists the editions of a work', () async {
      final client = clientFor({
        '/works/OL45W/editions.json': {
          'entries': [
            {
              'key': '/books/OL1M',
              'title': 'Der Vorleser',
              'publishers': ['Diogenes'],
              'publish_date': '1997',
              'number_of_pages': 207,
              'isbn_10': ['3257229534'],
              'covers': [11],
              'languages': [
                {'key': '/languages/ger'},
              ],
            },
            {
              'key': '/books/OL2M',
              'title': 'The Reader',
              'isbn_13': ['9780375707971'],
            },
            {'key': '/books/OL3M'},
          ],
        },
      });

      final editions = await client.editions('/works/OL45W');

      expect(requests.single.path, '/works/OL45W/editions.json');
      expect(editions, hasLength(2));
      expect(editions.first.olid, 'OL1M');
      expect(editions.first.publisher, 'Diogenes');
      expect(editions.first.publishYear, 1997);
      expect(editions.first.isbn13, '9783257229530');
      expect(editions.first.language, 'de');
      expect(editions.first.coverUrl, contains('/11-L.jpg'));
      expect(editions.last.isbn13, '9780375707971');
      expect(editions.last.coverUrl, isNull);
    });

    test('accepts a bare id and survives failures', () async {
      final client = clientFor({
        '/works/OL45W/editions.json': {'entries': []},
      });
      expect(await client.editions('OL45W'), isEmpty);
      expect(requests.single.path, '/works/OL45W/editions.json');
      expect(await clientFor({}).editions('OL1W'), isEmpty);
    });
  });
}
