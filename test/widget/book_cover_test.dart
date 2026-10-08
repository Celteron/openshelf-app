import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';

import '../helpers/test_images.dart';

class _Repo implements BookRepository {
  final paths = <int, String?>{};

  @override
  Future<void> setCoverLocalPath(int id, String? path) async =>
      paths[id] = path;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book book({
  int id = 1,
  String? isbn13,
  String? coverUrl,
  String? coverLocalPath,
}) => Book(
  id: id,
  title: 'Titel',
  authors: const ['A'],
  status: BookStatus.unread,
  rating: 0,
  isbn13: isbn13,
  coverUrl: coverUrl,
  coverLocalPath: coverLocalPath,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late Directory dir;
  var requests = 0;
  var failing = false;

  CoverCacheService service() => CoverCacheService(
    baseDirectory: dir,
    client: MockClient((_) async {
      requests++;
      return failing
          ? http.Response('nope', 404)
          : http.Response.bytes(
              testPng(),
              200,
              headers: {'content-type': 'image/png'},
            );
    }),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('book_cover_test');
    requests = 0;
    failing = false;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    CoverCacheService? cache,
    BookRepository? repo,
  }) async {
    final app = MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
    final providers = <RepositoryProvider>[
      if (cache != null)
        RepositoryProvider<CoverCacheService>.value(value: cache),
      if (repo != null) RepositoryProvider<BookRepository>.value(value: repo),
    ];
    // Real file and HTTP futures do not complete under the fake clock, so the
    // whole build + resolve cycle runs in the real zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        providers.isEmpty
            ? app
            : MultiRepositoryProvider(providers: providers, child: app),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
  }

  testWidgets('without a cover service it shows the placeholder', (
    tester,
  ) async {
    await pump(
      tester,
      BookCover(book: book(coverUrl: 'https://x/c.png'), width: 40, height: 56),
    );
    expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
  });

