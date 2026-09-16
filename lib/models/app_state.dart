import 'package:flutter/material.dart';

/// Global application state managed via Provider.
///
/// Currently tracks the app-wide theme mode (light / dark) so that
/// toggling Dark Mode in Settings updates the entire application,
/// including the Home Dashboard and all other screens.
class AppState extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Toggles between Light Mode and Dark Mode and notifies all listeners
  /// so the entire app rebuilds with the new theme.
  void toggleDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }
}