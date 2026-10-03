import 'package:flutter/material.dart';
import '../theme/mesh_console_theme.dart';

class ConsoleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final Color activeColor;
  const ConsoleButton({super.key, required this.label, required this.onPressed, this.active = false, this.activeColor = MeshConsoleColors.signalGreen});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(foregroundColor: active ? activeColor : MeshConsoleColors.textPrimary, side: BorderSide(color: active ? activeColor : MeshConsoleColors.gridLine)),
    child: Text(label, style: MeshConsoleTypography.mono(size: 12)),
  );
}
