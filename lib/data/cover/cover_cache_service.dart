import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openreads/data/cover/cover_compaction.dart';

/// Keeps book covers on disk (`<base>/covers/<key>.jpg`) so they stay available
/// offline (Constitution Article III.3).
///
/// Remote covers are downloaded once and then served from the cache; manually
/// chosen covers (camera/gallery) are stored next to them. Downloads are
/// limited to a few at a time so scrolling a long library does not hammer the
/// cover hosts.
/// Open Library serves a cover for most ISBNs; `default=false` makes it answer
/// 404 (instead of a blank image) when it has none.
String openLibraryCoverUrl(String isbn) =>
    'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg?default=false';

/// The DNB's public cover service (MVB); covers most German-language ISBNs
/// that Open Library lacks.
String dnbCoverUrl(String isbn) =>
    'https://portal.dnb.de/opac/mvb/cover?isbn=$isbn';

/// Where to look for a book's cover, best first: the URL stored with the book
/// (from the metadata lookup), then the DNB, then Open Library by ISBN.
List<String> coverCandidates({String? coverUrl, String? isbn}) {
  final stored = coverUrl?.trim() ?? '';
  return {
    if (stored.isNotEmpty) stored,
    if (isbn != null) ...[dnbCoverUrl(isbn), openLibraryCoverUrl(isbn)],
  }.toList();
}

/// Outcome of looking for a cover online. Only [CoverMissing] is a definite
/// "there is none": a source that is offline, slow or overloaded says nothing
/// about the cover, so it is [CoverUnavailable].
sealed class CoverFetch {
  const CoverFetch();
}

class CoverFound extends CoverFetch {
  final String path;
  const CoverFound(this.path);
}

class CoverMissing extends CoverFetch {
  const CoverMissing();
}

class CoverUnavailable extends CoverFetch {
  const CoverUnavailable();
}

class CoverCacheService {
  static const _maxConcurrentDownloads = 4;

  /// Bodies smaller than this are the 1×1 "no cover" placeholders some hosts
  /// answer with, not real images.
  static const _minImageBytes = 200;

  final http.Client _client;
  final Directory _baseDirectory;
  var _activeDownloads = 0;
  final _waiting = <Completer<void>>[];

  CoverCacheService({http.Client? client, required Directory baseDirectory})
    : _client = client ?? http.Client(),
      _baseDirectory = baseDirectory;

  /// Every write goes through [compactCover], off the UI isolate.
  static Future<Uint8List?> _compact(Uint8List bytes) =>
      Isolate.run(() => compactCover(bytes));

  Directory get _coversDir => Directory('${_baseDirectory.path}/covers');

  File _file(String key) => File('${_coversDir.path}/${_safeKey(key)}.jpg');

