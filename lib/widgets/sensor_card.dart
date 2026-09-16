import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable card displaying an example sensor name, icon, and a
/// local/example status value (no real device sensor data is read).
class SensorCard extends StatelessWidget {
  final String name;
  final String exampleValue;
  final IconData icon;

  const SensorCard({
    super.key,
    required this.name,
    required this.exampleValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondaryGreen, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            exampleValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.accentOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}