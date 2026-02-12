import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<List<PlatformFile>?> pickFolder() async {
  try {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return null;
    final files = <PlatformFile>[];
    await for (final entity in Directory(path).list(recursive: true)) {
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final relativePath = entity.path.startsWith(path)
            ? entity.path.substring(path.length + 1)
            : entity.uri.pathSegments.last;
        files.add(PlatformFile(
          name: relativePath,
          size: bytes.length,
          bytes: bytes,
          path: entity.path,
        ));
      }
    }
    return files.isEmpty ? null : files;
  } catch (e) {
    return null;
  }
}
