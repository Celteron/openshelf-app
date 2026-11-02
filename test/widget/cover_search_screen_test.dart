import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';
import 'package:openreads/features/library/cover_search_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Choosing a cover found online (FR-R2-13).
void main() {
  final asked = <Uri>[];
  String? picked;

  Future<void> open(
    WidgetTester tester, {
    String? isbn,
    String? coverUrl,
    String query = 'Der Vorleser Schlink',
    List<Map<String, Object>> docs = const [],
    VoidCallback? onNothingFound,
    bool offline = false,
  }) async {
    asked.clear();
    final client = OpenLibrarySearchClient(
      client: MockClient((request) async {
        asked.add(request.url);
        if (offline) throw http.ClientException('offline');
        return http.Response.bytes(
          utf8.encode(jsonEncode({'docs': docs})),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    picked = null;
    await tester.pumpWidget(
      RepositoryProvider<OpenLibrarySearchClient>.value(
        value: client,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => CoverSearchScreen(
                      isbn: isbn,
                      coverUrl: coverUrl,
                      query: query,
                      onNothingFound: onNothingFound,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers the ISBN sources first, then other editions', (
    tester,
  ) async {
    await open(
      tester,
      isbn: '9783257229530',
      coverUrl: 'https://books.google.test/c.jpg',
      docs: [
        {'key': '/works/OL1W', 'title': 'Der Vorleser', 'cover_i': 11},
        {'key': '/works/OL2W', 'title': 'Der Vorleser', 'cover_i': 12},
        {'key': '/works/OL3W', 'title': 'Ohne Cover'},
      ],
    );

    final urls = [
      for (final w in tester.widgetList<CoverCandidateTile>(
        find.byType(CoverCandidateTile),
      ))
        w.url,
    ];
    expect(urls, [
      'https://books.google.test/c.jpg',
      dnbCoverUrl('9783257229530'),
      openLibraryCoverUrl('9783257229530'),
      OpenLibrarySearchClient.coverUrlForId(11),
      OpenLibrarySearchClient.coverUrlForId(12),
    ]);
    expect(asked.single.queryParameters['q'], 'Der Vorleser Schlink');
  });

  testWidgets('a tapped cover is the pick', (tester) async {
    await open(tester, isbn: '9783257229530');
    await tester.tap(find.byType(CoverCandidateTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(CoverSearchScreen), findsNothing);
    expect(picked, dnbCoverUrl('9783257229530'));
  });

  testWidgets('nothing found says so and reports it', (tester) async {
    var reported = 0;
    await open(tester, onNothingFound: () => reported++);

    expect(find.byKey(const ValueKey('cover-search-empty')), findsOneWidget);
    expect(reported, 1);
  });

  testWidgets('offline is not "nothing found": the book stays unmarked', (
    tester,
  ) async {
    var reported = 0;
    await open(tester, offline: true, onNothingFound: () => reported++);

    expect(find.byKey(const ValueKey('cover-search-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('cover-search-empty')), findsNothing);
    expect(reported, 0);
  });
}
