import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ---------------------------------------------------------------------------
/// Operational tiers
/// ---------------------------------------------------------------------------

/// Connection health buckets the whole app reacts to.
///
/// * [excellent] — more than 10 Mbps down, healthy latency.
/// * [fair]      — 2–10 Mbps. Usable, but multimedia should be scaled down.
/// * [poor]      — under 2 Mbps. Serve lightweight placeholders only.
/// * [degraded]  — heavy packet loss or extreme latency. The link may report a
///                 decent raw speed yet still be unusable, so this tier wins
///                 over the bandwidth buckets.
/// * [unknown]   — no diagnostic has completed yet.
enum ConnectionTier { unknown, excellent, fair, poor, degraded }

/// What the UI should render for media-heavy content at the current tier.
enum MediaQuality { full, reduced, placeholder }

/// The step the diagnostic tool is currently executing.
enum DiagnosticPhase { idle, idlePing, download, upload, analyzing }

/// ---------------------------------------------------------------------------
/// Tunables
/// ---------------------------------------------------------------------------

class DiagnosticConfig {
  /// Zero-byte endpoint — the response is empty, so the round trip is a clean
  /// latency sample. (ICMP ping isn't available to Dart without platform code,
  /// so this is an HTTP round-trip time, which is what matters for the app.)
  static const String pingUrl = 'https://speed.cloudflare.com/__down?bytes=0';

  /// Returns a payload of exactly `bytes` incompressible bytes.
  static const String downloadUrlBase = 'https://speed.cloudflare.com/__down?bytes=';

  /// Accepts and discards a POST body.
  static const String uploadUrl = 'https://speed.cloudflare.com/__up';

  static const int idlePingSamples = 5;
  static const int initialDownloadBytes = 1 * 1024 * 1024; // 1 MB
  static const int maxDownloadBytes = 8 * 1024 * 1024; // 8 MB
  static const int uploadBytes = 512 * 1024; // 512 KB

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration probeInterval = Duration(milliseconds: 350);
  static const Duration autoTestInterval = Duration(seconds: 90);

  // Threshold logic lives here so it can be tuned in one place.
  static const double excellentMbps = 10.0;
  static const double fairMbps = 2.0;
  static const double degradedLossPercent = 15.0;
  static const double degradedLatencyMs = 900.0;
  static const double degradedBufferbloatMs = 500.0;
}

/// ---------------------------------------------------------------------------
/// Measurement value objects
/// ---------------------------------------------------------------------------

class PingStats {
  final double avgMs;
  final double jitterMs;
  final double lossPercent;
  final int sent;
  final int received;

  const PingStats({
    required this.avgMs,
    required this.jitterMs,
    required this.lossPercent,
    required this.sent,
    required this.received,
  });

  static const PingStats empty =
      PingStats(avgMs: 0, jitterMs: 0, lossPercent: 100, sent: 0, received: 0);

  /// Mean RTT, mean consecutive-sample deviation (jitter) and loss ratio.
  factory PingStats.from(List<double> samples, int failures) {
    final sent = samples.length + failures;
    if (samples.isEmpty) {
      return PingStats(
        avgMs: 0,
        jitterMs: 0,
        lossPercent: 100,
        sent: sent,
        received: 0,
      );
    }
    final avg = samples.reduce((a, b) => a + b) / samples.length;

    double jitter = 0;
    if (samples.length > 1) {
      double total = 0;
      for (int i = 1; i < samples.length; i++) {
        total += (samples[i] - samples[i - 1]).abs();
      }
      jitter = total / (samples.length - 1);
    }

    return PingStats(
      avgMs: avg,
      jitterMs: jitter,
      lossPercent: sent == 0 ? 0 : (failures / sent) * 100.0,
      sent: sent,
      received: samples.length,
    );
  }
}

class TransferResult {
  final double mbps;
  final double seconds;
  final int bytes;

  const TransferResult({
    required this.mbps,
    required this.seconds,
    required this.bytes,
  });

  static const TransferResult failed =
      TransferResult(mbps: 0, seconds: 0, bytes: 0);
}

/// One complete run of the diagnostic tool.
class DiagnosticSnapshot {
  final DateTime timestamp;
  final PingStats idlePing;
  final PingStats downloadPing;
  final PingStats uploadPing;
  final TransferResult download;
  final TransferResult upload;
  final ConnectionTier tier;
  final String? error;

  const DiagnosticSnapshot({
    required this.timestamp,
    required this.idlePing,
    required this.downloadPing,
    required this.uploadPing,
    required this.download,
    required this.upload,
    required this.tier,
    this.error,
  });

