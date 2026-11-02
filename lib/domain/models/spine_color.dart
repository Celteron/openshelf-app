/// Colours of book spines. Pure ints (ARGB), no Flutter types, so the layout
/// and its tests stay free of the UI (Constitution IV).
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// A stable colour for a book without a cover: the same title always gets the
/// same hue. FNV-1a, because `String.hashCode` is not stable between runs.
int placeholderSpineColor(String title) {
  var hash = 0x811c9dc5;
  for (final unit in title.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return _hsl((hash % 360).toDouble(), 0.45, 0.40);
}

/// Black or white, whichever reads better on [background] (WCAG contrast of
/// at least 4.5 either way, since the mid-luminance worst case is 4.58).
int onSpineColor(int background) {
  final l = _luminance(background);
  final white = 1.05 / (l + 0.05);
  final black = (l + 0.05) / 0.05;
  return white >= black ? 0xFFFFFFFF : 0xFF000000;
}

double _luminance(int argb) {
  double channel(int v) {
    final s = v / 255;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel((argb >> 16) & 0xff) +
      0.7152 * channel((argb >> 8) & 0xff) +
      0.0722 * channel(argb & 0xff);
}

int _hsl(double hue, double saturation, double lightness) {
  final c = (1 - (2 * lightness - 1).abs()) * saturation;
  final x = c * (1 - ((hue / 60) % 2 - 1).abs());
  final m = lightness - c / 2;
  final (r, g, b) = switch (hue ~/ 60) {
    0 => (c, x, 0.0),
    1 => (x, c, 0.0),
    2 => (0.0, c, x),
    3 => (0.0, x, c),
    4 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  int to8(double v) => ((v + m) * 255).round().clamp(0, 255);
  return 0xFF000000 | (to8(r) << 16) | (to8(g) << 8) | to8(b);
}

/// The colour a cover is best remembered by, from its RGBA pixels (a few
/// dozen are enough, the caller shrinks the image).
///
/// Pixels are sorted into a coarse colour histogram. Each counts by its
/// chroma, so a small vivid title beats a large grey area, and near-white
/// and near-black pixels (paper, frames) and transparent ones are skipped.
/// `null` when nothing is left, e.g. a plain white cover: the caller falls
/// back to the placeholder colour.
int? spineColorFromRgba(Uint8List rgba, int width, int height) {
  final pixels = math.min(width * height, rgba.length ~/ 4);
  final weight = <int, double>{};
  final red = <int, double>{};
  final green = <int, double>{};
  final blue = <int, double>{};
  for (var i = 0; i < pixels; i++) {
    final r = rgba[i * 4];
    final g = rgba[i * 4 + 1];
    final b = rgba[i * 4 + 2];
    if (rgba[i * 4 + 3] < 128) continue;
    final high = math.max(r, math.max(g, b));
    final low = math.min(r, math.min(g, b));
    if (low > 235 || high < 25) continue;
    final w = 0.1 + (high - low) / 255;
    final bin = ((r >> 5) << 6) | ((g >> 5) << 3) | (b >> 5);
    weight[bin] = (weight[bin] ?? 0) + w;
    red[bin] = (red[bin] ?? 0) + r * w;
    green[bin] = (green[bin] ?? 0) + g * w;
    blue[bin] = (blue[bin] ?? 0) + b * w;
  }
  if (weight.isEmpty) return null;
  final best = weight.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  final total = weight[best]!;
  return 0xFF000000 |
      ((red[best]! / total).round() << 16) |
      ((green[best]! / total).round() << 8) |
      (blue[best]! / total).round();
}
