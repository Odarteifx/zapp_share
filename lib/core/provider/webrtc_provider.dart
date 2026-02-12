import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/file_saver.dart';

class WebRTCProvider extends ChangeNotifier {
  WebSocketChannel? _ws;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  List<String> _peers = [];
  String? _selfId;
  String? _roomId;
  String? _connectingPeerId;
  bool _disposed = false;

  // Reconnection state
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // seconds
  static const int _maxReconnectAttempts = 10;
  bool _isConnected = false;

  // File receive state
  String? _receivingFileName;
  int _receivingFileSize = 0;
  final List<int> _receivingBuffer = [];
  void Function(String filename, int received, int total)? onReceiveProgress;
  void Function(String filename, String path)? onFileReceived;

  List<String> get peers => _peers;
  bool get isConnectedToServer => _isConnected;
  bool get isDataChannelOpen =>
      _dataChannel != null &&
      _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen;
  String? get roomId => _roomId;
  /// The peer ID we're currently connected to (when data channel is open).
  String? get connectedPeerId =>
      isDataChannelOpen ? _connectingPeerId : null;

  // ---------------------------------------------------------------------------
  // Platform / Peer-info helpers
  // ---------------------------------------------------------------------------

  /// Returns a short platform tag for the current device.
  static String getPlatformPrefix() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Extract the human-readable name from a peer ID like `android:CosmicCorgi`.
  static String parsePeerName(String peerId) {
    final idx = peerId.indexOf(':');
    return idx >= 0 ? peerId.substring(idx + 1) : peerId;
  }

  /// Extract the platform tag from a peer ID like `android:CosmicCorgi`.
  static String parsePeerPlatform(String peerId) {
    final idx = peerId.indexOf(':');
    return idx >= 0 ? peerId.substring(0, idx) : 'unknown';
  }