  /// How much latency grows while the link is saturated — the classic
  /// bufferbloat signal. A fast link with 800 ms of loaded latency still feels
  /// broken, so this feeds the tier decision.
  double get bufferbloatMs {
    final loaded = max(downloadPing.avgMs, uploadPing.avgMs);
    if (loaded == 0 || idlePing.avgMs == 0) return 0;
    return max(0, loaded - idlePing.avgMs);
  }

  double get worstLossPercent => [
        idlePing.lossPercent,
        downloadPing.lossPercent,
        uploadPing.lossPercent,
      ].reduce(max);

  DiagnosticSnapshot copyWithTier(ConnectionTier newTier) => DiagnosticSnapshot(
        timestamp: timestamp,
        idlePing: idlePing,
        downloadPing: downloadPing,
        uploadPing: uploadPing,
        download: download,
        upload: upload,
        tier: newTier,
        error: error,
      );

  factory DiagnosticSnapshot.failure(String message) => DiagnosticSnapshot(
        timestamp: DateTime.now(),
        idlePing: PingStats.empty,
        downloadPing: PingStats.empty,
        uploadPing: PingStats.empty,
        download: TransferResult.failed,
        upload: TransferResult.failed,
        tier: ConnectionTier.degraded,
        error: message,
      );
}

/// ---------------------------------------------------------------------------
/// Background pinger used *during* a transfer
/// ---------------------------------------------------------------------------

/// Fires latency probes on a loop while another request is in flight, so the
/// download/upload phases report latency under load rather than at idle.
class _ConcurrentPinger {
  final Future<double?> Function() _probe;
  final Duration _interval;
  final List<double> _samples = [];
  int _failures = 0;
  bool _stopped = false;
  Future<void>? _task;

  _ConcurrentPinger(this._probe, this._interval);

  void start() => _task = _loop();

  Future<void> _loop() async {
    while (!_stopped) {
      final value = await _probe();
      if (_stopped) break;
      if (value == null) {
        _failures++;
      } else {
        _samples.add(value);
      }
      await Future.delayed(_interval);
    }
  }

  Future<PingStats> stop() async {
    _stopped = true;
    await _task;
    return PingStats.from(_samples, _failures);
  }
}

/// ---------------------------------------------------------------------------
/// Global state
/// ---------------------------------------------------------------------------

/// The diagnostic tool plus the app-wide connection health it broadcasts.
///
/// Registered once in `main.dart` as a `ChangeNotifierProvider`, so any widget
/// can call `context.watch<NetworkDiagnosticState>().tier` and adapt itself.
class NetworkDiagnosticState extends ChangeNotifier {
  final http.Client _client = http.Client();
  final Random _random = Random();

  Timer? _autoTimer;
  bool _disposed = false;

  bool _isRunning = false;
  bool _autoTestEnabled = true;
  DiagnosticPhase _phase = DiagnosticPhase.idle;
  double _phaseProgress = 0;

  DiagnosticSnapshot? _latest;
  final List<DiagnosticSnapshot> _history = [];

  // --- Public surface -------------------------------------------------------

  bool get isRunning => _isRunning;
  bool get autoTestEnabled => _autoTestEnabled;
  DiagnosticPhase get phase => _phase;
  double get phaseProgress => _phaseProgress;
  DiagnosticSnapshot? get latest => _latest;
  List<DiagnosticSnapshot> get history => List.unmodifiable(_history.reversed);

  /// The categorised health broadcast to the rest of the app.
  ConnectionTier get tier => _latest?.tier ?? ConnectionTier.unknown;

  
  MediaQuality get mediaQuality {
    switch (tier) {
      case ConnectionTier.excellent:
        return MediaQuality.full;
      case ConnectionTier.fair:
        return MediaQuality.reduced;
      case ConnectionTier.poor:
      case ConnectionTier.degraded:
        return MediaQuality.placeholder;
      case ConnectionTier.unknown:
        // Be conservative until the first test lands.
        return MediaQuality.reduced;
    }
  }

  /// Starts the tool: one test now, then a repeating test on an interval.
  Future<void> init() async {
    _startAutoTimer();
    await runDiagnostic();
  }

  void setAutoTest(bool enabled) {
    if (_autoTestEnabled == enabled) return;
    _autoTestEnabled = enabled;
    if (enabled) {
      _startAutoTimer();
    } else {
      _autoTimer?.cancel();
      _autoTimer = null;
    }
    _notify();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    if (!_autoTestEnabled) return;
    _autoTimer = Timer.periodic(DiagnosticConfig.autoTestInterval, (_) {
      if (!_isRunning) runDiagnostic();
    });
  }

  // --- The multi-step diagnostic sequence -----------------------------------

