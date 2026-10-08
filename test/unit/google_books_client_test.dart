import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/metadata/google_books_client.dart';

/// The key is optional and only meant for tests and development; the app runs
/// without one (the default).
void main() {
  late List<Uri> requested;

  http.Client client() => MockClient((request) async {
    requested.add(request.url);
    return http.Response(jsonEncode({'items': []}), 200);
  });

  setUp(() => requested = []);

  test('sends no key by default', () async {
    await GoogleBooksClient(client: client()).lookupByIsbn('9783833874239');

    expect(requested.single.queryParameters, {'q': 'isbn:9783833874239'});
  });

  test('sends the key when one is given', () async {
    await GoogleBooksClient(
      client: client(),
      apiKey: 'test-key',
    ).lookupByIsbn('9783833874239');

    expect(requested.single.queryParameters['key'], 'test-key');
  });

  test('a blank key counts as no key', () async {
    await GoogleBooksClient(
      client: client(),
      apiKey: '  ',
    ).lookupByIsbn('9783833874239');

    expect(requested.single.queryParameters.containsKey('key'), isFalse);
  });

  test('a rate limit (429) is a quiet miss, not an error', () async {
    final limited = MockClient((_) async => http.Response('quota', 429));

    expect(
      await GoogleBooksClient(client: limited).lookupByIsbn('9783833874239'),
      isNull,
    );
  });
}
