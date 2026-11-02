import 'dart:typed_data';

/// Reads the text of a photo, on the device. An interface so the engine can
/// be swapped (Tesseract today) and screens do not depend on a plugin.
abstract class TextRecognizer {
  /// The recognised text, or `null` when the photo holds none. Throws
  /// [TextRecognitionException] when the engine itself fails.
  Future<String?> recognize(Uint8List image);
}

class TextRecognitionException implements Exception {
  final String message;
  TextRecognitionException(this.message);

  @override
  String toString() => 'TextRecognitionException: $message';
}
