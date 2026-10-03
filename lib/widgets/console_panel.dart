import 'package:flutter/material.dart';
import '../theme/mesh_console_theme.dart';

class ConsolePanel extends StatelessWidget {
  final Widget child;
  final String? label;
  final EdgeInsetsGeometry padding;
  const ConsolePanel({super.key, required this.child, this.label, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(color: MeshConsoleColors.panel, border: Border.all(color: MeshConsoleColors.gridLine), borderRadius: BorderRadius.circular(8)),
    child: label == null ? child : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(12), child: Text(label!, style: const TextStyle(color: MeshConsoleColors.signalGreen, fontFamily: 'monospace', fontSize: 12))),
      child,
    ]),
  );
}
