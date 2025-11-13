import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart';

void updateSystemUIColor(JSString color) {
  if (kIsWeb) {
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', color.toDart);
  }
}