  /// A user-friendly platform label (e.g. "Android", "iPhone", …).
  static String platformDisplayName(String platform) {
    switch (platform) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iPhone';
      case 'macos':
        return 'Mac';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      case 'web':
        return 'Web';
      default:
        return 'Device';
    }
  }

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ],
  };

  /// The signaling server URL.
  /// For local development run: `cd signaling_server && dart run bin/server.dart`
  final String _signalingServerUrl = 'ws://localhost:8080';

  Future<void> init(String selfId) async {
    _selfId = selfId;
    _connectWebSocket();
  }

  /// Guards against onError + onDone both triggering a reconnect.
  bool _reconnectScheduled = false;

  void _connectWebSocket() {
    if (_disposed || _selfId == null) return;
    _reconnectScheduled = false;

    // Close any leftover socket cleanly before opening a new one.
    final oldWs = _ws;
    _ws = null;
    try { oldWs?.sink.close(); } catch (_) {}

    try {
      final channel = WebSocketChannel.connect(Uri.parse(_signalingServerUrl));
      _ws = channel;

      channel.stream.listen(
        (message) {
          // Ignore messages if this channel has been superseded.
          if (_ws != channel) return;

          if (!_isConnected) {
            _isConnected = true;
            _reconnectAttempts = 0;
            debugPrint('WebSocket connected to $_signalingServerUrl');
            notifyListeners();
          }
          _handleSignalingMessage(message.toString());
        },
        onError: (e) {
          if (_ws != channel) return;
          debugPrint('WebSocket error: $e');
          _onDisconnected();
        },
        onDone: () {
          if (_ws != channel) return;
          // Check close code – 4000 means server evicted us (ghost), don't reconnect.
          final closeCode = channel.closeCode;
          debugPrint('WebSocket closed (code=$closeCode)');
          if (closeCode == 4000) {
            debugPrint('Server evicted this client – not reconnecting.');
            _isConnected = false;
            _peers = [];
            _ws = null;
            notifyListeners();
            return;
          }
          _onDisconnected();
        },
      );

      // Send join after connecting.
      _sendJoin(_roomId);
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _onDisconnected();
    }
  }

  /// Called whenever the WebSocket drops – clears stale data and reconnects once.
  void _onDisconnected() {
    _isConnected = false;
    _peers = [];
    _ws = null;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectScheduled) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached – giving up.');
      return;
    }
    _reconnectScheduled = true;
    _reconnectTimer?.cancel();
    final delay = Duration(
      seconds: (1 << _reconnectAttempts).clamp(1, _maxReconnectDelay),
    );
    _reconnectAttempts++;
    debugPrint('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)…');
    _reconnectTimer = Timer(delay, _connectWebSocket);
  }

  void _sendJoin(String? room) {
    if (_selfId == null) return;
    final msg = <String, dynamic>{'type': 'join', 'id': _selfId};
    if (room != null && room.isNotEmpty) msg['room'] = room;
    _ws?.sink.add(jsonEncode(msg));
  }

  void joinRoom(String roomId) {
    _roomId = roomId;
    _sendJoin(roomId);
    notifyListeners();
  }

  void leaveRoom() {
    _roomId = null;
    // Re-join the lobby (no room) so the server moves us back.
    _sendJoin(null);
    notifyListeners();
  }

  Future<void> _createPeerConnection({required bool isOfferer}) async {
    _peerConnection?.close();
    _peerConnection = await createPeerConnection(_iceServers);
    _dataChannel = null;

    _peerConnection!.onIceCandidate = (candidate) {
      if (_connectingPeerId != null) {
        _ws?.sink.add(jsonEncode({
          'type': 'candidate',
          'candidate': candidate.toMap(),
          'sender': _selfId,
          'receiver': _connectingPeerId,
        }));
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      if (!isOfferer) {
        _setupDataChannel(channel);
      }
    };

    if (isOfferer) {
      _dataChannel = await _peerConnection!.createDataChannel(
        'fileTransfer',
        RTCDataChannelInit()..ordered = true,
      );
      _setupDataChannel(_dataChannel!);
    }
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    channel.onDataChannelState = (state) {
      debugPrint('Data channel state: $state');
      notifyListeners();
    };
    channel.onMessage = (RTCDataChannelMessage message) {
      _handleDataChannelMessage(message);
    };
  }

  static const int _chunkSize = 16384;

  Future<void> sendFiles(List<PlatformFile> files) async {
    if (!isDataChannelOpen || files.isEmpty) return;

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        debugPrint('File ${file.name} has no bytes - use pickFiles(withData: true)');
        continue;
      }

      final meta = jsonEncode({
        't': 'file',
        'n': file.name,
        's': bytes.length,
      });
      _dataChannel!.send(RTCDataChannelMessage(meta));

      for (var i = 0; i < bytes.length; i += _chunkSize) {
        final end = (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        _dataChannel!.send(RTCDataChannelMessage.fromBinary(Uint8List.fromList(chunk)));
      }

      _dataChannel!.send(RTCDataChannelMessage(jsonEncode({'t': 'file_end'})));
    }
  }

  void _handleDataChannelMessage(RTCDataChannelMessage message) {
    if (!message.isBinary && message.text.isNotEmpty) {
      try {
        final json = jsonDecode(message.text) as Map<String, dynamic>;
        final type = json['t'] as String?;
        if (type == 'file') {
          _receivingFileName = json['n'] as String?;
          _receivingFileSize = (json['s'] as num?)?.toInt() ?? 0;
          _receivingBuffer.clear();
        } else if (type == 'file_end' && _receivingFileName != null) {
          _saveReceivedFile();
        }
      } catch (_) {}
    } else if (message.isBinary && _receivingFileName != null) {
      _receivingBuffer.addAll(message.binary);
      onReceiveProgress?.call(
        _receivingFileName!,
        _receivingBuffer.length,
        _receivingFileSize,
      );
    }
  }

  Future<void> _saveReceivedFile() async {
    if (_receivingFileName == null) return;
    final name = _receivingFileName!;
    final bytes = Uint8List.fromList(_receivingBuffer);
    _receivingFileName = null;
    _receivingBuffer.clear();
    _receivingFileSize = 0;

    try {
      final saved = await saveReceivedFile(name, bytes);
      if (saved != null) {
        onFileReceived?.call(name, saved);
      }
    } catch (e) {
      debugPrint('Save file error: $e');
    }
  }

  Future<void> connect(String peerId) async {
    _connectingPeerId = peerId;
    await _createPeerConnection(isOfferer: true);

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _ws?.sink.add(jsonEncode({
      'type': 'offer',
      'offer': offer.toMap(),
      'sender': _selfId,
      'receiver': peerId,
    }));
  }

  /// Disconnect from the currently paired peer (close data channel + peer connection).
  void disconnect() {
    _dataChannel?.close();
    _dataChannel = null;
    _peerConnection?.close();
    _peerConnection = null;
    _connectingPeerId = null;
    notifyListeners();
  }

  void _handleSignalingMessage(String message) {
    try {
      final decodedMessage = jsonDecode(message) as Map<String, dynamic>;
      final type = decodedMessage['type'] as String?;

      switch (type) {
        // ── Server heartbeat ──────────────────────────────────────────
        case 'ping':
          _ws?.sink.add(jsonEncode({'type': 'pong'}));
          return; // no UI update needed

        // ── Peer list ─────────────────────────────────────────────────
        case 'peer-list':
          _peers = List<String>.from(decodedMessage['peers'] ?? []);
          _peers.remove(_selfId);

          // If the peer we were paired with has gone away, auto-disconnect.
          if (_connectingPeerId != null &&
              !_peers.contains(_connectingPeerId)) {
            debugPrint('Paired peer $_connectingPeerId left – disconnecting');
            _dataChannel?.close();
            _dataChannel = null;
            _peerConnection?.close();
            _peerConnection = null;
            _connectingPeerId = null;
          }
          break;

        case 'offer':
          _handleOffer(decodedMessage);
          return;
        case 'answer':
          _handleAnswer(decodedMessage);
          break;
        case 'candidate':
          _handleCandidate(decodedMessage);
          break;
      }
    } catch (e) {
      debugPrint('Signaling message error: $e');
    }
    notifyListeners();
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData) async {
    final sender = offerData['sender'] as String?;
    if (sender == null) return;

    _connectingPeerId = sender;
    await _createPeerConnection(isOfferer: false);

    final offer = RTCSessionDescription(
      offerData['offer']['sdp'] as String,
      offerData['offer']['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _ws?.sink.add(jsonEncode({
      'type': 'answer',
      'answer': answer.toMap(),
      'sender': _selfId,
      'receiver': sender,
    }));
    notifyListeners();
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    final answer = RTCSessionDescription(
      answerData['answer']['sdp'] as String,
      answerData['answer']['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> _handleCandidate(Map<String, dynamic> candidateData) async {
    try {
      final cand = candidateData['candidate'] as Map<String, dynamic>?;
      if (cand == null) return;
      final candidate = RTCIceCandidate(
        cand['candidate'] as String,
        cand['sdpMid'] as String?,
        cand['sdpMLineIndex'] as int?,
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('Add candidate error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _ws?.sink.close();
    _peerConnection?.close();
    super.dispose();
  }
}