  /// Step 1 baseline ping → step 2 download + concurrent ping →
  /// step 3 upload + concurrent ping → step 4 classify.
  Future<void> runDiagnostic() async {
    if (_isRunning || _disposed) return;
    _isRunning = true;
    _setPhase(DiagnosticPhase.idlePing, 0);

    try {
      // Step 1 — baseline (idle) latency, jitter and packet loss.
      final idle = await _measureIdlePing();

      // A total failure here means there is no usable link at all.
      if (idle.received == 0) {
        _commit(DiagnosticSnapshot.failure(
          'No response from the test server. The connection looks unavailable.',
        ));
        return;
      }

      // Step 2 — download bandwidth while latency is probed under load.
      _setPhase(DiagnosticPhase.download, 0);
      final downloadPinger =
          _ConcurrentPinger(_singlePing, DiagnosticConfig.probeInterval)..start();
      TransferResult download;
      PingStats downloadPing;
      try {
        download = await _measureDownload(DiagnosticConfig.initialDownloadBytes);
        // Fast links finish the small payload before the measurement is
        // meaningful, so scale up once and re-measure.
        if (download.seconds < 1.5 &&
            download.bytes < DiagnosticConfig.maxDownloadBytes) {
          download = await _measureDownload(DiagnosticConfig.maxDownloadBytes);
        }
      } finally {
        // The probe loop is stopped even if the transfer threw, so it can
        // never outlive the phase that started it.
        downloadPing = await downloadPinger.stop();
      }

      // Step 3 — upload bandwidth with the upload's own latency tracked.
      _setPhase(DiagnosticPhase.upload, 0);
      final uploadPinger =
          _ConcurrentPinger(_singlePing, DiagnosticConfig.probeInterval)..start();
      TransferResult upload;
      PingStats uploadPing;
      try {
        upload = await _measureUpload(DiagnosticConfig.uploadBytes, idle.avgMs);
      } finally {
        uploadPing = await uploadPinger.stop();
      }

      // Step 4 — group the results into an operational tier.
      _setPhase(DiagnosticPhase.analyzing, 1);
      final snapshot = DiagnosticSnapshot(
        timestamp: DateTime.now(),
        idlePing: idle,
        downloadPing: downloadPing,
        uploadPing: uploadPing,
        download: download,
        upload: upload,
        tier: ConnectionTier.unknown,
      );
      _commit(snapshot.copyWithTier(classify(snapshot)));
    } on TimeoutException {
      _commit(DiagnosticSnapshot.failure(
        'The test timed out. The connection is too slow to measure.',
      ));
    } catch (e) {
      _commit(DiagnosticSnapshot.failure('Test failed: $e'));
    } finally {
      _isRunning = false;
      _setPhase(DiagnosticPhase.idle, 0);
    }
  }

  // --- Threshold logic ------------------------------------------------------

  /// Groups a completed run into an operational tier.
  ///
  /// Reliability is checked before speed: loss and latency make a link unusable
  /// regardless of how many Mbps it can push.
  static ConnectionTier classify(DiagnosticSnapshot s) {
    final loss = s.worstLossPercent;
    final latency = max(s.idlePing.avgMs, s.downloadPing.avgMs);

    if (loss >= DiagnosticConfig.degradedLossPercent ||
        latency >= DiagnosticConfig.degradedLatencyMs ||
        s.bufferbloatMs >= DiagnosticConfig.degradedBufferbloatMs) {
      return ConnectionTier.degraded;
    }
    if (s.download.mbps <= 0) return ConnectionTier.degraded;
    if (s.download.mbps > DiagnosticConfig.excellentMbps) {
      return ConnectionTier.excellent;
    }
    if (s.download.mbps >= DiagnosticConfig.fairMbps) return ConnectionTier.fair;
    return ConnectionTier.poor;
  }

  static String tierLabel(ConnectionTier tier) {
    switch (tier) {
      case ConnectionTier.excellent:
        return 'Excellent';
      case ConnectionTier.fair:
        return 'Fair';
      case ConnectionTier.poor:
        return 'Poor';
      case ConnectionTier.degraded:
        return 'Degraded';
      case ConnectionTier.unknown:
        return 'Not measured';
    }
  }

  static String tierDescription(ConnectionTier tier) {
    switch (tier) {
      case ConnectionTier.excellent:
        return 'Above 10 Mbps with stable latency. Full-resolution media is on.';
      case ConnectionTier.fair:
        return '2–10 Mbps. Images load at reduced resolution to keep the app responsive.';
      case ConnectionTier.poor:
        return 'Under 2 Mbps. Media is replaced with lightweight placeholders.';
      case ConnectionTier.degraded:
        return 'Heavy packet loss or extreme latency. Downloads are paused and placeholders are shown.';
      case ConnectionTier.unknown:
        return 'Run a diagnostic to measure this connection.';
    }
  }

