import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

enum CoverPickSource { gallery, camera }

/// Width kept for a cover; matches what [ImagePickerCoverPicker] asks the
/// platform for.
const _maxCoverWidth = 1200;

/// Lets the user choose a cover image. An interface so screens and tests do not
/// depend on a platform plugin.
abstract class CoverPicker {
  /// The picked image bytes, or `null` when the user cancelled.
  Future<Uint8List?> pick(CoverPickSource source);
}

/// The scanner where the platform has one (Android), the plain picker
/// elsewhere.
CoverPicker platformCoverPicker() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? ScannerCoverPicker(fallback: ImagePickerCoverPicker())
    : ImagePickerCoverPicker();

class ImagePickerCoverPicker implements CoverPicker {
  final ImagePicker _picker;

  ImagePickerCoverPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  Future<Uint8List?> pick(CoverPickSource source) async {
    final file = await _picker.pickImage(
      source: source == CoverPickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxCoverWidth.toDouble(),
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }
}

/// Takes cover photos with the ML Kit document scanner (Android, Google Play
/// services): it finds the cover's edges as a crop suggestion, lets the user
/// drag the corners and straightens a photo taken at an angle. The gallery,
/// and devices without the scanner, use [fallback].
class ScannerCoverPicker implements CoverPicker {
  final CoverPicker _fallback;

  /// Path of the scanned JPEG, or `null` when the user cancelled. Throws when
  /// the scanner is unavailable.
  final Future<String?> Function() _scan;

  ScannerCoverPicker({
    required CoverPicker fallback,
    Future<String?> Function() scan = scanCoverWithMlKit,
  }) : _fallback = fallback,
       _scan = scan;

  @override
  Future<Uint8List?> pick(CoverPickSource source) async {
    if (source != CoverPickSource.camera) return _fallback.pick(source);

    final String? path;
    try {
      path = await _scan();
    } catch (_) {
      // No Play services or scanner module: a plain photo beats no cover.
      return _fallback.pick(source);
    }
    if (path == null) return null;

    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      // Decoding a full-resolution scan takes long enough to drop frames.
      return await Isolate.run(() => shrinkCover(bytes));
    } finally {
      // The scanner leaves its JPEG in the app cache; the cover is kept by the
      // caller, so the photo itself must not pile up.
      try {
        await file.delete();
      } on FileSystemException catch (_) {}
    }
  }
}

/// Opens the ML Kit scanner for a single page. Base mode offers crop and
/// rotate but no colour filters, which would falsify a cover.
Future<String?> scanCoverWithMlKit() async {
  final scanner = DocumentScanner(
    options: DocumentScannerOptions(
      mode: ScannerMode.base,
      pageLimit: 1,
      isGalleryImport: true,
    ),
  );
  try {
    final images = (await scanner.scanDocument()).images;
    return images == null || images.isEmpty ? null : images.first;
  } on PlatformException catch (e) {
    // The plugin reports a closed scanner as an error.
    if (e.message == 'Operation cancelled') return null;
    rethrow;
  } finally {
    await scanner.close();
  }
}

/// Scales [bytes] down to [_maxCoverWidth] as a JPEG. Small images and bytes
/// that are not an image are returned unchanged.
Uint8List shrinkCover(Uint8List bytes) {
  final img.Image? image;
  try {
    image = img.decodeImage(bytes);
  } catch (_) {
    // Some decoders throw on truncated data instead of returning null.
    return bytes;
  }
  if (image == null || image.width <= _maxCoverWidth) return bytes;
  return img.encodeJpg(
    img.copyResize(image, width: _maxCoverWidth),
    quality: 85,
  );
}
