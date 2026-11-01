import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openreads/data/cover/cover_picker.dart';

Uint8List jpeg(int width, int height) =>
    img.encodeJpg(img.Image(width: width, height: height));

class _Fallback implements CoverPicker {
  final requested = <CoverPickSource>[];
  final Uint8List result = Uint8List.fromList([1, 2, 3]);

  @override
  Future<Uint8List?> pick(CoverPickSource source) async {
    requested.add(source);
    return result;
  }
}

void main() {
  group('shrinkCover', () {
    test('scales a wide photo down to 1200 px, keeping the aspect', () {
      final out = img.decodeImage(shrinkCover(jpeg(2400, 3600)))!;

      expect(out.width, 1200);
      expect(out.height, 1800);
    });

    test('leaves a small image untouched', () {
      final small = jpeg(600, 900);

      expect(shrinkCover(small), same(small));
    });

    test('passes bytes it cannot decode through unchanged', () {
      final junk = Uint8List.fromList([0, 1, 2, 3]);

      expect(shrinkCover(junk), same(junk));
    });
  });

  group('ScannerCoverPicker', () {
    late Directory dir;
    late _Fallback fallback;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('cover_picker_test');
      fallback = _Fallback();
    });
    tearDown(() => dir.deleteSync(recursive: true));

    String scanned(Uint8List bytes) {
      final file = File('${dir.path}/scan.jpg')..writeAsBytesSync(bytes);
      return file.path;
    }

    test(
      'the camera goes through the scanner and shrinks the result',
      () async {
        final path = scanned(jpeg(2400, 3600));
        final picker = ScannerCoverPicker(
          fallback: fallback,
          scan: () async => path,
        );

        final bytes = await picker.pick(CoverPickSource.camera);

        expect(img.decodeImage(bytes!)!.width, 1200);
        expect(fallback.requested, isEmpty);
        expect(File(path).existsSync(), isFalse, reason: 'scan cleaned up');
      },
    );

    test('a cancelled scan picks nothing and opens no camera', () async {
      final picker = ScannerCoverPicker(
        fallback: fallback,
        scan: () async => null,
      );

      expect(await picker.pick(CoverPickSource.camera), isNull);
      expect(fallback.requested, isEmpty);
    });

    test('without a working scanner the plain camera is used', () async {
      final picker = ScannerCoverPicker(
        fallback: fallback,
        scan: () async => throw Exception('no Google Play services'),
      );

      expect(await picker.pick(CoverPickSource.camera), fallback.result);
      expect(fallback.requested, [CoverPickSource.camera]);
    });

    test('the gallery keeps using the plain picker', () async {
      var scans = 0;
      final picker = ScannerCoverPicker(
        fallback: fallback,
        scan: () async {
          scans++;
          return null;
        },
      );

      expect(await picker.pick(CoverPickSource.gallery), fallback.result);
      expect(scans, 0);
      expect(fallback.requested, [CoverPickSource.gallery]);
    });
  });

  group('scanCoverWithMlKit', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('google_mlkit_document_scanner');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    void answer(Object? Function() start) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'vision#closeDocumentScanner') return null;
        return start();
      });
    }

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('returns the scanned image', () async {
      answer(
        () => {
          'images': ['/cache/scan.jpg'],
          'pdf': null,
        },
      );

      expect(await scanCoverWithMlKit(), '/cache/scan.jpg');
    });

    test('a closed scanner is a cancel, not an error', () async {
      answer(
        () => throw PlatformException(
          code: 'DocumentScanner',
          message: 'Operation cancelled',
        ),
      );

      expect(await scanCoverWithMlKit(), isNull);
    });

    test('a scanner that cannot start is an error', () async {
      answer(
        () => throw PlatformException(
          code: 'DocumentScanner',
          message: 'Failed to start document scanner',
        ),
      );

      expect(scanCoverWithMlKit(), throwsA(isA<PlatformException>()));
    });

    test('a result without images picks nothing', () async {
      answer(() => {'images': null, 'pdf': null});

      expect(await scanCoverWithMlKit(), isNull);
    });
  });
}
