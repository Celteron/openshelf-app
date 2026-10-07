import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A small valid PNG that is larger than the cover cache's "placeholder"
/// threshold (it is noisy, so it does not compress to a few bytes).
Uint8List testPng({int size = 24, int seed = 1}) {
  final image = img.Image(width: size, height: size);
  var value = seed;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      value = (value * 1103515245 + 12345) & 0x7fffffff;
      image.setPixelRgb(
        x,
        y,
        value & 255,
        (value >> 8) & 255,
        (value >> 16) & 255,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