  static String phaseLabel(DiagnosticPhase phase) {
    switch (phase) {
      case DiagnosticPhase.idle:
        return 'Ready';
      case DiagnosticPhase.idlePing:
        return 'Measuring baseline ping';
      case DiagnosticPhase.download:
        return 'Measuring download speed and ping';
      case DiagnosticPhase.upload:
        return 'Measuring upload speed and ping';
      case DiagnosticPhase.analyzing:
        return 'Analysing results';
    }
  }

  // --- Measurement primitives ----------------------------------------------

  /// One latency sample. Returns null when the probe fails (counted as loss).
  Future<double?> _singlePing() async {
    final watch = Stopwatch()..start();
    try {
      final request = http.Request('GET', Uri.parse(DiagnosticConfig.pingUrl));
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 5));
      await response.stream.drain();
      watch.stop();
      if (response.statusCode >= 400) return null;
      return watch.elapsedMicroseconds / 1000.0;
    } catch (_) {
      return null;
    }
  }

  Future<PingStats> _measureIdlePing() async {
    final samples = <double>[];
    int failures = 0;

    for (int i = 0; i < DiagnosticConfig.idlePingSamples; i++) {
      final value = await _singlePing();
      if (value == null) {
        failures++;
      } else {
        samples.add(value);
      }
      _setPhase(
        DiagnosticPhase.idlePing,
        (i + 1) / DiagnosticConfig.idlePingSamples,
      );
      await Future.delayed(const Duration(milliseconds: 150));
    }
    return PingStats.from(samples, failures);
  }

  /// Streams a fixed payload and times it from first byte to last, so DNS and
  /// TLS setup don't depress the throughput figure.
  Future<TransferResult> _measureDownload(int bytes) async {
    final uri = Uri.parse('${DiagnosticConfig.downloadUrlBase}$bytes');
    final request = http.Request('GET', uri);
    final watch = Stopwatch();
    int received = 0;

    try {
      final response =
          await _client.send(request).timeout(DiagnosticConfig.requestTimeout);
      if (response.statusCode >= 400) return TransferResult.failed;

      await for (final chunk
          in response.stream.timeout(DiagnosticConfig.requestTimeout)) {
        if (!watch.isRunning) watch.start();
        received += chunk.length;
        _setPhase(DiagnosticPhase.download, (received / bytes).clamp(0.0, 1.0));
      }
      watch.stop();
    } on TimeoutException {
      watch.stop();
      // A timeout still tells us something: whatever arrived, arrived slowly.
      if (received == 0) return TransferResult.failed;
    }

    final seconds = watch.elapsedMicroseconds / 1000000.0;
    if (seconds <= 0 || received == 0) return TransferResult.failed;

    return TransferResult(
      mbps: (received * 8) / seconds / 1000000.0,
      seconds: seconds,
      bytes: received,
    );
  }

  /// Posts an incompressible payload. The round trip includes one latency
  /// hop, so the baseline RTT is subtracted before computing throughput.
  Future<TransferResult> _measureUpload(int bytes, double baselineMs) async {
    final payload = _randomPayload(bytes);
    final watch = Stopwatch()..start();

    try {
      final response = await _client
          .post(
            Uri.parse(DiagnosticConfig.uploadUrl),
            headers: const {'Content-Type': 'application/octet-stream'},
            body: payload,
          )
          .timeout(DiagnosticConfig.requestTimeout);
      watch.stop();
      if (response.statusCode >= 400) return TransferResult.failed;
    } on TimeoutException {
      return TransferResult.failed;
    } catch (_) {
      return TransferResult.failed;
    }

    final seconds =
        max(0.001, (watch.elapsedMicroseconds / 1000000.0) - (baselineMs / 1000.0));

    _setPhase(DiagnosticPhase.upload, 1);
    return TransferResult(
      mbps: (bytes * 8) / seconds / 1000000.0,
      seconds: seconds,
      bytes: bytes,
    );
  }

  /// Random bytes, so proxies and compression can't inflate the result.
  Uint8List _randomPayload(int bytes) {
    final data = Uint8List(bytes);
    for (int i = 0; i < bytes; i++) {
      data[i] = _random.nextInt(256);
    }
    return data;
  }

  // --- Plumbing -------------------------------------------------------------

  void _commit(DiagnosticSnapshot snapshot) {
    _latest = snapshot;
    _history.add(snapshot);
    if (_history.length > 20) _history.removeAt(0);
    _notify();
  }

  void _setPhase(DiagnosticPhase phase, double progress) {
    _phase = phase;
    _phaseProgress = progress.clamp(0.0, 1.0);
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoTimer?.cancel();
    _client.close();
    super.dispose();
  }
}