import 'dart:io';

import 'package:http/http.dart' as http;

/// Downloads remote cover images into the app documents directory
/// (`covers/<isbn13>.jpg`) and returns the local file path, so covers remain
/// available offline (Constitution Article III.3).
class CoverCacheService {
  final http.Client _client;
  final Directory _baseDirectory;

  CoverCacheService({http.Client? client, required Directory baseDirectory})
    : _client = client ?? http.Client(),
      _baseDirectory = baseDirectory;

  Future<String?> downloadAndCache(String isbn13, String coverUrl) async {
    try {
      final response = await _client.get(Uri.parse(coverUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;

      final coversDir = Directory('${_baseDirectory.path}/covers');
      await coversDir.create(recursive: true);

      final file = File('${coversDir.path}/$isbn13.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
