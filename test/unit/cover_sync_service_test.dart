import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/services/cover_sync_service.dart';

import '../helpers/test_images.dart';

class _Repo implements BookRepository {
  final List<Book> books;
  final paths = <int, String?>{};
  _Repo(this.books);

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  Future<void> setCoverLocalPath(int id, String? path) async =>
      paths[id] = path;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book book(int id, {String? isbn13, String? url, String? local}) => Book(
  id: id,
  title: 'B$id',
  authors: const ['A'],
  status: BookStatus.unread,
  rating: 0,
  isbn13: isbn13,
  coverUrl: url,
  coverLocalPath: local,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('cover_sync_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  CoverCacheService cache(Set<String> failingUrls) => CoverCacheService(
    baseDirectory: dir,
    client: MockClient(
      (req) async => failingUrls.contains(req.url.toString())
          ? http.Response('x', 404)
          : http.Response.bytes(
              testPng(),
              200,
              headers: {'content-type': 'image/png'},
            ),
    ),
  );

  test(
    'downloads only covers that are known by URL but missing locally',
    () async {
      final covers = cache({'https://x/fail.jpg'});
      final existing = await covers.saveCover('present', testPng());
      final repo = _Repo([
        book(1, isbn13: '9783000000201', url: 'https://x/a.jpg'), // missing
        book(2, url: 'https://x/b.jpg'), // missing, keyed by id
        book(
          3,
          isbn13: '9783000000203',
          url: 'https://x/c.jpg',
          local: existing,
        ),
        book(4, isbn13: '9783000000204'), // no URL: Open Library by ISBN
        book(5, isbn13: '9783000000205', url: 'https://x/fail.jpg'), // 404
        book(
          6,
          isbn13: '9783000000206',
          url: 'https://x/d.jpg',
          local: '/gone.jpg',
        ),
      ]);
      final progress = <(int, int)>[];

      final result = await CoverSyncService(repo, covers).downloadMissing(
        onProgress: (done, total) => progress.add((done, total)),
      );

      expect(result.total, 5);
      expect(result.downloaded, 4);
      expect(result.failed, 1);
      expect(repo.paths.keys, unorderedEquals([1, 2, 4, 6]));
      expect(repo.paths[1], '${dir.path}/covers/9783000000201.jpg');
      expect(repo.paths[2], '${dir.path}/covers/book-2.jpg');
      expect(progress.last, (5, 5));
    },
  );

  test('nothing missing is a quick no-op', () async {
    final repo = _Repo([book(1), book(2)]);

    final result = await CoverSyncService(repo, cache({})).downloadMissing();

    expect((result.total, result.downloaded, result.failed), (0, 0, 0));
    expect(repo.paths, isEmpty);
  });
}
