import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// The three network states the dashboard cares about. [other] covers
/// interfaces such as ethernet/VPN that connectivity_plus can report but
/// that don't fit the Wi-Fi / Cellular / Offline categories.
enum NetworkStatus { wifi, cellular, other, offline }

/// Lifecycle of a simulated long-running data request.
enum RequestStatus { inProgress, queued, completed }

/// Thrown internally when the network drops mid-request. Caught by
/// [NetworkMonitorState._runRequest] so the app never crashes on a
/// handover — the request is queued instead.
class NetworkDroppedException implements Exception {}

class QueuedRequest {
  final String id;
  final String name;
  final int totalChunks;
  int completedChunks;
  RequestStatus status;
  final DateTime startedAt;
  DateTime? completedAt;

  QueuedRequest({
    required this.id,
    required this.name,
    required this.totalChunks,
    this.completedChunks = 0,
    this.status = RequestStatus.inProgress,
    required this.startedAt,
    this.completedAt,
  });

  double get progress => completedChunks / totalChunks;
}

class NetworkLogEntry {
  final String message;
  final DateTime time;
  NetworkLogEntry(this.message, this.time);
}

/// Global state for the Network Monitor activity.
///
/// - Subscribes to [Connectivity.onConnectivityChanged] to track the active
///   network interface in real time (Wi-Fi, Cellular, or Offline).
/// - Simulates a long-running "large dataset" fetch in discrete chunks.
/// - If the connection drops mid-fetch (e.g. during a Wi-Fi ↔ Cellular
///   handover), the in-flight request is caught and moved to a queue
///   instead of crashing or silently failing.
/// - When the connectivity stream reports a stable connection again, queued
///   requests are automatically resumed from where they left off.
///
/// Note: connectivity_plus already declares the ACCESS_NETWORK_STATE
/// permission it needs via its own Android manifest, so no extra manifest
/// entry is required in the host app.
class NetworkMonitorState extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkStatus _status = NetworkStatus.offline;
  NetworkStatus get status => _status;

  final List<QueuedRequest> _requests = [];
  List<QueuedRequest> get requests => List.unmodifiable(_requests);

  final List<NetworkLogEntry> _log = [];
  List<NetworkLogEntry> get log => List.unmodifiable(_log.reversed);

  int _requestCounter = 0;
  bool _isResumingQueue = false;

  /// Begins listening to the real-time connectivity stream. Call once,
  /// e.g. via `NetworkMonitorState()..init()` at Provider creation.
  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    _status = _mapStatus(initial);
    _addLog('Initial network: ${statusLabel(_status)}');
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final previous = _status;
      final next = _mapStatus(results);
      if (next == previous) return;

      _status = next;
      _addLog('Network changed: ${statusLabel(previous)} → ${statusLabel(next)}');
      notifyListeners();

      // Graceful recovery: as soon as we come back online from Offline,
      // automatically resume any queued requests.
      if (previous == NetworkStatus.offline && next != NetworkStatus.offline) {
        _resumeQueuedRequests();
      }
    });
  }

  NetworkStatus _mapStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return NetworkStatus.wifi;
    if (results.contains(ConnectivityResult.mobile)) return NetworkStatus.cellular;
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.other;
  }

  static String statusLabel(NetworkStatus s) {
    switch (s) {
      case NetworkStatus.wifi:
        return 'Wi-Fi';
      case NetworkStatus.cellular:
        return 'Cellular';
      case NetworkStatus.other:
        return 'Other Network';
      case NetworkStatus.offline:
        return 'Offline';
    }
  }

  void _addLog(String message) {
    _log.add(NetworkLogEntry(message, DateTime.now()));
    if (_log.length > 30) _log.removeAt(0);
  }

  /// Starts a simulated large-dataset fetch, broken into chunks so a
  /// handover can realistically interrupt it mid-flight.
  Future<void> startSimulatedRequest({String? label}) async {
    _requestCounter++;
    final request = QueuedRequest(
      id: 'req_$_requestCounter',
      name: label ?? 'Data Fetch #$_requestCounter',
      totalChunks: 6,
      startedAt: DateTime.now(),
    );
    _requests.add(request);
    _addLog('${request.name} started.');
    notifyListeners();

    await _runRequest(request);
  }

  /// Executes (or resumes) a request chunk-by-chunk. If the network drops
  /// partway through, the error is caught here — the request's progress is
  /// preserved and its status flips to [RequestStatus.queued] rather than
  /// throwing an unhandled exception up the widget tree.
  Future<void> _runRequest(QueuedRequest request) async {
    request.status = RequestStatus.inProgress;
    notifyListeners();

    for (int i = request.completedChunks; i < request.totalChunks; i++) {
      try {
        await Future.delayed(const Duration(milliseconds: 700));

        if (_status == NetworkStatus.offline) {
          throw NetworkDroppedException();
        }

        request.completedChunks = i + 1;
        notifyListeners();
      } on NetworkDroppedException {
        request.status = RequestStatus.queued;
        _addLog(
          '${request.name} interrupted mid-transfer — connection dropped. '
          'Queued at ${request.completedChunks}/${request.totalChunks} chunks.',
        );
        notifyListeners();
        return;
      }
    }

    request.status = RequestStatus.completed;
    request.completedAt = DateTime.now();
    _addLog('${request.name} completed successfully.');
    notifyListeners();
  }

  /// Called automatically whenever the connectivity stream reports a
  /// transition from Offline back to Wi-Fi/Cellular/Other. Resumes every
  /// queued request in order, continuing from its last completed chunk.
  Future<void> _resumeQueuedRequests() async {
    if (_isResumingQueue) return;
    _isResumingQueue = true;

    final queued = _requests.where((r) => r.status == RequestStatus.queued).toList();
    for (final request in queued) {
      _addLog('Resuming ${request.name} — connection restored.');
      await _runRequest(request);
    }

    _isResumingQueue = false;
  }

  void clearCompleted() {
    _requests.removeWhere((r) => r.status == RequestStatus.completed);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}