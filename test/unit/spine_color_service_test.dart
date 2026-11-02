import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/cover/spine_color_service.dart';

void main() {
  late Directory dir;
  late File cover;
  var decodes = 0;
  var running = 0;
  var maxRunning = 0;
  Duration delay = Duration.zero;

  Future<DecodedPixels?> decoder(Uint8List bytes) async {
    decodes++;
    running++;
    if (running > maxRunning) maxRunning = running;
    await Future<void>.delayed(delay);
    running--;
    if (bytes.isEmpty) return null;
    return (rgba: Uint8List.fromList([200, 30, 40, 255]), width: 1, height: 1);
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('spine_color');
    cover = File('${dir.path}/c.jpg')..writeAsBytesSync([1, 2, 3]);
    decodes = 0;
    running = 0;
    maxRunning = 0;
    delay = Duration.zero;
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('reads the colour of a cover file', () async {
    final service = SpineColorService(decode: decoder);

    expect(await service.colorFor(cover.path), 0xFFC81E28);
  });

  test('a second ask is answered from memory', () async {
    final service = SpineColorService(decode: decoder);

    await service.colorFor(cover.path);
    await service.colorFor(cover.path);

    expect(decodes, 1);
  });

  test('asks at the same time share one decode', () async {
    delay = const Duration(milliseconds: 20);
    final service = SpineColorService(decode: decoder);

    await Future.wait([
      service.colorFor(cover.path),
      service.colorFor(cover.path),
    ]);

    expect(decodes, 1);
  });

  test('a replaced cover file is read again', () async {
    final service = SpineColorService(decode: decoder);
    await service.colorFor(cover.path);

    cover
      ..writeAsBytesSync([9, 9])
      ..setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
    await service.colorFor(cover.path);

    expect(decodes, 2);
  });

  test('a missing file or one that cannot be decoded has no colour', () async {
    final service = SpineColorService(decode: decoder);

    expect(await service.colorFor('${dir.path}/gone.jpg'), isNull);
    final empty = File('${dir.path}/empty.jpg')..writeAsBytesSync([]);
    expect(await service.colorFor(empty.path), isNull);
  });

  test(
    'a decoder that throws has no colour and does not stop the service',
    () async {
      final service = SpineColorService(
        decode: (_) async => throw StateError('codec'),
      );

      expect(await service.colorFor(cover.path), isNull);
    },
  );

  test('at most two decodes run at once', () async {
    delay = const Duration(milliseconds: 20);
    final service = SpineColorService(decode: decoder);
    final files = [
      for (var i = 0; i < 6; i++)
        File('${dir.path}/c$i.jpg')..writeAsBytesSync([i + 1]),
    ];

    await Future.wait([for (final f in files) service.colorFor(f.path)]);

    expect(decodes, 6);
    expect(maxRunning, lessThanOrEqualTo(2));
  });

  test('the cache forgets the oldest entries past its capacity', () async {
    final service = SpineColorService(decode: decoder, capacity: 2);
    final files = [
      for (var i = 0; i < 3; i++)
        File('${dir.path}/c$i.jpg')..writeAsBytesSync([i + 1]),
    ];
    for (final f in files) {
      await service.colorFor(f.path);
    }
    decodes = 0;

    await service.colorFor(files.last.path);
    expect(decodes, 0, reason: 'newest is kept');
    await service.colorFor(files.first.path);
    expect(decodes, 1, reason: 'oldest was dropped');
  });
}
