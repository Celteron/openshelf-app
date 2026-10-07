import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';

import '../helpers/test_images.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('covers_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  CoverCacheService serviceFor(
    Future<http.Response> Function(http.Request) handler,
  ) => CoverCacheService(client: MockClient(handler), baseDirectory: dir);

  http.Response image([int seed = 1]) => http.Response.bytes(
    testPng(seed: seed),
    200,
    headers: {'content-type': 'image/jpeg'},
  );

  group('downloadAndCache', () {
    test(
      'stores the image under covers/<key>.jpg and returns the path',
      () async {
        final service = serviceFor((_) async => image());

        final path = await service.downloadAndCache(
          '9783442719255',
          'https://x/c.jpg',
        );

        expect(path, '${dir.path}/covers/9783442719255.jpg');
        expect(File(path!).existsSync(), isTrue);
        expect(File(path).readAsBytesSync(), testPng());
      },
    );

    test('rejects HTTP errors, tiny placeholders and non-images', () async {
      Future<String?> fetch(http.Response response) => serviceFor(
        (_) async => response,
      ).downloadAndCache('k', 'https://x/c.jpg');

      expect(await fetch(http.Response('nope', 404)), isNull);
      expect(
        await fetch(
          http.Response.bytes(
            List.filled(43, 1),
            200,
            headers: {'content-type': 'image/gif'},
          ),
        ),
        isNull,
        reason: 'the 1×1 "no cover" gif some hosts return',
      );
      expect(
        await fetch(
          http.Response.bytes(
            List.filled(5000, 1),
            200,
            headers: {'content-type': 'text/html'},
          ),
        ),
        isNull,
        reason: 'an HTML error page is not a cover',
      );
      expect(Directory('${dir.path}/covers').existsSync(), isFalse);
    });

    test('returns null when the request fails', () async {
      final service = serviceFor(
        (_) async => throw const SocketException('offline'),
      );
      expect(await service.downloadAndCache('k', 'https://x/c.jpg'), isNull);
    });

    test('a new download replaces the cached file', () async {
      var seed = 1;
      final service = serviceFor((_) async => image(seed++));

      await service.downloadAndCache('k', 'https://x/c.jpg');
      final path = await service.downloadAndCache('k', 'https://x/c.jpg');

      expect(File(path!).readAsBytesSync(), testPng(seed: 2));
    });
  });

  group('resolve', () {
    test('serves a cached file without touching the network', () async {
      var calls = 0;
      final service = serviceFor((_) async {
        calls++;
        return image();
      });
      await service.downloadAndCache('k', 'https://x/c.jpg');
      expect(calls, 1);

      final path = await service.resolve('k', 'https://x/other.jpg');

      expect(path, service.cachedPath('k'));
      expect(calls, 1);
    });

    test('downloads when nothing is cached yet', () async {
      final service = serviceFor((_) async => image());
      expect(service.cachedPath('k'), isNull);

      final path = await service.resolve('k', 'https://x/c.jpg');

      expect(path, isNotNull);
      expect(service.cachedPath('k'), path);
    });

    test('without cache and URL there is nothing to resolve', () async {
      final service = serviceFor((_) async => image());
      expect(await service.resolve('k', null), isNull);
      expect(await service.resolve('k', '  '), isNull);
    });
  });

  group('manual covers and housekeeping', () {
    test('saveCover stores user bytes', () async {
      final service = serviceFor((_) async => image());
      final path = await service.saveCover('manual-1', testPng(seed: 9));
      expect(File(path).readAsBytesSync(), testPng(seed: 9));
      expect(service.exists(path), isTrue);
    });

    test('keys cannot escape the covers directory', () async {
      final service = serviceFor((_) async => image());
      final path = await service.saveCover('../../evil', testPng());
      expect(path.startsWith('${dir.path}/covers/'), isTrue);
      expect(
        path.substring('${dir.path}/covers/'.length),
        isNot(contains('/')),
      );
    });

    test('deleteFile removes the file and ignores missing ones', () async {
      final service = serviceFor((_) async => image());
      final path = await service.saveCover('x', testPng());

      await service.deleteFile(path);
      expect(service.exists(path), isFalse);

      await service.deleteFile(path);
      await service.deleteFile(null);
    });

    test('exists is false for null and missing paths', () {
      final service = serviceFor((_) async => image());
      expect(service.exists(null), isFalse);
      expect(service.exists('${dir.path}/nope.jpg'), isFalse);
    });
  });

  test('at most four downloads run at the same time', () async {
    var active = 0;
    var peak = 0;
    final gates = <Completer<void>>[];
    final service = serviceFor((_) async {
      active++;
      if (active > peak) peak = active;
      final gate = Completer<void>();
      gates.add(gate);
      await gate.future;
      active--;
      return image();
    });

    final downloads = [
      for (var i = 0; i < 10; i++)
        service.downloadAndCache('k$i', 'https://x/$i.jpg'),
    ];

    // Let every request that may start, start.
    await pumpEventQueue();
    expect(active, 4, reason: 'only four slots');

    // Release them one by one; the waiting ones take over each freed slot.
    var released = 0;
    while (released < 10) {
      await pumpEventQueue();
      gates[released++].complete();
    }
    final paths = await Future.wait(downloads);

    expect(peak, 4);
    expect(paths.whereType<String>(), hasLength(10));
  });
}
