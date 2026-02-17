import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String?> saveReceivedFile(String filename, Uint8List bytes) async {
  try {
    // For browser downloads, use only the leaf filename (strip folder paths).
    final normalized = filename.replaceAll('\\', '/');
    final downloadName = normalized.contains('/')
        ? normalized.substring(normalized.lastIndexOf('/') + 1)
        : normalized;

    final base64 = base64Encode(bytes);
    final dataUrl = 'data:application/octet-stream;base64,$base64';
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = dataUrl
      ..download = downloadName
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    return downloadName;
  } catch (e) {
    return null;
  }
}