  static String _safeKey(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  /// The cached file for [key], or `null` when nothing is cached yet.
  String? cachedPath(String key) {
    final file = _file(key);
    return file.existsSync() ? file.path : null;
  }

  /// Whether [path] still points at an existing file.
  bool exists(String? path) => path != null && File(path).existsSync();

  /// Returns the cached cover for [key], downloading [url] first if needed.
  /// `null` when there is no cache entry and no (working) URL.
  Future<String?> resolve(String key, String? url) async {
    final cached = cachedPath(key);
    if (cached != null) return cached;
    if (url == null || url.trim().isEmpty) return null;
    return downloadAndCache(key, url);
  }

  /// Like [resolve], but tries [urls] in order and keeps the first that
  /// delivers an image. A source that is down or rate-limited (e.g. Google
  /// Books answering 429) simply hands over to the next one.
  Future<String?> resolveAny(String key, Iterable<String> urls) async =>
      switch (await findAny(key, urls)) {
        CoverFound(:final path) => path,
        CoverMissing() || CoverUnavailable() => null,
      };

  /// Tries [urls] in order like [resolveAny] and says why nothing was found:
  /// [CoverMissing] only when every source answered "no cover".
  Future<CoverFetch> findAny(String key, Iterable<String> urls) async {
    final cached = cachedPath(key);
    if (cached != null) return CoverFound(cached);
    var unavailable = false;
    for (final url in urls) {
      switch (await fetch(key, url)) {
        case final CoverFound found:
          return found;
        case CoverMissing():
          break;
        case CoverUnavailable():
          unavailable = true;
      }
    }
    return unavailable ? const CoverUnavailable() : const CoverMissing();
  }

  /// Downloads [coverUrl] into the cache under [key] (replacing an older
  /// file) and returns the local path, or `null` on any failure.
  Future<String?> downloadAndCache(String key, String coverUrl) async =>
      switch (await fetch(key, coverUrl)) {
        CoverFound(:final path) => path,
        CoverMissing() || CoverUnavailable() => null,
      };

  /// Downloads one cover. 404/410, placeholder-sized bodies and non-images
  /// are [CoverMissing]; network errors, timeouts, other HTTP errors (429,
  /// 5xx) and a failed write are [CoverUnavailable].
  Future<CoverFetch> fetch(String key, String coverUrl) async {
    await _acquire();
    try {
      final response = await _client
          .get(Uri.parse(coverUrl))
          .timeout(const Duration(seconds: 15));
      final status = response.statusCode;
      if (status == 404 || status == 410) return const CoverMissing();
      if (status != 200) return const CoverUnavailable();
      final contentType = response.headers['content-type'];
      if (response.bodyBytes.length < _minImageBytes ||
          (contentType != null && !contentType.startsWith('image/'))) {
        return const CoverMissing();
      }
      final compact = await _compact(response.bodyBytes);
      if (compact == null) return const CoverMissing(); // not decodable
      return CoverFound(await _store(key, compact));
    } catch (_) {
      return const CoverUnavailable();
    } finally {
      _release();
    }
  }

  /// Stores user-supplied image bytes under [key], compacted, and returns the
  /// path. Throws a [FormatException] when the bytes are not an image.
  Future<String> saveCover(String key, List<int> bytes) async {
    final compact = await _compact(Uint8List.fromList(bytes));
    if (compact == null) throw const FormatException('Not an image');
    return _store(key, compact);
  }

  /// Deletes a cached/manual cover file; missing files are ignored.
  Future<void> deleteFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Deletes every cached and manually chosen cover.
  ///
  /// Only the `*.jpg` files the app wrote are removed, never recursively: on
  /// Linux the base folder is `~/Documents`, where a user may keep their own
  /// `covers` folder. The folder itself goes only when nothing else is in it.
  Future<void> deleteAll() async {
    try {
      final dir = _coversDir;
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          await entity.delete();
        }
      }
      if (await dir.list().isEmpty) await dir.delete();
    } catch (_) {}
  }

  /// Compacts covers written before every write went through [compactCover]
  /// (ADR-0004) and returns how many files shrank.
  ///
  /// One file at a time, so a long library does not hold many images in
  /// memory. Each file is replaced by an atomic rename on the same path, so the
  /// book rows stay valid and an interrupted run leaves only whole files (plus
  /// a `.part` file the next run removes). A result that saves less than a
  /// tenth is not written: re-encoding would cost quality for nothing and
  /// make a rerun touch the same files again.
  Future<int> compactStored() async {
    var compacted = 0;
    try {
      final dir = _coversDir;
      if (!await dir.exists()) return 0;
      final entities = await dir.list(followLinks: false).toList();
      for (final entity in entities) {
        if (entity is! File) continue;
        if (entity.path.endsWith('.part')) {
          await entity.delete();
        } else if (entity.path.endsWith('.jpg') && await _compactFile(entity)) {
          compacted++;
        }
      }
    } on FileSystemException catch (_) {
      // Storage trouble: the covers stay as they are, which is fine.
    }
    return compacted;
  }

  Future<bool> _compactFile(File file) async {
    try {
      if (await file.length() <= coverKeepAsIsBytes) return false;
      final modified = await file.lastModified();
      final bytes = await file.readAsBytes();
      final compact = await _compact(bytes);
      if (compact == null || compact.length > bytes.length * 0.9) return false;
      final part = File('${file.path}.part');
      await part.writeAsBytes(compact, flush: true);
      // A cover saved meanwhile (new photo, download) must not be replaced by
      // the compacted old one.
      if (await file.lastModified() != modified) {
        await part.delete();
        return false;
      }
      await part.rename(file.path);
      return true;
    } on FileSystemException catch (_) {
      return false;
    }
  }

  Future<String> _store(String key, List<int> bytes) async {
    await _coversDir.create(recursive: true);
    final file = _file(key);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _acquire() async {
    if (_activeDownloads < _maxConcurrentDownloads) {
      _activeDownloads++;
      return;
    }
    final waiter = Completer<void>();
    _waiting.add(waiter);
    await waiter.future;
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete(); // hand the slot to the next in line
    } else {
      _activeDownloads--;
    }
  }
}
