import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/spine_color.dart';

double luminance(int argb) {
  double c(int v) {
    final s = v / 255;
    return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * c((argb >> 16) & 0xff) +
      0.7152 * c((argb >> 8) & 0xff) +
      0.0722 * c(argb & 0xff);
}

double contrast(int a, int b) {
  final la = luminance(a) + 0.05;
  final lb = luminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  coverColorTests();

  test('the placeholder colour of a title never changes', () {
    expect(
      placeholderSpineColor('Der Vorleser'),
      placeholderSpineColor('Der Vorleser'),
    );
    expect(
      placeholderSpineColor('Der Vorleser'),
      isNot(placeholderSpineColor('Die Blechtrommel')),
    );
  });

  test('placeholder colours are opaque and not near white or black', () {
    for (final title in [
      '',
      'A',
      'Der Vorleser',
      'Ein sehr langer Titel mit Umlauten äöü ß',
    ]) {
      final c = placeholderSpineColor(title);
      expect(c >> 24, 0xff);
      expect(luminance(c), inInclusiveRange(0.03, 0.55), reason: title);
    }
  });

  test('text on a spine always reads: contrast of at least 4.5', () {
    for (final title in List.generate(80, (i) => 'Buch $i')) {
      final bg = placeholderSpineColor(title);
      expect(
        contrast(bg, onSpineColor(bg)),
        greaterThanOrEqualTo(4.5),
        reason: title,
      );
    }
    for (final bg in [
      0xFFFFFFFF,
      0xFF000000,
      0xFF808080,
      0xFFFFD54F,
      0xFF1A237E,
    ]) {
      expect(
        contrast(bg, onSpineColor(bg)),
        greaterThanOrEqualTo(4.5),
        reason: '$bg',
      );
    }
  });
}

Uint8List solid(int w, int h, int r, int g, int b) {
  final out = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    out[i * 4] = r;
    out[i * 4 + 1] = g;
    out[i * 4 + 2] = b;
    out[i * 4 + 3] = 255;
  }
  return out;
}

void coverColorTests() {
  group('colour from a cover', () {
    test('a plain cover gives its colour', () {
      expect(spineColorFromRgba(solid(4, 4, 200, 30, 40), 4, 4), 0xFFC81E28);
    });

    test('a white cover with a blue block gives the blue', () {
      final rgba = solid(10, 10, 255, 255, 255);
      for (var i = 0; i < 30; i++) {
        rgba[i * 4] = 20;
        rgba[i * 4 + 1] = 60;
        rgba[i * 4 + 2] = 200;
      }
      final color = spineColorFromRgba(rgba, 10, 10)!;

      expect((color >> 16) & 0xff, lessThan(60));
      expect(color & 0xff, greaterThan(150));
    });

    test('a vivid area beats a larger dull one', () {
      final rgba = solid(10, 10, 120, 118, 119);
      for (var i = 0; i < 40; i++) {
        rgba[i * 4] = 230;
        rgba[i * 4 + 1] = 40;
        rgba[i * 4 + 2] = 40;
      }
      final color = spineColorFromRgba(rgba, 10, 10)!;

      expect((color >> 16) & 0xff, greaterThan(200));
    });

    test('only white, only black or nothing gives no colour', () {
      expect(spineColorFromRgba(solid(4, 4, 255, 255, 255), 4, 4), isNull);
      expect(spineColorFromRgba(solid(4, 4, 0, 0, 0), 4, 4), isNull);
      expect(spineColorFromRgba(Uint8List(0), 0, 0), isNull);
    });

    test('transparent pixels are ignored', () {
      final rgba = solid(2, 2, 200, 30, 40);
      for (var i = 0; i < 4; i++) {
        rgba[i * 4 + 3] = 0;
      }
      expect(spineColorFromRgba(rgba, 2, 2), isNull);
    });
  });
}
