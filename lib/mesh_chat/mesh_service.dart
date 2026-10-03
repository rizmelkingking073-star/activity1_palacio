import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import 'mesh_models.dart';

enum MeshStatus { idle, starting, running, error }

/// All networking logic lives here. The UI only reads this object's state
/// (UI = f(state)) and calls its methods.
class MeshService extends ChangeNotifier {
  MeshService({String? userName})
      : userName = userName ?? 'User-${_rand.nextInt(9000) + 1000}';

  static final _rand = Random.secure();

  /// Devices must use the same service id to find each other.
  static const String serviceId = 'com.palacio.labcompilation.meshchat';

  /// P2P_CLUSTER = M-to-N topology, so devices can form a mesh.
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  final Nearby _nearby = Nearby();

  /// Stable id for this install session, used for message de-duplication.
  final String deviceId = List.generate(12, (_) => _rand.nextInt(36).toRadixString(36)).join();

  String userName;
  MeshStatus status = MeshStatus.idle;
  String? errorMessage;

  final Map<String, MeshPeer> _peers = {};
  final List<MeshMessage> _messages = [];
  final Set<String> _seenIds = {};

  // ---- read-only state for the UI -------------------------------------
  List<MeshPeer> get discovered =>
      _peers.values.where((p) => p.state == PeerState.discovered || p.state == PeerState.failed || p.state == PeerState.connecting).toList();
  List<MeshPeer> get pending =>
      _peers.values.where((p) => p.state == PeerState.awaitingApproval).toList();
  List<MeshPeer> get connected =>
      _peers.values.where((p) => p.state == PeerState.connected).toList();
  List<MeshMessage> get messages => List.unmodifiable(_messages);
  bool get isRunning => status == MeshStatus.running;

  // ---- 1. permissions + discovery -------------------------------------
  /// Ask for every permission Nearby may need. We deliberately do NOT gate on
  /// the results: which ones exist depends on the Android version (e.g. the
  /// Bluetooth ones only exist on Android 12+, NEARBY_WIFI_DEVICES on 13+), so
  /// a "denied" for a permission that doesn't apply would wrongly block us.
  /// If something truly required is missing, Nearby throws and we show it.
  Future<void> _requestPermissions() async {
    // One at a time so every system dialog is shown reliably.
    for (final p in [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ]) {
      try {
        if (!await p.isGranted) await p.request();
      } catch (_) {/* not applicable on this Android version */}
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('MISSING_PERMISSION') || msg.contains('8034') || msg.toLowerCase().contains('permission')) {
      return 'Missing permission. Open Settings > Apps > this app > Permissions '
          'and allow Location and Nearby devices, then try again.';
    }
    return msg;
  }

