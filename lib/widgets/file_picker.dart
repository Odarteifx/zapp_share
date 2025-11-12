import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';

class FileHelper {
  static Future<List<PlatformFile>?> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      return result?.files;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
}
