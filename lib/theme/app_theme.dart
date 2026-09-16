import 'package:flutter/material.dart';

/// Central design-system colors and ThemeData for the Lab Compilation App.
class AppColors {
  static const Color primaryDeepGreen = Color(0xFF1D6B3A);
  static const Color secondaryGreen = Color(0xFF1D9E75);
  static const Color accentOrange = Color(0xFFD85A30);

  // Light mode
  static const Color lightBackground = Color(0xFFF5F6F7);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1B1D1F);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Dark mode
  static const Color darkBackground = Color(0xFF1A1B1E);
  static const Color darkCard = Color(0xFF2B2D31);
  static const Color darkTextPrimary = Color(0xFFF5F6F7);
  static const Color darkTextSecondary = Color(0xFFA3A7AD);
}

/// 8px spacing system used consistently across the app.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primaryDeepGreen,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryDeepGreen,
        secondary: AppColors.secondaryGreen,
        tertiary: AppColors.accentOrange,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightTextPrimary,
      ),
      cardColor: AppColors.lightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeepGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeepGreen
              : const Color(0xFFD1D5DB),
        ),
      ),
      dividerColor: const Color(0xFFE5E7EB),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryDeepGreen,
      colorScheme: ColorScheme.dark(
        primary: AppColors.secondaryGreen,
        secondary: AppColors.secondaryGreen,
        tertiary: AppColors.accentOrange,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkTextPrimary,
      ),
      cardColor: AppColors.darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondaryGreen
              : const Color(0xFF4B4F55),
        ),
      ),
      dividerColor: const Color(0xFF3A3C40),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineLarge: TextStyle(color: primary, fontSize: 26, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: secondary, fontSize: 13, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}