import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'file_picker_io.dart' if (dart.library.html) 'file_picker_stub.dart' as impl;

class FileHelper {
  static Future<List<PlatformFile>?> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      return result?.files;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Pick a directory and return all files within it (non-web only).
  static Future<List<PlatformFile>?> pickFolder() async {
    if (kIsWeb) return null;
    return impl.pickFolder();
  }
}
