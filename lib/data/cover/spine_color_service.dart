import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:openreads/domain/models/spine_color.dart';

/// Decoded pixels of a small version of an image.
typedef DecodedPixels = ({Uint8List rgba, int width, int height});

/// Turns image file bytes into a small RGBA bitmap; `null` when they are not
/// an image. Injected so the service is testable without the engine.
typedef PixelDecoder = Future<DecodedPixels?> Function(Uint8List bytes);

/// The engine shrinks while it decodes, off the UI thread, which is far
/// cheaper than decoding a full cover in Dart.
Future<DecodedPixels?> engineDecode(Uint8List bytes) async {
  ui.Codec? codec;
  try {
    codec = await ui.instantiateImageCodec(bytes, targetWidth: 12);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (data == null) return null;
    return (
      rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      width: frame.image.width,
      height: frame.image.height,
    );
  } catch (_) {
    return null;
  } finally {
    codec?.dispose();
  }
}

/// The colour of a cover file for its spine on the shelf wall.
///
/// Derived data, so it is kept in memory only (FR-R2-10): a few thousand
/// small ints, rebuilt lazily as spines come into view. The key includes the
/// file's modification time, because replacing a cover keeps its path.
class SpineColorService {
  static const _maxConcurrent = 2;

  final PixelDecoder _decode;
  final int _capacity;
  final LinkedHashMap<String, int?> _cache = LinkedHashMap();
  final _inFlight = <String, Future<int?>>{};
  final _waiting = Queue<Completer<void>>();
  var _running = 0;

  SpineColorService({PixelDecoder decode = engineDecode, int capacity = 4000})
    : _decode = decode,
      _capacity = capacity;

  /// The cover's colour, or `null` when it has none (missing file, plain
  /// white, not an image).
  Future<int?> colorFor(String path) async {
    final DateTime modified;
    try {
      modified = File(path).lastModifiedSync();
    } on FileSystemException {
      return null;
    }
    final key = '$path|${modified.microsecondsSinceEpoch}';
    if (_cache.containsKey(key)) {
      final hit = _cache.remove(key); // re-insert: most recently used
      _cache[key] = hit;
      return hit;
    }
    // A block body: `remove` returns the very future whenComplete would
    // otherwise wait for (the future would wait on itself).
    return _inFlight[key] ??= _compute(path, key).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<int?> _compute(String path, String key) async {
    await _acquire();
    int? color;
    try {
      final pixels = await _decode(await File(path).readAsBytes());
      if (pixels != null) {
        color = spineColorFromRgba(pixels.rgba, pixels.width, pixels.height);
      }
    } catch (_) {
      color = null; // a broken cover just has no colour
    } finally {
      _release();
    }
    _cache[key] = color;
    while (_cache.length > _capacity) {
      _cache.remove(_cache.keys.first);
    }
    return color;
  }

  Future<void> _acquire() async {
    if (_running < _maxConcurrent) {
      _running++;
      return;
    }
    final turn = Completer<void>();
    _waiting.add(turn);
    await turn.future; // the releasing job hands its slot over
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
    } else {
      _running--;
    }
  }
}
