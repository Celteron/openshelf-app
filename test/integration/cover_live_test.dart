@Tags(['live-network'])
library;

import 'dart:io';

import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:test/test.dart';

/// One live request to verify the cover fallback chain (spec 003 FR-F1-09).
///
///     LIVE_NETWORK=1 flutter test --tags live-network test/integration/cover_live_test.dart
///
/// 9783833874239 has no Open Library cover and Google Books may be
/// rate-limited; the DNB cover service delivers it. The stored URL is left
/// out on purpose so Google is not called.
const _isbn = '9783833874239';

void main() {
  final enabled = Platform.environment['LIVE_NETWORK'] == '1';

  test(
    'the DNB cover service delivers a cover for an ISBN without other sources',
    () async {
      final dir = Directory.systemTemp.createTempSync('cover_live');
      addTearDown(() => dir.deleteSync(recursive: true));
      final service = CoverCacheService(baseDirectory: dir);

      final path = await service.resolveAny(
        _isbn,
        coverCandidates(isbn: _isbn),
      );

      expect(path, isNotNull);
      expect(File(path!).lengthSync(), greaterThan(1000));
    },
    skip: enabled ? false : 'set LIVE_NETWORK=1 to run',
  );
}
