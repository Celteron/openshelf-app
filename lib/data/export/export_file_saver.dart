import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Puts an export file where the user can reach it. An interface so screens
/// and tests do not depend on a platform plugin.
abstract class ExportFileSaver {
  /// Where the file was saved (a path on desktop, the file name on mobile), or
  /// `null` when the user cancelled.
  Future<String?> save(String fileName, String content);

  /// Like [save] for binary content such as an image.
  Future<String?> saveBytes(
    String fileName,
    Uint8List bytes, {
    required String mimeType,
  });
}

class PlatformExportFileSaver implements ExportFileSaver {
  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<String?> save(String fileName, String content) => saveBytes(
    fileName,
    Uint8List.fromList(utf8.encode(content)),
    mimeType: fileName.endsWith('.json') ? 'application/json' : 'text/csv',
  );

  @override
  Future<String?> saveBytes(
    String fileName,
    Uint8List bytes, {
    required String mimeType,
  }) async {
    if (_isMobile) {
      // The app's own storage is invisible to the user on Android/iOS, so the
      // system "save as" dialog writes the file where they choose. Its URI is
      // a content:// handle, so the file name is the only readable part.
      final saved = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      return saved == null ? null : fileName;
    }
    // Desktop Linux has no save dialog without zenity/kdialog.
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
