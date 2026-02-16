import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/file_saver.dart';
import '../config/app_config.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

enum PeerConnectionStatus { waiting, connecting, connected }

/// Per-peer file receive buffer.
class _PeerReceiveState {
  String? fileName;
  int fileSize = 0;
  final List<int> buffer = [];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class WebRTCProvider extends ChangeNotifier {
  WebSocketChannel? _ws;
  List<String> _peers = [];
  String? _selfId;
  String? _roomId;
  bool _disposed = false;

  // ── ICE server configuration (updated dynamically from signaling server) ──
  Map<String, dynamic> _iceServers = {
    'iceServers': AppConfig.defaultIceServers,
  };

  // ── Multi-peer connection state ─────────────────────────────────────────
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final Map<String, _PeerReceiveState> _receiveStates = {};
  final Map<String, List<RTCIceCandidate>> _pendingCandidates = {};

  // Reconnection state
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // seconds
  static const int _maxReconnectAttempts = 10;
  bool _isConnected = false;

  // File receive callbacks
  void Function(String filename, int received, int total)? onReceiveProgress;
  void Function(String filename, String path)? onFileReceived;
  void Function(String filename, String error)? onFileReceiveError;

  // ── Observable transfer progress ────────────────────────────────────────
  String? _transferFileName;
  int _transferredBytes = 0;
  int _transferTotalBytes = 0;
  bool? _transferIsSending;
  int _transferTargetIndex = 0;
  int _transferTargetCount = 0;
  String? _transferTargetPeerName;

  String? get transferFileName => _transferFileName;
  int get transferredBytes => _transferredBytes;
  int get transferTotalBytes => _transferTotalBytes;
  bool? get transferIsSending => _transferIsSending;
  bool get isTransferring => _transferFileName != null;
  double get transferProgress =>
      _transferTotalBytes > 0 ? _transferredBytes / _transferTotalBytes : 0;
  int get transferTargetIndex => _transferTargetIndex;
  int get transferTargetCount => _transferTargetCount;
  String? get transferTargetPeerName => _transferTargetPeerName;

  List<String> get peers => _peers;
  bool get isConnectedToServer => _isConnected;
  String? get roomId => _roomId;

  /// Whether the current room is a public room (6-digit PIN).
  bool get isInPublicRoom => _roomId != null && _roomId!.length == 6;

  /// Set of peer IDs that have an open data channel.
  Set<String> get connectedPeerIds => _dataChannels.entries
      .where((e) => e.value.state == RTCDataChannelState.RTCDataChannelOpen)
      .map((e) => e.key)
      .toSet();

  /// True when at least one data channel is open.
  bool get isDataChannelOpen => connectedPeerIds.isNotEmpty;

  /// The single connected peer ID (backward-compat for 1:1 pairing).
  String? get connectedPeerId =>
      connectedPeerIds.isNotEmpty ? connectedPeerIds.first : null;

  /// Connection status for a specific peer.
  PeerConnectionStatus getPeerStatus(String peerId) {
    if (_dataChannels.containsKey(peerId) &&
        _dataChannels[peerId]!.state ==
            RTCDataChannelState.RTCDataChannelOpen) {
      return PeerConnectionStatus.connected;
    }
    if (_peerConnections.containsKey(peerId)) {
      return PeerConnectionStatus.connecting;
    }
    return PeerConnectionStatus.waiting;
  }

  // ---------------------------------------------------------------------------
  // Platform / Peer-info helpers
  // ---------------------------------------------------------------------------

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

  static String parsePeerName(String peerId) {
    final idx = peerId.indexOf(':');
    return idx >= 0 ? peerId.substring(idx + 1) : peerId;
  }

  static String parsePeerPlatform(String peerId) {
    final idx = peerId.indexOf(':');
    return idx >= 0 ? peerId.substring(0, idx) : 'unknown';
  }

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

  final String _signalingServerUrl = AppConfig.signalingServerUrl;

  Future<void> init(String selfId) async {
    _selfId = selfId;
    _connectWebSocket();
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  bool _reconnectScheduled = false;

  void _connectWebSocket() {
    if (_disposed || _selfId == null) return;
    _reconnectScheduled = false;

    final oldWs = _ws;
    _ws = null;
    try {
      oldWs?.sink.close();
    } catch (_) {}

    try {
      final channel = WebSocketChannel.connect(Uri.parse(_signalingServerUrl));
      _ws = channel;

      channel.stream.listen(
        (message) {
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
          final closeCode = channel.closeCode;
          debugPrint('WebSocket closed (code=$closeCode)');
          if (closeCode == 4000) {
            debugPrint('Server evicted this client – not reconnecting.');
            _isConnected = false;
            _peers = [];
            _ws = null;
            _disconnectAllPeers();
            notifyListeners();
            return;
          }
          _onDisconnected();
        },
      );

      _sendJoin(_roomId);
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _peers = [];
    _ws = null;
    _disconnectAllPeers();
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
    debugPrint(
        'Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)…');
    _reconnectTimer = Timer(delay, _connectWebSocket);
  }

  void _sendJoin(String? room) {
    if (_selfId == null) return;
    final msg = <String, dynamic>{'type': 'join', 'id': _selfId};
    if (room != null && room.isNotEmpty) msg['room'] = room;
    _ws?.sink.add(jsonEncode(msg));
  }

  void joinRoom(String roomId) {
    _disconnectAllPeers();
    _roomId = roomId;
    _sendJoin(roomId);
    notifyListeners();
  }

  void leaveRoom() {
    _disconnectAllPeers();
    _roomId = null;
    _sendJoin(null);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Multi-peer connection management
  // ---------------------------------------------------------------------------

  Future<RTCPeerConnection> _createPeerConnectionForPeer(
    String peerId, {
    required bool isOfferer,
  }) async {
    // Close existing connection to this peer if any.
    await _closePeerConnection(peerId);

    final pc = await createPeerConnection(_iceServers);
    _peerConnections[peerId] = pc;

    pc.onIceCandidate = (candidate) {
      _ws?.sink.add(jsonEncode({
        'type': 'candidate',
        'candidate': candidate.toMap(),
        'sender': _selfId,
        'receiver': peerId,
      }));
    };

    pc.onDataChannel = (channel) {
      if (!isOfferer) {
        _setupDataChannelForPeer(peerId, channel);
      }
    };

    if (isOfferer) {
      final dc = await pc.createDataChannel(
        'fileTransfer',
        RTCDataChannelInit()..ordered = true,
      );
      _setupDataChannelForPeer(peerId, dc);
    }

    // Drain any ICE candidates that arrived before this connection was ready.
    final buffered = _pendingCandidates.remove(peerId);
    if (buffered != null && buffered.isNotEmpty) {
      debugPrint('Applying ${buffered.length} buffered candidates for $peerId');
      for (final candidate in buffered) {
        try {
          await pc.addCandidate(candidate);
        } catch (e) {
          debugPrint('Buffered candidate error: $e');
        }
      }
    }

    return pc;
  }

  void _setupDataChannelForPeer(String peerId, RTCDataChannel channel) {
    _dataChannels[peerId] = channel;
    channel.onDataChannelState = (state) {
      debugPrint('Data channel [$peerId] state: $state');
      if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _dataChannels.remove(peerId);
        _receiveStates.remove(peerId);
      }
      notifyListeners();
    };
    channel.onMessage = (RTCDataChannelMessage message) {
      _handleDataChannelMessageFromPeer(peerId, message);
    };
  }

  Future<void> _closePeerConnection(String peerId) async {
    _dataChannels[peerId]?.close();
    _dataChannels.remove(peerId);
    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);
    _receiveStates.remove(peerId);
    _pendingCandidates.remove(peerId);
  }

  void _disconnectAllPeers() {
    for (final peerId in _peerConnections.keys.toList()) {
      _dataChannels[peerId]?.close();
      _peerConnections[peerId]?.close();
    }
    _peerConnections.clear();
    _dataChannels.clear();
    _receiveStates.clear();
    _pendingCandidates.clear();
  }

  Future<void> _connectToPeer(String peerId) async {
    // Don't create duplicate connections.
    if (_peerConnections.containsKey(peerId)) return;

    try {
      final pc =
          await _createPeerConnectionForPeer(peerId, isOfferer: true);

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _ws?.sink.add(jsonEncode({
        'type': 'offer',
        'offer': offer.toMap(),
        'sender': _selfId,
        'receiver': peerId,
      }));
    } catch (e) {
      debugPrint('Failed to connect to peer $peerId: $e');
      await _closePeerConnection(peerId);
    }
  }

  /// Auto-connect to new peers in any room.
  /// Uses ID comparison to break symmetry – higher ID initiates.
  /// In private rooms (4-digit), only one peer connection is allowed (1:1).
  void _autoConnectNewPeers() {
    if (_selfId == null) return;

    // In private rooms, skip if we already have a connection.
    if (!isInPublicRoom && _peerConnections.isNotEmpty) return;

    for (final peerId in _peers) {
      if (!_peerConnections.containsKey(peerId)) {
        if (_selfId!.compareTo(peerId) > 0) {
          debugPrint('Auto-connecting to $peerId');
          _connectToPeer(peerId);
          // In private rooms, only connect to one peer.
          if (!isInPublicRoom) break;
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Public API – connect / disconnect
  // ---------------------------------------------------------------------------

  /// Manually connect to a specific peer (used for 1:1 pairing).
  Future<void> connect(String peerId) async {
    // In private rooms, disconnect existing peers first (1:1 only).
    if (!isInPublicRoom) {
      _disconnectAllPeers();
    }
    await _connectToPeer(peerId);
  }

  /// Disconnect from a specific peer.
  void disconnectPeer(String peerId) {
    _closePeerConnection(peerId);
    notifyListeners();
  }

  /// Disconnect from all peers.
  void disconnect() {
    _disconnectAllPeers();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // File sending (supports multi-peer)
  // ---------------------------------------------------------------------------

  static const int _chunkSize = 16384;

  /// Send [files] to the given [targetPeerIds].
  /// If [targetPeerIds] is null, sends to ALL connected peers.
  Future<void> sendFiles(
    List<PlatformFile> files, {
    Set<String>? targetPeerIds,
  }) async {
    final targets = (targetPeerIds ?? connectedPeerIds)
        .where((id) =>
            _dataChannels[id]?.state ==
            RTCDataChannelState.RTCDataChannelOpen)
        .toList();

    if (files.isEmpty || targets.isEmpty) return;

    _transferTargetCount = targets.length;

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        debugPrint(
            'File ${file.name} has no bytes – use pickFiles(withData: true)');
        continue;
      }

      for (var pi = 0; pi < targets.length; pi++) {
        final peerId = targets[pi];
        final dc = _dataChannels[peerId];
        if (dc == null ||
            dc.state != RTCDataChannelState.RTCDataChannelOpen) {
          continue;
        }

        // Update transfer progress.
        _transferFileName = file.name;
        _transferTotalBytes = bytes.length;
        _transferredBytes = 0;
        _transferIsSending = true;
        _transferTargetIndex = pi + 1;
        _transferTargetPeerName = parsePeerName(peerId);
        notifyListeners();

        // Send file metadata.
        final meta = jsonEncode({
          't': 'file',
          'n': file.name,
          's': bytes.length,
        });
        dc.send(RTCDataChannelMessage(meta));

        // Send chunks.
        for (var i = 0; i < bytes.length; i += _chunkSize) {
          final end =
              (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          dc.send(
              RTCDataChannelMessage.fromBinary(Uint8List.fromList(chunk)));

          _transferredBytes = end;
          notifyListeners();

          await Future<void>.delayed(Duration.zero);
        }

        dc.send(RTCDataChannelMessage(jsonEncode({'t': 'file_end'})));
      }
    }

    // Clear transfer state.
    _transferFileName = null;
    _transferredBytes = 0;
    _transferTotalBytes = 0;
    _transferIsSending = null;
    _transferTargetIndex = 0;
    _transferTargetCount = 0;
    _transferTargetPeerName = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // File receiving (per-peer)
  // ---------------------------------------------------------------------------

  void _handleDataChannelMessageFromPeer(
      String peerId, RTCDataChannelMessage message) {
    if (!message.isBinary && message.text.isNotEmpty) {
      try {
        final json = jsonDecode(message.text) as Map<String, dynamic>;
        final type = json['t'] as String?;
        if (type == 'file') {
          final state = _PeerReceiveState()
            ..fileName = json['n'] as String?
            ..fileSize = (json['s'] as num?)?.toInt() ?? 0;
          _receiveStates[peerId] = state;

          _transferFileName = state.fileName;
          _transferTotalBytes = state.fileSize;
          _transferredBytes = 0;
          _transferIsSending = false;
          _transferTargetPeerName = parsePeerName(peerId);
          notifyListeners();

          debugPrint(
              'Receiving file from $peerId: ${state.fileName} (${state.fileSize} bytes)');
        } else if (type == 'file_end') {
          _saveReceivedFileFromPeer(peerId);
        }
      } catch (e) {
        debugPrint('Data channel message parse error: $e');
      }
    } else if (message.isBinary) {
      final state = _receiveStates[peerId];
      if (state != null && state.fileName != null) {
        state.buffer.addAll(message.binary);
        _transferredBytes = state.buffer.length;
        notifyListeners();
        onReceiveProgress?.call(
            state.fileName!, state.buffer.length, state.fileSize);
      }
    }
  }

  Future<void> _saveReceivedFileFromPeer(String peerId) async {
    final state = _receiveStates[peerId];
    if (state == null || state.fileName == null) return;

    final name = state.fileName!;
    final expectedSize = state.fileSize;
    final bytes = Uint8List.fromList(state.buffer);

    _receiveStates.remove(peerId);

    // Clear observable transfer state.
    _transferFileName = null;
    _transferredBytes = 0;
    _transferTotalBytes = 0;
    _transferIsSending = null;
    _transferTargetPeerName = null;
    notifyListeners();

    if (expectedSize > 0 && bytes.length != expectedSize) {
      final msg =
          'Size mismatch for "$name": expected $expectedSize bytes, got ${bytes.length}';
      debugPrint(msg);
      onFileReceiveError?.call(name, msg);
      return;
    }

    try {
      final saved = await saveReceivedFile(name, bytes);
      if (saved != null) {
        debugPrint('File saved: $saved');
        onFileReceived?.call(name, saved);
      } else {
        debugPrint('Failed to save file: $name');
        onFileReceiveError?.call(name, 'Failed to save file');
      }
    } catch (e) {
      debugPrint('Save file error: $e');
      onFileReceiveError?.call(name, e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Signaling message handler
  // ---------------------------------------------------------------------------

  void _handleSignalingMessage(String message) {
    try {
      final decodedMessage = jsonDecode(message) as Map<String, dynamic>;
      final type = decodedMessage['type'] as String?;

      switch (type) {
        case 'ping':
          _ws?.sink.add(jsonEncode({'type': 'pong'}));
          return;

        case 'peer-list':
          _peers = List<String>.from(decodedMessage['peers'] ?? []);
          _peers.remove(_selfId);

          // Update ICE servers if the signaling server provided them.
          final serverIce = decodedMessage['iceServers'];
          if (serverIce is List && serverIce.isNotEmpty) {
            _iceServers = {
              'iceServers': List<Map<String, dynamic>>.from(
                serverIce.map((e) => Map<String, dynamic>.from(e as Map)),
              ),
            };
            debugPrint(
                'ICE servers updated from signaling server '
                '(${serverIce.length} entries, '
                'TURN: ${serverIce.any((e) => e['urls']?.toString().startsWith('turn') ?? false)})');
          }

          // Remove connections for peers that left.
          for (final peerId in _peerConnections.keys.toList()) {
            if (!_peers.contains(peerId)) {
              debugPrint('Peer $peerId left – disconnecting');
              _closePeerConnection(peerId);
            }
          }

          // Auto-connect to new peers in any room (public or private).
          if (_roomId != null) {
            _autoConnectNewPeers();
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

    // In private rooms, disconnect existing peers first (1:1).
    if (!isInPublicRoom) {
      _disconnectAllPeers();
    }

    final pc =
        await _createPeerConnectionForPeer(sender, isOfferer: false);

    final offer = RTCSessionDescription(
      offerData['offer']['sdp'] as String,
      offerData['offer']['type'] as String,
    );
    await pc.setRemoteDescription(offer);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _ws?.sink.add(jsonEncode({
      'type': 'answer',
      'answer': answer.toMap(),
      'sender': _selfId,
      'receiver': sender,
    }));
    notifyListeners();
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    final sender = answerData['sender'] as String?;
    if (sender == null) return;

    final pc = _peerConnections[sender];
    if (pc == null) {
      debugPrint('No peer connection for $sender to apply answer');
      return;
    }

    final answer = RTCSessionDescription(
      answerData['answer']['sdp'] as String,
      answerData['answer']['type'] as String,
    );
    await pc.setRemoteDescription(answer);
  }

  Future<void> _handleCandidate(Map<String, dynamic> candidateData) async {
    final sender = candidateData['sender'] as String?;
    if (sender == null) return;

    try {
      final cand = candidateData['candidate'] as Map<String, dynamic>?;
      if (cand == null) return;
      final candidate = RTCIceCandidate(
        cand['candidate'] as String,
        cand['sdpMid'] as String?,
        cand['sdpMLineIndex'] as int?,
      );

      final pc = _peerConnections[sender];
      if (pc == null) {
        // Peer connection not ready yet — buffer the candidate.
        debugPrint('Buffering ICE candidate for $sender');
        _pendingCandidates.putIfAbsent(sender, () => []).add(candidate);
        return;
      }

      await pc.addCandidate(candidate);
    } catch (e) {
      debugPrint('Add candidate error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _disconnectAllPeers();
    _ws?.sink.close();
    super.dispose();
  }
}
