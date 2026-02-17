import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Sanitize a single path component (file or folder name) without
/// destroying path separators.  Keeps alphanumerics, hyphens, dots,
/// underscores, and spaces.
String _sanitizeComponent(String component) {
  return component.replaceAll(RegExp(r'[^\w\-. ]'), '_');
}

Future<String?> saveReceivedFile(String filename, Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final zappDir = Directory('${dir.path}/ZappShare');

    // Normalize separators (handles Windows-originated paths too).
    final normalized = filename.replaceAll('\\', '/');

    // Split into components, sanitize each individually, and re-join.
    final parts = normalized.split('/');
    final safeParts = parts.map(_sanitizeComponent).toList();
    final safeName = safeParts.join(Platform.pathSeparator);

    final fullPath = '${zappDir.path}${Platform.pathSeparator}$safeName';
    final file = File(fullPath);

    // Create parent directories if they don't exist (for folders).
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return fullPath;
  } catch (e) {
    debugPrint('saveReceivedFile error: $e');
    return null;
  }
}
