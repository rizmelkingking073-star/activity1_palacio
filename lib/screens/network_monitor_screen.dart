import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network_minitor_state.dart';
import '../theme/app_theme.dart';
import '../widgets/network_status_banner.dart';
import '../widgets/queued_request_card.dart';

class NetworkMonitorScreen extends StatelessWidget {
  const NetworkMonitorScreen({super.key});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<NetworkMonitorState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity 3'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    color: AppColors.secondaryGreen,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(child: Text('Network Monitor', style: theme.textTheme.headlineMedium)),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Real-time network status (updates via connectivity stream)
              NetworkStatusBanner(status: state.status),

              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Requests', style: theme.textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: state.requests.any((r) => r.status == RequestStatus.completed)
                        ? state.clearCompleted
                        : null,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear completed'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => state.startSimulatedRequest(),
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: const Text('Simulate Large Data Fetch'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (state.requests.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No requests yet. Tap the button above to start one, then toggle '
                      'Wi-Fi off to simulate a handover and watch it queue and recover.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...state.requests.reversed.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: QueuedRequestCard(request: r),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),
              Text('Connection Log', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Container(
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
                child: state.log.isEmpty
                    ? Text('No events yet.', style: theme.textTheme.bodyMedium)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.log.take(10).map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${_formatTime(entry.time)}  •  ${entry.message}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