  testWidgets('a book without any cover shows the placeholder', (tester) async {
    await pump(tester, BookCover(book: book()), cache: service());
    expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('a stored local file is shown without downloading', (
    tester,
  ) async {
    final cache = service();
    final path = await tester.runAsync(
      () => cache.saveCover('mine', testPng()),
    );

    await pump(
      tester,
      BookCover(
        book: book(coverLocalPath: path, coverUrl: 'https://x/c.png'),
      ),
      cache: cache,
    );

    expect(find.byKey(ValueKey('cover-image:$path')), findsOneWidget);
    expect(find.byKey(const ValueKey('cover-placeholder')), findsNothing);
    expect(requests, 0);
  });

  testWidgets('downloads the remote cover once and remembers the file', (
    tester,
  ) async {
    final repo = _Repo();
    final cache = service();

    await pump(
      tester,
      BookCover(
        book: book(isbn13: '9783000000101', coverUrl: 'https://x/c.png'),
      ),
      cache: cache,
      repo: repo,
    );

    final expected = '${dir.path}/covers/9783000000101.jpg';
    expect(find.byKey(ValueKey('cover-image:$expected')), findsOneWidget);
    expect(requests, 1);
    expect(repo.paths[1], expected, reason: 'persisted on the book');

    // The same book again is served from the cache.
    await pump(
      tester,
      BookCover(
        book: book(isbn13: '9783000000101', coverUrl: 'https://x/c.png'),
      ),
      cache: cache,
      repo: repo,
    );
    expect(requests, 1);
  });

  testWidgets(
    'an imported book (ISBN, no cover URL) asks Open Library by ISBN',
    (tester) async {
      final repo = _Repo();
      await pump(
        tester,
        BookCover(book: book(isbn13: '9783000000105')),
        cache: service(),
        repo: repo,
      );

      expect(
        find.byKey(
          ValueKey('cover-image:${dir.path}/covers/9783000000105.jpg'),
        ),
        findsOneWidget,
      );
      expect(requests, 1);
      expect(repo.paths[1], isNotNull);
    },
  );

  testWidgets('a missing local file falls back to the cover URL', (
    tester,
  ) async {
    await pump(
      tester,
      BookCover(
        book: book(
          isbn13: '9783000000102',
          coverUrl: 'https://x/c.png',
          coverLocalPath: '${dir.path}/gone.jpg',
        ),
      ),
      cache: service(),
      repo: _Repo(),
    );

    expect(
      find.byKey(ValueKey('cover-image:${dir.path}/covers/9783000000102.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('a failing download keeps the placeholder and is not retried', (
    tester,
  ) async {
    failing = true;
    final cache = service();
    final unavailable = book(
      isbn13: '9783000000103',
      coverUrl: 'https://x/c.png',
    );

    await pump(
      tester,
      BookCover(book: unavailable),
      cache: cache,
      repo: _Repo(),
    );
    expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
    expect(requests, 1, reason: 'viewing only asks the stored URL');

    await pump(
      tester,
      BookCover(book: unavailable),
      cache: cache,
      repo: _Repo(),
    );
    expect(requests, 1, reason: 'no request storm while scrolling');
  });

  testWidgets('a corrupt image file degrades to the placeholder', (
    tester,
  ) async {
    final cache = service();
    final path = await tester.runAsync(
      () => cache.saveCover('broken', List.filled(500, 7)),
    );

    await pump(
      tester,
      BookCover(book: book(coverLocalPath: path)),
      cache: cache,
    );

    expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
  });

  testWidgets('UrlCover caches under the given key (scanner staging)', (
    tester,
  ) async {
    final cache = service();

    await pump(
      tester,
      const UrlCover(
        cacheKey: '9783000000104',
        url: 'https://x/c.png',
        width: 32,
        height: 46,
      ),
      cache: cache,
    );

    final expected = '${dir.path}/covers/9783000000104.jpg';
    expect(find.byKey(ValueKey('cover-image:$expected')), findsOneWidget);
    // The book saved later reuses that very file (same ISBN key).
    expect(
      cache.cachedPath(BookCover.keyFor(book(isbn13: '9783000000104'))),
      expected,
    );
  });

  testWidgets('UrlCover without a URL shows the placeholder', (tester) async {
    await pump(
      tester,
      const UrlCover(cacheKey: 'x', url: null),
      cache: service(),
    );
    expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
  });

  test('the cache key is the ISBN-13, else the book id', () {
    expect(BookCover.keyFor(book(isbn13: '9780000000001')), '9780000000001');
    expect(BookCover.keyFor(book(id: 42)), 'book-42');
  });

  testWidgets('a stored DNB fallback URL without a cover tries Open Library', (
    tester,
  ) async {
    final asked = <String>[];
    final cache = CoverCacheService(
      baseDirectory: dir,
      client: MockClient((request) async {
        asked.add(request.url.host);
        return request.url.host == 'portal.dnb.de'
            ? http.Response('', 404)
            : http.Response.bytes(
                testPng(),
                200,
                headers: {'content-type': 'image/png'},
              );
      }),
    );
    const isbn = '9783833874239';

    await pump(
      tester,
      BookCover(
        book: book(isbn13: isbn, coverUrl: dnbCoverUrl(isbn)),
      ),
      cache: cache,
      repo: _Repo(),
    );

    expect(asked, ['portal.dnb.de', 'covers.openlibrary.org']);
    expect(find.byKey(const ValueKey('cover-placeholder')), findsNothing);
  });

  testWidgets('a real stored cover URL is the only one asked', (tester) async {
    final asked = <String>[];
    final cache = CoverCacheService(
      baseDirectory: dir,
      client: MockClient((request) async {
        asked.add(request.url.host);
        return http.Response('', 404);
      }),
    );

    await pump(
      tester,
      BookCover(
        book: book(isbn13: '9783000000999', coverUrl: 'https://x/c.png'),
      ),
      cache: cache,
      repo: _Repo(),
    );

    expect(asked, ['x']);
  });
}
