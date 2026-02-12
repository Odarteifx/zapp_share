import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveReceivedFile(String filename, Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = filename.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final path = '${dir.path}/ZappShare_$safeName';
    await File(path).writeAsBytes(bytes);
    return path;
  } catch (e) {
    return null;
  }
}