  /// Start broadcasting our presence AND scanning for neighbours.
  Future<void> start() async {
    if (status == MeshStatus.starting || status == MeshStatus.running) return;
    status = MeshStatus.starting;
    errorMessage = null;
    notifyListeners();

    try {
      await _requestPermissions();
      if (!await Permission.location.serviceStatus.isEnabled) {
        throw 'Turn on Location (GPS) – Nearby needs it to scan.';
      }

      await _nearby.startAdvertising(
        userName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: serviceId,
      );

      await _nearby.startDiscovery(
        userName,
        _strategy,
        onEndpointFound: (id, name, svc) {
          _peers.putIfAbsent(id, () => MeshPeer(endpointId: id, name: name));
          notifyListeners();
        },
        onEndpointLost: (id) {
          if (id != null && _peers[id]?.state == PeerState.discovered) {
            _peers.remove(id);
            notifyListeners();
          }
        },
        serviceId: serviceId,
      );

      status = MeshStatus.running;
      _system('Mesh started as "$userName". Scanning for nearby devices…');
    } catch (e) {
      status = MeshStatus.error;
      errorMessage = _friendlyError(e);
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _peers.clear();
    status = MeshStatus.idle;
    _system('Mesh stopped.');
    notifyListeners();
  }

  // ---- 2. connection + handshake --------------------------------------
  /// We tap a discovered device -> start the handshake.
  Future<void> connectTo(MeshPeer peer) async {
    peer.state = PeerState.connecting;
    notifyListeners();
    try {
      await _nearby.requestConnection(
        userName,
        peer.endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      peer.state = PeerState.failed;
      notifyListeners();
    }
  }

  /// Fired on BOTH devices. Nearby has already set up an encrypted channel;
  /// the authentication code lets the users verify it out-of-band.
  void _onConnectionInitiated(String id, ConnectionInfo info) {
    final peer = _peers.putIfAbsent(id, () => MeshPeer(endpointId: id, name: info.endpointName));
    peer
      ..state = PeerState.awaitingApproval
      ..authCode = info.authenticationToken
      ..isIncoming = info.isIncomingConnection;
    notifyListeners();
  }

  Future<void> approve(MeshPeer peer) async {
    await _nearby.acceptConnection(
      peer.endpointId,
      onPayLoadRecieved: _onPayload,
      onPayloadTransferUpdate: (_, __) {},
    );
  }

  Future<void> reject(MeshPeer peer) async {
    await _nearby.rejectConnection(peer.endpointId);
    peer.state = PeerState.failed;
    notifyListeners();
  }

  void _onConnectionResult(String id, Status s) {
    final peer = _peers[id];
    if (peer == null) return;
    if (s == Status.CONNECTED) {
      peer.state = PeerState.connected;
      _system('${peer.name} joined the mesh.');
    } else {
      peer.state = PeerState.failed;
    }
    notifyListeners();
  }

  void _onDisconnected(String id) {
    final peer = _peers.remove(id);
    if (peer != null) _system('${peer.name} left the mesh.');
    notifyListeners();
  }

  Future<void> disconnect(MeshPeer peer) async {
    await _nearby.disconnectFromEndpoint(peer.endpointId);
    _onDisconnected(peer.endpointId);
  }

  // ---- 3. payload routing ---------------------------------------------
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msg = MeshMessage(
      id: '$deviceId-${DateTime.now().microsecondsSinceEpoch}',
      senderId: deviceId,
      senderName: userName,
      text: trimmed,
      timestamp: DateTime.now(),
      isMine: true,
    );
    _seenIds.add(msg.id);
    _messages.add(msg);
    notifyListeners();
    await _broadcast(msg, exceptEndpoint: null);
  }

  void _onPayload(String fromEndpoint, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    final msg = MeshMessage.fromBytes(payload.bytes!);
    if (msg == null) return;

    // De-duplicate: in a mesh the same message can arrive via several paths.
    if (!_seenIds.add(msg.id)) return;

    _messages.add(msg);
    notifyListeners();

    // Multi-hop relay (flooding with TTL): forward to everyone except the
    // peer we got it from, so devices out of range of the sender still
    // receive it through intermediate nodes.
    if (msg.ttl > 1) {
      _broadcast(msg.copyForRelay(), exceptEndpoint: fromEndpoint);
    }
  }

  Future<void> _broadcast(MeshMessage msg, {required String? exceptEndpoint}) async {
    final bytes = msg.toBytes();
    for (final peer in connected) {
      if (peer.endpointId == exceptEndpoint) continue;
      try {
        await _nearby.sendBytesPayload(peer.endpointId, bytes);
      } catch (_) {/* peer dropped; onDisconnected will clean up */}
    }
  }

  void _system(String text) {
    _messages.add(MeshMessage(
      id: 'sys-${DateTime.now().microsecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'System',
      text: text,
      timestamp: DateTime.now(),
      isSystem: true,
    ));
  }

  @override
  void dispose() {
    _nearby.stopAdvertising();
    _nearby.stopDiscovery();
    _nearby.stopAllEndpoints();
    super.dispose();
  }
}