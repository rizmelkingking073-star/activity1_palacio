import 'package:flutter/material.dart';
import '../models/network_minitor_state.dart';
import '../theme/app_theme.dart';

/// Displays one simulated data request: its name, status badge (in
/// progress / queued-waiting-for-connection / completed), and a progress
/// bar showing chunks transferred so far.
class QueuedRequestCard extends StatelessWidget {
  final QueuedRequest request;

  const QueuedRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    late final Color badgeColor;
    late final String badgeText;
    late final IconData badgeIcon;

    switch (request.status) {
      case RequestStatus.inProgress:
        badgeColor = AppColors.secondaryGreen;
        badgeText = 'In Progress';
        badgeIcon = Icons.sync_rounded;
        break;
      case RequestStatus.queued:
        badgeColor = AppColors.accentOrange;
        badgeText = 'Queued — waiting for connection';
        badgeIcon = Icons.pause_circle_outline_rounded;
        break;
      case RequestStatus.completed:
        badgeColor = AppColors.primaryDeepGreen;
        badgeText = 'Completed';
        badgeIcon = Icons.check_circle_rounded;
        break;
    }

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
          Text(request.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(badgeIcon, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  badgeText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: request.progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF3A3C40) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(badgeColor),
            ),
          ),
          const SizedBox(height: 4),
          Text('${request.completedChunks}/${request.totalChunks} chunks',
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
