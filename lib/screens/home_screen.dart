import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_card.dart';
import '../widgets/connection_health_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/bottom_nav.dart';
import 'activity_one_screen.dart';
import 'activity_two_screen.dart';
import 'network_monitor_screen.dart';
import 'network_diagnostic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text('Lab Compilation', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Master Laboratory Activities',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryGreen,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Welcome to your laboratory workspace',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Global connection health, broadcast from the diagnostic
                  // tool. Tapping it opens the full dashboard.
                  ConnectionHealthBanner(
                    compact: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NetworkDiagnosticScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Laboratory Activities section
                  const SectionHeader(title: 'Laboratory Activities'),
                  const SizedBox(height: AppSpacing.sm),

                  ActivityCard(
                    activityLabel: 'ACTIVITY 1',
                    title: 'Mobile Computing',
                    description: 'Introduction to mobile application development',
                    icon: Icons.phone_android_rounded,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActivityOneScreen()),
                    ),
                  ),
                  ActivityCard(
                    activityLabel: 'ACTIVITY 2',
                    title: 'Device Sensors',
                    description: 'Explore mobile sensors and device capabilities',
                    icon: Icons.sensors_rounded,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActivityTwoScreen()),
                    ),
                  ),
                  ActivityCard(
                    activityLabel: 'ACTIVITY 3',
                    title: 'Network Monitor',
                    description: 'Real-time Wi-Fi/Cellular handover and request queuing',
                    icon: Icons.wifi_tethering_rounded,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NetworkMonitorScreen()),
                    ),
                  ),
                  ActivityCard(
                    activityLabel: 'ACTIVITY 4',
                    title: 'Network Diagnostic',
                    description:
                        'Speed and ping tests that adapt the interface to connection health',
                    icon: Icons.speed_rounded,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NetworkDiagnosticScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Status indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.secondaryGreen,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '4 Activities Available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}