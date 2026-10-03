import 'package:flutter/material.dart';

/// Keeps readable line lengths on large windows while using the full width on
/// phones and small tablets.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsivePage({super.key, required this.child, this.maxWidth = 1100});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
