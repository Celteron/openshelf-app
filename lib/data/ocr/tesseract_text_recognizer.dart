import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:openreads/domain/services/ocr_text.dart';
import 'package:openreads/domain/services/text_recognizer.dart';

export 'package:openreads/domain/services/text_recognizer.dart'
    show TextRecognitionException;

/// Offline OCR with Tesseract (Apache-2.0) through a small Android channel.
/// The language models ship with the app (`assets/tessdata`, the "fast"
/// variants), so reading a photo never touches the network.
class TesseractTextRecognizer implements TextRecognizer {
  static const channelName = 'de.openshelf.app/ocr';

  /// German first: the app's market. English for the rest of the shelf.
  static const languages = ['deu', 'eng'];

  final MethodChannel _channel;
  final AssetBundle _bundle;
  final Future<Directory> Function() _workDirectory;
  Future<void>? _dataReady;

  TesseractTextRecognizer({
    required Future<Directory> Function() workDirectory,
    MethodChannel channel = const MethodChannel(channelName),
    AssetBundle? bundle,
  }) : _channel = channel,
       _bundle = bundle ?? rootBundle,
       _workDirectory = workDirectory;

  @override
  Future<String?> recognize(Uint8List image) async {
    final dir = await _workDirectory();
    try {
      await (_dataReady ??= _copyLanguageData(dir));
    } catch (e) {
      _dataReady = null; // try again next time
      throw TextRecognitionException('language data: $e');
    }

    // The photo only lives for the length of the recognition.
    final file = File('${dir.path}/ocr-input.jpg');
    try {
      await file.writeAsBytes(await Isolate.run(() => _upright(image)));
      final raw = await _channel.invokeMethod<String>('recognize', {
        'imagePath': file.path,
        'dataPath': dir.path,
        'language': languages.join('+'),
      });
      final text = cleanRecognizedText(raw ?? '');
      return text.isEmpty ? null : text;
    } on PlatformException catch (e) {
      throw TextRecognitionException(e.message ?? e.code);
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }

  /// Tesseract wants `<dataPath>/tessdata/<lang>.traineddata` on disk.
  Future<void> _copyLanguageData(Directory dir) async {
    final target = Directory('${dir.path}/tessdata')
      ..createSync(recursive: true);
    for (final lang in languages) {
      final data = await _bundle.load('assets/tessdata/$lang.traineddata');
      final file = File('${target.path}/$lang.traineddata');
      // A model that changed with an app update has another size.
      if (!file.existsSync() || file.lengthSync() != data.lengthInBytes) {
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
    }
  }

  /// Photos come with an EXIF rotation that Tesseract's reader ignores: turn
  /// the pixels upright. Bytes that are not an image pass through unchanged.
  static Uint8List _upright(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      return Uint8List.fromList(
        img.encodeJpg(img.bakeOrientation(decoded), quality: 92),
      );
    } catch (_) {
      // Undecodable data (the decoder may throw instead of returning null):
      // let Tesseract try the original.
      return bytes;
    }
  }
}
