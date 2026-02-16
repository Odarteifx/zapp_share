import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Simple WebRTC signaling server for ZappShare.
///
/// Peers must respond to a ping before they appear in anyone's peer list.
/// This eliminates ghost entries from stale browser tabs or crashed clients.
///
/// ## TURN server configuration (environment variables)
///
/// The server provisions ICE server credentials to every client so that
/// WebRTC connections succeed even across symmetric NATs / firewalls.
///
/// **Option A – HMAC time-limited credentials (recommended for coturn)**
///   TURN_URLS   – comma-separated TURN/TURNS URLs
///                 e.g. "turn:turn.example.com:3478,turns:turn.example.com:5349"
///   TURN_SECRET – the shared HMAC secret configured in coturn
///                 (`static-auth-secret` in turnserver.conf)
///
/// **Option B – Static / managed-service credentials**
///   TURN_URLS       – comma-separated TURN/TURNS URLs
///   TURN_USERNAME   – static username
///   TURN_CREDENTIAL – static credential
///
/// If none of the above are set, only public STUN servers are provided.

// ── Per-peer state ──────────────────────────────────────────────────────────
class _Peer {
  final String id;
  final WebSocket socket;
  String? room;
  DateTime lastSeen;
  bool verified; // becomes true once the peer replies to a ping

  _Peer(this.id, this.socket, {this.room})
      : lastSeen = DateTime.now(),
        verified = false;
}

final Map<String, _Peer> _peers = {};
final Map<int, String> _socketToPeer = {}; // socket.hashCode → peerId

const _pingInterval = Duration(seconds: 8);
const _peerTimeout = Duration(seconds: 20);

// ── TURN configuration (read once at startup) ───────────────────────────────
final List<String> _turnUrls = (Platform.environment['TURN_URLS'] ?? '')
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

final String? _turnSecret = Platform.environment['TURN_SECRET'];
final String? _turnUsername = Platform.environment['TURN_USERNAME'];
final String? _turnCredential = Platform.environment['TURN_CREDENTIAL'];

/// TTL for HMAC-generated credentials (24 hours).
const _hmacCredentialTtl = Duration(hours: 24);

void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('✓ Signaling server listening on ws://localhost:$port');

  if (_turnUrls.isNotEmpty) {
    final mode = _turnSecret != null ? 'HMAC (time-limited)' : 'static';
    print('  TURN configured ($mode): ${_turnUrls.join(', ')}');
  } else {
    print('  ⚠ No TURN servers configured – peers behind symmetric '
        'NATs may fail to connect.');
  }

  Timer.periodic(_pingInterval, (_) => _sweepAndPing());

  await for (final request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _handleConnection(socket);
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('ZappShare signaling server is running')
        ..close();
    }
  }
}

// ── Heartbeat / sweep ───────────────────────────────────────────────────────

void _sweepAndPing() {
  final now = DateTime.now();
  final dead = <String>[];

  for (final p in _peers.values) {
    if (now.difference(p.lastSeen) > _peerTimeout) {
      dead.add(p.id);
    }
  }

  for (final id in dead) {
    final peer = _peers[id];
    if (peer != null) {
      print('[timeout] $id (verified=${peer.verified})');
      _removePeer(id, peer.socket);
      // Close with custom code 4000 → tells smart clients not to reconnect.
      try { peer.socket.close(4000, 'timeout'); } catch (_) {}
    }
  }

  // Ping remaining peers.
  final ping = jsonEncode({'type': 'ping'});
  for (final p in _peers.values) {
    try { p.socket.add(ping); } catch (_) {}
  }
}

// ── Connection handler ──────────────────────────────────────────────────────

void _handleConnection(WebSocket socket) {
  final socketHash = socket.hashCode;

  socket.listen(
    (raw) {
      try {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        final type = msg['type'] as String?;

        // Update lastSeen for whichever peer owns this socket.
        final ownerId = _socketToPeer[socketHash];
        if (ownerId != null) {
          _peers[ownerId]?.lastSeen = DateTime.now();
        }

        switch (type) {
          case 'join':
            _handleJoin(msg, socket);
            break;

          case 'leave':
            final id = _socketToPeer[socketHash];
            if (id != null) {
              _removePeer(id, socket);
              print('[leave] $id');
            }
            break;

          case 'pong':
            _handlePong(socketHash);
            break;

          case 'offer':
          case 'answer':
          case 'candidate':
            final receiver = msg['receiver'] as String?;
            if (receiver != null) {
              final target = _peers[receiver];
              if (target != null) {
                target.socket.add(raw);
              }
            }
            break;
        }
      } catch (e) {
        print('Error: $e');
      }
    },
    onDone: () => _handleSocketClosed(socket),
    onError: (_) => _handleSocketClosed(socket),
  );
}

