import 'package:flutter/foundation.dart';

/// Centralised app configuration.
///
/// In **debug** mode (`flutter run`) the signaling server defaults to
/// `ws://localhost:8080` so you can develop against a local server.
///
/// In **release** mode (`flutter run --release` / production builds) it
/// defaults to the deployed Fly.io instance over secure WebSockets.
///
/// You can override at compile-time with:
/// ```
/// flutter run --dart-define=SIGNALING_URL=wss://my-custom-server.example.com
/// ```
class AppConfig {
  AppConfig._();

  static const String _defaultProdUrl = 'wss://zappshare-signaling.fly.dev';
  static const String _defaultDevUrl = 'ws://localhost:8080';

  /// Resolved signaling server URL.
  static String get signalingServerUrl {
    // Compile-time override takes highest priority.
    const override = String.fromEnvironment('SIGNALING_URL');
    if (override.isNotEmpty) return override;

    // Otherwise pick based on build mode.
    return kReleaseMode ? _defaultProdUrl : _defaultDevUrl;
  }

  /// Default ICE servers used as a fallback before the signaling server
  /// provides its own list (which may include TURN credentials).
  static const List<Map<String, String>> defaultIceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];
}
