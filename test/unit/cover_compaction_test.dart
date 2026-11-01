import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openreads/data/cover/cover_compaction.dart';

import '../helpers/test_images.dart';

Uint8List jpeg(int width, int height) =>
    img.encodeJpg(img.Image(width: width, height: height));

/// Every stored cover fits 720×1080 as JPEG q82 (ADR-0004, FR-R2-10).
void main() {
  test('a large photo is scaled into the box and gets smaller', () {
    final big = jpeg(2400, 3600);
    final out = compactCover(big)!;
    final image = img.decodeImage(out)!;

    expect((image.width, image.height), (720, 1080));
    expect(out.length, lessThan(big.length));
  });

  test('a wide cover (slipcase) keeps its aspect ratio', () {
    final image = img.decodeImage(compactCover(jpeg(2000, 1000))!)!;
    expect((image.width, image.height), (720, 360));
  });

  test('a small image is kept byte for byte (no generation loss)', () {
    final small = testPng();
    expect(compactCover(small), same(small));
  });

  test('a heavy image inside the box is re-encoded as JPEG', () {
    final heavy = testPng(size: 600);
    expect(heavy.length, greaterThan(100 * 1024));

    final out = compactCover(heavy)!;

    expect(out.length, lessThan(heavy.length));
    expect(img.JpegDecoder().isValidFile(out), isTrue);
    expect(img.decodeImage(out)!.width, 600, reason: 'no needless resize');
  });

  test('bytes that are no image are rejected', () {
    expect(compactCover(Uint8List.fromList(List.filled(500, 7))), isNull);
    expect(compactCover(Uint8List(0)), isNull);
  });
}
