import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Keeps book covers on disk (`<base>/covers/<key>.jpg`) so they stay available
/// offline (Constitution Article III.3).
///
/// Remote covers are downloaded once and then served from the cache; manually
/// chosen covers (camera/gallery) are stored next to them. Downloads are
/// limited to a few at a time so scrolling a long library does not hammer the
/// cover hosts.
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

  /// Downloads [coverUrl] into the cache under [key] (replacing an older
  /// file) and returns the local path, or `null` on any failure.
  Future<String?> downloadAndCache(String key, String coverUrl) async {
    await _acquire();
    try {
      final response = await _client
          .get(Uri.parse(coverUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 ||
          response.bodyBytes.length < _minImageBytes) {
        return null;
      }
      final contentType = response.headers['content-type'];
      if (contentType != null && !contentType.startsWith('image/')) {
        return null;
      }
      return await _write(key, response.bodyBytes);
    } catch (_) {
      return null;
    } finally {
      _release();
    }
  }

  /// Stores user-supplied image bytes under [key] and returns the path.
  Future<String> saveCover(String key, List<int> bytes) => _write(key, bytes);

  /// Deletes a cached/manual cover file; missing files are ignored.
  Future<void> deleteFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<String> _write(String key, List<int> bytes) async {
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
