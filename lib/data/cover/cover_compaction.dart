import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Stored covers fit this box (ADR-0004): sharp in the detail view of a
/// high-density phone, a fraction of a full photo's size.
const coverMaxWidth = 720;
const coverMaxHeight = 1080;
const coverJpegQuality = 82;

/// Images this small that already fit the box are kept as they are:
/// re-encoding them would only lose quality.
const _keepAsIsBytes = 100 * 1024;

/// The bytes to store for a cover: scaled into [coverMaxWidth] ×
/// [coverMaxHeight] (aspect ratio kept) as JPEG q[coverJpegQuality]. Returns
/// `null` when [bytes] are not an image. Pure and synchronous: run it in an
/// isolate, decoding a full-size photo takes long enough to drop frames.
Uint8List? compactCover(Uint8List bytes) {
  final img.Image? image;
  try {
    image = img.decodeImage(bytes);
  } catch (_) {
    // Some decoders throw on truncated data instead of returning null.
    return null;
  }
  if (image == null) return null;

  final fits = image.width <= coverMaxWidth && image.height <= coverMaxHeight;
  if (fits && bytes.length <= _keepAsIsBytes) return bytes;

  final scaled = fits
      ? image
      : image.width * coverMaxHeight > image.height * coverMaxWidth
      ? img.copyResize(image, width: coverMaxWidth)
      : img.copyResize(image, height: coverMaxHeight);
  final encoded = img.encodeJpg(scaled, quality: coverJpegQuality);
  // A heavy image inside the box could, in rare cases, encode larger.
  return fits && encoded.length >= bytes.length ? bytes : encoded;
}
