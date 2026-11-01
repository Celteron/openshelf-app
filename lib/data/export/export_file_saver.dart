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
}

class PlatformExportFileSaver implements ExportFileSaver {
  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<String?> save(String fileName, String content) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    if (_isMobile) {
      // The app's own storage is invisible to the user on Android/iOS, so the
      // system "save as" dialog writes the file where they choose. The path it
      // returns is a guess ("Downloads/<name>") whatever folder was picked.
      final saved = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
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
