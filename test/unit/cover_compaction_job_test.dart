import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/domain/services/cover_compaction_job.dart';

import '../helpers/fake_settings_repository.dart';

void main() {
  late Directory dir;
  late File cover;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cover_job_test');
    cover = File('${dir.path}/covers/big.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        img.encodeJpg(img.Image(width: 1600, height: 2400), quality: 100),
      );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('compacts the stored covers once and remembers it', () async {
    final settings = FakeSettingsRepository();

    await compactStoredCoversOnce(
      settings,
      CoverCacheService(baseDirectory: dir),
    );

    expect(img.decodeImage(cover.readAsBytesSync())!.width, 720);
    expect(settings.values[coverCompactionKey], '$coverCompactionVersion');
  });

  test('skips the folder once this version has run', () async {
    final settings = FakeSettingsRepository()
      ..values[coverCompactionKey] = '$coverCompactionVersion';
    final before = cover.readAsBytesSync();

    await compactStoredCoversOnce(
      settings,
      CoverCacheService(baseDirectory: dir),
    );

    expect(cover.readAsBytesSync(), before);
  });
}
