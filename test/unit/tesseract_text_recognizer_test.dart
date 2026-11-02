import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/ocr/tesseract_text_recognizer.dart';

class _Bundle extends CachingAssetBundle {
  final loads = <String>[];

  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    return ByteData.sublistView(Uint8List.fromList(key.codeUnits));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('de.openshelf.app/ocr');
  late Directory dir;
  late _Bundle bundle;
  late List<MethodCall> calls;
  late Object? Function(MethodCall) answer;
  late bool imageExistedDuringCall;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ocr_test');
    bundle = _Bundle();
    calls = [];
    imageExistedDuringCall = false;
    answer = (_) => 'Text';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final path = (call.arguments as Map)['imagePath'] as String;
          imageExistedDuringCall = File(path).existsSync();
          return answer(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    dir.deleteSync(recursive: true);
  });

  TesseractTextRecognizer recognizer() => TesseractTextRecognizer(
    channel: channel,
    bundle: bundle,
    workDirectory: () async => dir,
  );

  test(
    'copies the language data once and asks for German and English',
    () async {
      final r = recognizer();

      final text = await r.recognize(Uint8List.fromList([1, 2, 3]));

      expect(text, 'Text');
      expect(File('${dir.path}/tessdata/deu.traineddata').existsSync(), isTrue);
      expect(File('${dir.path}/tessdata/eng.traineddata').existsSync(), isTrue);
      final args = calls.single.arguments as Map;
      expect(calls.single.method, 'recognize');
      expect(args['dataPath'], dir.path);
      expect(args['language'], 'deu+eng');

      await r.recognize(Uint8List.fromList([4]));
      expect(bundle.loads, hasLength(2), reason: 'not copied again');
    },
  );

  test('the photo only exists while it is read, then it is deleted', () async {
    await recognizer().recognize(Uint8List.fromList([1]));

    expect(imageExistedDuringCall, isTrue);
    final leftovers = dir.listSync().whereType<File>().where(
      (f) => f.path.contains('ocr-input'),
    );
    expect(leftovers, isEmpty);
  });

  test('the recognised text is tidied for a quote', () async {
    answer = (_) => 'Ein Bei-\nspiel.\n';

    expect(await recognizer().recognize(Uint8List(1)), 'Ein Beispiel.');
  });

  test('nothing recognised is null, not an empty string', () async {
    answer = (_) => '  \n';

    expect(await recognizer().recognize(Uint8List(1)), isNull);
  });

  test('a native failure becomes a TextRecognitionException', () async {
    answer = (_) => throw PlatformException(code: 'init', message: 'no data');

    await expectLater(
      recognizer().recognize(Uint8List(1)),
      throwsA(isA<TextRecognitionException>()),
    );
    expect(File('${dir.path}/ocr-input.jpg').existsSync(), isFalse);
  });
}