void _handleJoin(Map<String, dynamic> msg, WebSocket socket) {
  final id = msg['id'] as String?;
  if (id == null) return;

  final room = msg['room'] as String?;
  final socketHash = socket.hashCode;

  // Evict old socket if this peer ID reconnected on a new socket.
  final existing = _peers[id];
  if (existing != null && existing.socket != socket) {
    _socketToPeer.remove(existing.socket.hashCode);
    try { existing.socket.close(4001, 'replaced'); } catch (_) {}
  }

  // If this socket was under a different peer ID before, clean that up.
  final oldId = _socketToPeer[socketHash];
  if (oldId != null && oldId != id) {
    _removePeer(oldId, socket);
  }

  final oldRoom = _peers[id]?.room;

  // Register as UNVERIFIED – will not appear in peer lists yet.
  _peers[id] = _Peer(id, socket, room: room);
  _socketToPeer[socketHash] = id;

  // Immediately ping to verify liveness.
  try { socket.add(jsonEncode({'type': 'ping'})); } catch (_) {}

  // Broadcast updated list for old room if room changed.
  if (oldRoom != null && oldRoom != room) {
    _broadcastPeerList(oldRoom);
  }

  print('[join] $id → room=${room ?? 'lobby'} (unverified, waiting for pong)');
}

void _handlePong(int socketHash) {
  final id = _socketToPeer[socketHash];
  if (id == null) return;

  final peer = _peers[id];
  if (peer == null) return;

  final wasUnverified = !peer.verified;
  peer.verified = true;
  peer.lastSeen = DateTime.now();

  // First pong after join → now broadcast this peer to others.
  if (wasUnverified) {
    print('[verified] $id → room=${peer.room ?? 'lobby'} '
        '(${_verifiedPeersInRoom(peer.room).length} active in room)');
    _broadcastPeerList(peer.room);
  }
}

void _handleSocketClosed(WebSocket socket) {
  final socketHash = socket.hashCode;
  final id = _socketToPeer[socketHash];
  if (id == null) return;

  final peer = _peers[id];
  if (peer != null && peer.socket == socket) {
    _removePeer(id, socket);
    print('[disconnect] $id');
  } else {
    _socketToPeer.remove(socketHash);
  }
}

void _removePeer(String id, WebSocket socket) {
  _socketToPeer.remove(socket.hashCode);
  final peer = _peers[id];
  if (peer != null && peer.socket == socket) {
    _peers.remove(id);
    _broadcastPeerList(peer.room);
  }
}

// ── ICE server provisioning ─────────────────────────────────────────────────

/// Build the list of ICE servers to send to clients.
///
/// Always includes public STUN servers. If TURN is configured, generates
/// appropriate credentials (HMAC time-limited or static).
List<Map<String, dynamic>> _buildIceServers() {
  final servers = <Map<String, dynamic>>[
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  if (_turnUrls.isEmpty) return servers;

  if (_turnSecret != null && _turnSecret!.isNotEmpty) {
    // HMAC time-limited credentials (for coturn with use-auth-secret).
    final expiry = DateTime.now().add(_hmacCredentialTtl).millisecondsSinceEpoch ~/ 1000;
    final username = '$expiry:zappshare';
    final key = utf8.encode(_turnSecret!);
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(utf8.encode(username));
    final credential = base64.encode(digest.bytes);

    for (final url in _turnUrls) {
      servers.add({
        'urls': url,
        'username': username,
        'credential': credential,
      });
    }
  } else if (_turnUsername != null && _turnCredential != null) {
    // Static credentials (managed TURN services like Metered / Xirsys).
    for (final url in _turnUrls) {
      servers.add({
        'urls': url,
        'username': _turnUsername,
        'credential': _turnCredential,
      });
    }
  }

  return servers;
}

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Only VERIFIED peers appear in peer lists.
List<String> _verifiedPeersInRoom(String? room) {
  return _peers.values
      .where((p) => p.room == room && p.verified)
      .map((p) => p.id)
      .toList();
}

void _broadcastPeerList(String? room) {
  final ids = _verifiedPeersInRoom(room);
  final payload = jsonEncode({
    'type': 'peer-list',
    'peers': ids,
    'iceServers': _buildIceServers(),
  });
  // Send to ALL peers in the room (even unverified ones need to see the list).
  for (final p in _peers.values) {
    if (p.room == room) {
      try { p.socket.add(payload); } catch (_) {}
    }
  }
}
