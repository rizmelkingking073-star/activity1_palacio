import 'package:flutter/material.dart';

class MeshConsoleColors {
  static const background = Color(0xFF101814);
  static const panel = Color(0xFF18231C);
  static const gridLine = Color(0xFF34483A);
  static const signalGreen = Color(0xFF7CDB91);
  static const staticAmber = Color(0xFFE4B65B);
  static const alertRed = Color(0xFFE87878);
  static const fog = Color(0xFF91A196);
  static const textPrimary = Color(0xFFE4EEE6);
}

class MeshConsoleTypography {
  static TextStyle mono({Color color = MeshConsoleColors.textPrimary, double size = 14, FontWeight weight = FontWeight.normal}) =>
      TextStyle(fontFamily: 'monospace', color: color, fontSize: size, fontWeight: weight);
}
