import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Simple WebRTC signaling server for ZappShare.
///
/// Peers must respond to a ping before they appear in anyone's peer list.
/// This eliminates ghost entries from stale browser tabs or crashed clients.

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

void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('✓ Signaling server listening on ws://localhost:$port');

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
  final payload = jsonEncode({'type': 'peer-list', 'peers': ids});
  // Send to ALL peers in the room (even unverified ones need to see the list).
  for (final p in _peers.values) {
    if (p.room == room) {
      try { p.socket.add(payload); } catch (_) {}
    }
  }
}
