import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
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
  group('coverCandidates', () {
    test('lists the stored URL first, then DNB, then Open Library', () {
      expect(
        coverCandidates(coverUrl: 'https://g/c.jpg', isbn: '9783833874239'),
        [
          'https://g/c.jpg',
          dnbCoverUrl('9783833874239'),
          openLibraryCoverUrl('9783833874239'),
        ],
      );
    });

    test('skips what is missing and never repeats a URL', () {
      expect(coverCandidates(coverUrl: ' ', isbn: null), isEmpty);
      expect(coverCandidates(coverUrl: 'https://g/c.jpg', isbn: null), [
        'https://g/c.jpg',
      ]);
      final dnb = dnbCoverUrl('9783833874239');
      expect(coverCandidates(coverUrl: dnb, isbn: '9783833874239'), [
        dnb,
        openLibraryCoverUrl('9783833874239'),
      ]);
    });

    test('the DNB URL is the public MVB cover service', () {
      expect(
        dnbCoverUrl('9783833874239'),
        'https://portal.dnb.de/opac/mvb/cover?isbn=9783833874239',
      );
    });
  });

  group('resolveAny', () {
    test('a rate-limited source (429) falls through to the next one', () async {
      final requested = <String>[];
      final service = serviceFor((req) async {
        requested.add(req.url.toString());
        return req.url.host == 'google.test'
            ? http.Response('quota', 429)
            : image();
      });

      final path = await service.resolveAny('k', [
        'https://google.test/c.jpg',
        'https://dnb.test/c.jpg',
      ]);

      expect(path, '${dir.path}/covers/k.jpg');
      expect(requested, [
        'https://google.test/c.jpg',
        'https://dnb.test/c.jpg',
      ]);
    });

    test('stops at the first source that delivers', () async {
      final requested = <String>[];
      final service = serviceFor((req) async {
        requested.add(req.url.toString());
        return image();
      });

      await service.resolveAny('k', ['https://a/c.jpg', 'https://b/c.jpg']);

      expect(requested, ['https://a/c.jpg']);
    });

    test('an already cached cover needs no request', () async {
      var calls = 0;
      final service = serviceFor((_) async {
        calls++;
        return image();
      });
      await service.saveCover('k', testPng());

      final path = await service.resolveAny('k', ['https://a/c.jpg']);

      expect(path, '${dir.path}/covers/k.jpg');
      expect(calls, 0);
    });

    test('returns null when every source fails', () async {
      final service = serviceFor((_) async => http.Response('', 404));
      expect(await service.resolveAny('k', ['https://a', 'https://b']), isNull);
      expect(await service.resolveAny('k', const []), isNull);
    });
  });

  group('findAny tells "no cover" from "could not ask" (FR-R2-08)', () {
    Future<CoverFetch> find(List<FutureOr<http.Response> Function()> answers) {
      var i = 0;
      final service = serviceFor((_) async => answers[i++]());
      return service.findAny('k', [
        for (var n = 0; n < answers.length; n++) 'https://s$n/c.jpg',
      ]);
    }

    test('every source answering 404 means no cover online', () async {
      expect(
        await find([
          () => http.Response('', 404),
          () => http.Response('', 404),
        ]),
        isA<CoverMissing>(),
      );
    });

    test('placeholders and non-images count as no cover', () async {
      expect(
        await find([
          () => http.Response.bytes(
            List.filled(43, 1),
            200,
            headers: {'content-type': 'image/gif'},
          ),
          () => http.Response.bytes(
            List.filled(5000, 1),
            200,
            headers: {'content-type': 'text/html'},
          ),
        ]),
        isA<CoverMissing>(),
      );
    });

    test(
      'one source offline, timing out or failing is not "no cover"',
      () async {
        for (final failing in <FutureOr<http.Response> Function()>[
          () => throw const SocketException('offline'),
          () => throw TimeoutException('slow'),
          () => http.Response('quota', 429),
          () => http.Response('down', 503),
        ]) {
          expect(
            await find([() => http.Response('', 404), failing]),
            isA<CoverUnavailable>(),
          );
        }
      },
    );

    test('a delivered image is found and cached', () async {
      final result = await find([() => http.Response('', 404), image]);

      expect(result, isA<CoverFound>());
      expect((result as CoverFound).path, '${dir.path}/covers/k.jpg');
    });

    test('a cached cover is found without asking', () async {
      var calls = 0;
      final service = serviceFor((_) async {
        calls++;
        return image();
      });
      await service.saveCover('k', testPng());

      expect(await service.findAny('k', ['https://a']), isA<CoverFound>());
      expect(calls, 0);
    });
  });

  group('compact storage (ADR-0004)', () {
    test('a large download is stored inside 720×1080', () async {
      final service = serviceFor(
        (_) async => http.Response.bytes(
          img.encodeJpg(img.Image(width: 1600, height: 2400)),
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      );

      final path = await service.downloadAndCache('k', 'https://x/c.jpg');
      final stored = img.decodeImage(File(path!).readAsBytesSync())!;

      expect((stored.width, stored.height), (720, 1080));
    });

    test('a download that is no image counts as no cover', () async {
      final service = serviceFor(
        (_) async => http.Response.bytes(
          List.filled(5000, 7),
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      );

      expect(await service.findAny('k', ['https://x']), isA<CoverMissing>());
      expect(Directory('${dir.path}/covers').existsSync(), isFalse);
    });

    test('saveCover compacts user photos and rejects non-images', () async {
      final service = serviceFor((_) async => http.Response('', 404));

      final path = await service.saveCover(
        'k',
        img.encodeJpg(img.Image(width: 3000, height: 4000)),
      );
      final stored = img.decodeImage(File(path).readAsBytesSync())!;
      expect((stored.width, stored.height), (720, 960), reason: 'width bound');

      expect(
        service.saveCover('x', List.filled(500, 7)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('compactStored shrinks covers saved before ADR-0004', () {
    File put(String name, List<int> bytes) => File('${dir.path}/covers/$name')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    test('large files are compacted in place, the rest stays', () async {
      final service = serviceFor((_) async => http.Response('', 404));
      final large = put(
        'big.jpg',
        img.encodeJpg(img.Image(width: 1600, height: 2400), quality: 100),
      );
      final small = testPng();
      final keep = put('small.jpg', small);
      final junk = put('junk.jpg', List.filled(200 * 1024, 7));

      final compacted = await service.compactStored();

      expect(compacted, 1);
      final stored = img.decodeImage(large.readAsBytesSync())!;
      expect((stored.width, stored.height), (720, 1080), reason: 'same path');
      expect(keep.readAsBytesSync(), small, reason: 'already compact');
      expect(junk.lengthSync(), 200 * 1024, reason: 'never destroys a file');
      expect(
        Directory('${dir.path}/covers').listSync().map((e) => e.path).toSet(),
        {large.path, keep.path, junk.path},
        reason: 'no temp files left behind',
      );
    });

    test('a second run has nothing left to do', () async {
      final service = serviceFor((_) async => http.Response('', 404));
      put(
        'big.jpg',
        img.encodeJpg(img.Image(width: 1600, height: 2400), quality: 100),
      );

      expect(await service.compactStored(), 1);
      expect(await service.compactStored(), 0);
    });

    test('removes temp files of an interrupted run', () async {
      final service = serviceFor((_) async => http.Response('', 404));
      final stale = put('big.jpg.part', [1, 2, 3]);

      await service.compactStored();

      expect(stale.existsSync(), isFalse);
    });

    test('without a covers folder there is nothing to do', () async {
      final service = serviceFor((_) async => http.Response('', 404));
      expect(await service.compactStored(), 0);
    });
  });

  group('deleteAll', () {
    test('removes the covers and the empty folder', () async {
      final service = serviceFor((_) async => image());
      await service.saveCover('a', testPng());
      await service.saveCover('b', testPng());

      await service.deleteAll();

      expect(service.cachedPath('a'), isNull);
      expect(Directory('${dir.path}/covers').existsSync(), isFalse);
    });

    test('never touches files or folders that are not covers', () async {
      // On Linux the base folder is ~/Documents; a user may keep their own
      // "covers" folder there.
      final service = serviceFor((_) async => image());
      await service.saveCover('a', testPng());
      final foreign = File('${dir.path}/covers/notes.txt')
        ..writeAsStringSync('mine');
      final nested = File('${dir.path}/covers/album/front.png')
        ..createSync(recursive: true);

      await service.deleteAll();

      expect(service.cachedPath('a'), isNull, reason: 'our cover is gone');
      expect(foreign.existsSync(), isTrue);
      expect(nested.existsSync(), isTrue);
    });

    test('is a no-op without a covers folder', () async {
      await serviceFor((_) async => image()).deleteAll();
    });
  });
}
