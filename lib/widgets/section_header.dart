import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable section title used across screens (e.g. "Laboratory Activities",
/// "Appearance").
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}