import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActivityOneScreen extends StatefulWidget {
  const ActivityOneScreen({super.key});

  @override
  State<ActivityOneScreen> createState() => _ActivityOneScreenState();
}

class _ActivityOneScreenState extends State<ActivityOneScreen> {
  // Local StatefulWidget state demonstrating an interaction counter.
  int _counter = 0;

  void _increase() => setState(() => _counter++);
  void _reset() => setState(() => _counter = 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity 1'),
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
              // Activity information
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.primaryDeepGreen,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text('Mobile Computing', style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'Introduction to mobile application development',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Information card
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
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.secondaryGreen, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('About this activity', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This activity introduces the fundamentals of mobile computing '
                      'and application development using Flutter, including widget '
                      'composition, state management, and responsive UI design.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Interactive demonstration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                  children: [
                    Text('Interaction Counter', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '$_counter',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 56,
                        color: AppColors.primaryDeepGreen,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _increase,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Increase'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppColors.accentOrange,
                              side: const BorderSide(color: AppColors.accentOrange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}