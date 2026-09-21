import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/network_diagnostic_state.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_media.dart';
import '../widgets/connection_health_banner.dart';
import '../widgets/metric_tile.dart';

/// Activity 4 — the diagnostic dashboard.
///
/// Shows the live results of the multi-step test (baseline ping → download +
/// ping → upload + ping), the tier those results map to, and a media area that
/// visibly adapts to that tier.
class NetworkDiagnosticScreen extends StatelessWidget {
  const NetworkDiagnosticScreen({super.key});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<NetworkDiagnosticState>();
    final snapshot = state.latest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity 4'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 600 ? 4 : 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: AppColors.primaryDeepGreen,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text('Network Diagnostic',
                        style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      'Measures speed and ping on a schedule, then adapts the '
                      'interface to match.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const ConnectionHealthBanner(),
                  const SizedBox(height: AppSpacing.md),

                  _RunControls(state: state),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Measurements', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _MetricsGrid(snapshot: snapshot, columns: columns),

                  const SizedBox(height: AppSpacing.lg),
                  Text('Adaptive content', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'These cards follow the tier above: full images on an '
                    'excellent link, smaller images on a fair one, and local '
                    'placeholders when the link is poor or degraded.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AdaptiveMedia(
                    caption: 'Campus network map',
                    fullResUrl: 'https://picsum.photos/seed/labnet/1600/900',
                    lowResUrl: 'https://picsum.photos/seed/labnet/480/270',
                    placeholderIcon: Icons.map_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AdaptiveMedia(
                    caption: 'Lab session recording',
                    fullResUrl: 'https://picsum.photos/seed/labvideo/1600/900',
                    lowResUrl: 'https://picsum.photos/seed/labvideo/480/270',
                    placeholderIcon: Icons.play_circle_outline_rounded,
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Text('Test history', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _HistoryPanel(
                    state: state,
                    formatTime: _formatTime,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RunControls extends StatelessWidget {
  final NetworkDiagnosticState state;

  const _RunControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  NetworkDiagnosticState.phaseLabel(state.phase),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (state.isRunning)
                Text(
                  '${(state.phaseProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.isRunning ? state.phaseProgress : 0,
              minHeight: 8,
              backgroundColor:
                  isDark ? const Color(0xFF3A3C40) : const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.secondaryGreen),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isRunning ? null : state.runDiagnostic,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(state.isRunning ? 'Test running' : 'Run test now'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test automatically',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Repeats every '
                      '${DiagnosticConfig.autoTestInterval.inSeconds} seconds '
                      'in the background.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.autoTestEnabled,
                onChanged: (value) =>
                    context.read<NetworkDiagnosticState>().setAutoTest(value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final DiagnosticSnapshot? snapshot;
  final int columns;

  const _MetricsGrid({required this.snapshot, required this.columns});

  String _n(double value, {int digits = 1}) =>
      value <= 0 ? '—' : value.toStringAsFixed(digits);

  @override
  Widget build(BuildContext context) {
    final s = snapshot;

    final tiles = <Widget>[
      MetricTile(
        label: 'Download',
        value: s == null ? '—' : _n(s.download.mbps, digits: 2),
        unit: 'Mbps',
        icon: Icons.download_rounded,
        color: AppColors.primaryDeepGreen,
      ),
      MetricTile(
        label: 'Upload',
        value: s == null ? '—' : _n(s.upload.mbps, digits: 2),
        unit: 'Mbps',
        icon: Icons.upload_rounded,
        color: AppColors.secondaryGreen,
      ),
      MetricTile(
        label: 'Idle ping',
        value: s == null ? '—' : _n(s.idlePing.avgMs, digits: 0),
        unit: 'ms',
        icon: Icons.timer_outlined,
        color: AppColors.secondaryGreen,
      ),
      MetricTile(
        label: 'Jitter',
        value: s == null ? '—' : _n(s.idlePing.jitterMs, digits: 0),
        unit: 'ms',
        icon: Icons.show_chart_rounded,
        color: AppColors.accentOrange,
      ),
      MetricTile(
        label: 'Ping while downloading',
        value: s == null ? '—' : _n(s.downloadPing.avgMs, digits: 0),
        unit: 'ms',
        icon: Icons.south_rounded,
        color: AppColors.primaryDeepGreen,
      ),
      MetricTile(
        label: 'Ping while uploading',
        value: s == null ? '—' : _n(s.uploadPing.avgMs, digits: 0),
        unit: 'ms',
        icon: Icons.north_rounded,
        color: AppColors.secondaryGreen,
      ),
      MetricTile(
        label: 'Latency under load',
        value: s == null ? '—' : _n(s.bufferbloatMs, digits: 0),
        unit: 'ms added',
        icon: Icons.waves_rounded,
        color: AppColors.accentOrange,
      ),
      MetricTile(
        label: 'Packet loss',
        value: s == null ? '—' : s.worstLossPercent.toStringAsFixed(0),
        unit: '%',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFB3261E),
      ),
    ];

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.35,
      children: tiles,
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final NetworkDiagnosticState state;
  final String Function(DateTime) formatTime;

  const _HistoryPanel({required this.state, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final history = state.history;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: history.isEmpty
          ? Text(
              'No tests yet. Run one to see how this connection behaves.',
              style: theme.textTheme.bodyMedium,
            )
          : Column(
              children: history.take(8).map((s) {
                final color = ConnectionHealthBanner.colorFor(s.tier);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 64,
                        child: Text(formatTime(s.timestamp),
                            style: theme.textTheme.bodyMedium),
                      ),
                      Expanded(
                        child: Text(
                          s.error ??
                              '${s.download.mbps.toStringAsFixed(1)} Mbps down · '
                                  '${s.idlePing.avgMs.toStringAsFixed(0)} ms',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        NetworkDiagnosticState.tierLabel(s.tier),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
