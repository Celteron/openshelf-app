import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openreads/data/ocr/photo_picker.dart';

class _Picker extends ImagePicker {
  final XFile? file;
  _Picker(this.file);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => file;
}

void main() {
  late Directory cache;
  late Directory elsewhere;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('cache');
    elsewhere = Directory.systemTemp.createTempSync('pictures');
  });

  tearDown(() {
    cache.deleteSync(recursive: true);
    elsewhere.deleteSync(recursive: true);
  });

  ImagePickerTextPhotoPicker picker(File? file) => ImagePickerTextPhotoPicker(
    picker: _Picker(file == null ? null : XFile(file.path)),
    cacheDirectory: () async => cache,
  );

  test('returns the bytes and removes the copy from the app cache', () async {
    final photo = File('${cache.path}/IMG_1.jpg')..writeAsBytesSync([1, 2, 3]);

    final bytes = await picker(photo).pick(PhotoSource.camera);

    expect(bytes, [1, 2, 3]);
    expect(photo.existsSync(), isFalse, reason: 'the page photo is not kept');
  });

  test('never deletes a file the user owns outside the app cache', () async {
    final photo = File('${elsewhere.path}/mine.jpg')..writeAsBytesSync([9]);

    final bytes = await picker(photo).pick(PhotoSource.gallery);

    expect(bytes, [9]);
    expect(photo.existsSync(), isTrue);
  });

  test('cancelling gives null', () async {
    expect(await picker(null).pick(PhotoSource.camera), isNull);
  });
}
