import 'dart:convert';
import 'dart:typed_data';

/// Connection lifecycle of a nearby device (a "peer").
enum PeerState {
  discovered, // seen during scanning, not connected yet
  connecting, // we asked to connect, waiting for handshake
  awaitingApproval, // handshake started, both users must confirm the code
  connected, // encrypted socket is open
  failed, // rejected / error
}

class MeshPeer {
  MeshPeer({
    required this.endpointId,
    required this.name,
    this.state = PeerState.discovered,
    this.authCode,
    this.isIncoming = false,
  });

  final String endpointId;
  final String name;
  PeerState state;

  /// Short code both screens display so users can verify they are pairing
  /// with the right person (protects against man-in-the-middle).
  String? authCode;
  bool isIncoming;
}

/// A single chat line. [id] + [ttl] enable multi-hop relaying (flooding).
class MeshMessage {
  MeshMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.ttl = 4,
    this.isMine = false,
    this.isSystem = false,
    this.hops = 0,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final int ttl;
  final bool isMine;
  final bool isSystem;
  final int hops;

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode({
        'id': id,
        'sid': senderId,
        'sn': senderName,
        't': text,
        'ts': timestamp.millisecondsSinceEpoch,
        'ttl': ttl,
        'h': hops,
      })));

  static MeshMessage? fromBytes(Uint8List bytes) {
    try {
      final m = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return MeshMessage(
        id: m['id'] as String,
        senderId: m['sid'] as String,
        senderName: m['sn'] as String,
        text: m['t'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int),
        ttl: m['ttl'] as int,
        hops: (m['h'] as int?) ?? 0,
      );
    } catch (_) {
      return null; // ignore malformed payloads
    }
  }

  MeshMessage copyForRelay() => MeshMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: timestamp,
        ttl: ttl - 1,
        hops: hops + 1,
      );
}