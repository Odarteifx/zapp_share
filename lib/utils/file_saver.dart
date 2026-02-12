import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart' as impl;

Future<String?> saveReceivedFile(String filename, Uint8List bytes) async {
  return impl.saveReceivedFile(filename, bytes);
}
