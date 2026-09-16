import 'package:flutter/material.dart';
import '../models/network_minitor_state.dart';
import '../theme/app_theme.dart';

/// Displays the current active network interface, updating live as the
/// [NetworkMonitorState] connectivity stream emits new values.
class NetworkStatusBanner extends StatelessWidget {
  final NetworkStatus status;

  const NetworkStatusBanner({super.key, required this.status});

  IconData get _icon {
    switch (status) {
      case NetworkStatus.wifi:
        return Icons.wifi_rounded;
      case NetworkStatus.cellular:
        return Icons.signal_cellular_alt_rounded;
      case NetworkStatus.other:
        return Icons.public_rounded;
      case NetworkStatus.offline:
        return Icons.wifi_off_rounded;
    }
  }

  Color get _color {
    switch (status) {
      case NetworkStatus.wifi:
        return AppColors.primaryDeepGreen;
      case NetworkStatus.cellular:
        return AppColors.secondaryGreen;
      case NetworkStatus.other:
        return AppColors.secondaryGreen;
      case NetworkStatus.offline:
        return AppColors.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(_icon, color: _color, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Network', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  NetworkMonitorState.statusLabel(status),
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, color: _color),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
