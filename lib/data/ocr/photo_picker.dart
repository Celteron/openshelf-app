import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum PhotoSource { camera, gallery }

/// Lets the user take or choose a photo of text. Separate from the cover
/// picker: text needs far more resolution than a cover thumbnail.
abstract class TextPhotoPicker {
  /// The image bytes, or `null` when the user cancelled.
  Future<Uint8List?> pick(PhotoSource source);
}

class ImagePickerTextPhotoPicker implements TextPhotoPicker {
  /// Long enough to read small print, small enough for the OCR to be quick.
  static const maxSide = 2400.0;

  final ImagePicker _picker;
  final Future<Directory> Function() _cacheDirectory;

  ImagePickerTextPhotoPicker({
    ImagePicker? picker,
    Future<Directory> Function()? cacheDirectory,
  }) : _picker = picker ?? ImagePicker(),
       _cacheDirectory = cacheDirectory ?? getTemporaryDirectory;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 92,
    );
    if (file == null) return null;
    try {
      return await file.readAsBytes();
    } finally {
      await _forget(file.path);
    }
  }

  /// The picker leaves a copy of every photo in the app cache. The page of a
  /// book is not kept past its recognition (FR-06-13), but a file outside the
  /// cache is the user's own and stays.
  Future<void> _forget(String path) async {
    try {
      final cache = (await _cacheDirectory()).path;
      if (path.startsWith(cache)) await File(path).delete();
    } on FileSystemException {
      // Already gone, or not ours to delete: nothing to do.
    }
  }
}
