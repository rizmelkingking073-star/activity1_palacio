import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';

class ActivityTwoScreen extends StatelessWidget {
  const ActivityTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Example/local sensor data — not real device sensor readings.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity 2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final crossAxisCount = isWide ? 3 : 2;

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
                        color: AppColors.secondaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: AppColors.secondaryGreen,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text('Device Sensors', style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Available Sensors', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),


                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '',
                    style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SensorData {
  final String name;
  final String exampleValue;
  final IconData icon;

  const _SensorData(this.name, this.exampleValue, this.icon);
}