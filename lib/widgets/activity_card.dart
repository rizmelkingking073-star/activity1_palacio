import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable card used to represent a single laboratory activity on the
/// Home Dashboard.
class ActivityCard extends StatelessWidget {
  final String activityLabel;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onOpen;

  const ActivityCard({
    super.key,
    required this.activityLabel,
    required this.title,
    required this.description,
    required this.icon,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryDeepGreen, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Open Activity'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}