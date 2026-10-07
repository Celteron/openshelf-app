import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum CoverPickSource { gallery, camera }

/// Lets the user choose a cover image. An interface so screens and tests do not
/// depend on a platform plugin.
abstract class CoverPicker {
  /// The picked image bytes, or `null` when the user cancelled.
  Future<Uint8List?> pick(CoverPickSource source);
}

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
      maxWidth: 1200,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }
}
