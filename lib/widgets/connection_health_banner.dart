import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/network_diagnostic_state.dart';
import '../theme/app_theme.dart';

/// Shows the connection tier the diagnostic tool has broadcast to the app.
///
/// Drop it on any screen — it reads [NetworkDiagnosticState] from Provider
/// itself, so no plumbing is needed at the call site. Use [compact] for a
/// single-line chip (e.g. on the Home dashboard).
class ConnectionHealthBanner extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;

  const ConnectionHealthBanner({super.key, this.compact = false, this.onTap});

  static Color colorFor(ConnectionTier tier) {
    switch (tier) {
      case ConnectionTier.excellent:
        return AppColors.primaryDeepGreen;
      case ConnectionTier.fair:
        return AppColors.secondaryGreen;
      case ConnectionTier.poor:
        return AppColors.accentOrange;
      case ConnectionTier.degraded:
        return const Color(0xFFB3261E);
      case ConnectionTier.unknown:
        return AppColors.lightTextSecondary;
    }
  }

  static IconData iconFor(ConnectionTier tier) {
    switch (tier) {
      case ConnectionTier.excellent:
        return Icons.network_check_rounded;
      case ConnectionTier.fair:
        return Icons.network_wifi_3_bar_rounded;
      case ConnectionTier.poor:
        return Icons.network_wifi_1_bar_rounded;
      case ConnectionTier.degraded:
        return Icons.warning_amber_rounded;
      case ConnectionTier.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<NetworkDiagnosticState>();
    final tier = state.tier;
    final color = colorFor(tier);
    final label = NetworkDiagnosticState.tierLabel(tier);

    if (compact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconFor(tier), size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                state.isRunning ? 'Testing connection…' : 'Connection: $label',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = state.latest;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconFor(tier), color: color, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection health', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontSize: 20, color: color),
                    ),
                  ],
                ),
              ),
              if (state.isRunning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            snapshot?.error ?? NetworkDiagnosticState.tierDescription(tier),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}