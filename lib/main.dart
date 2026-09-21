import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'models/network_minitor_state.dart';
import 'models/network_diagnostic_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LabCompilationApp());
}

class LabCompilationApp extends StatelessWidget {
  const LabCompilationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        // NetworkMonitorState starts listening to the connectivity stream
        // immediately so the dashboard is live the moment the screen opens.
        ChangeNotifierProvider(create: (_) => NetworkMonitorState()..init()),
        // NetworkDiagnosticState runs the speed/ping test on a schedule and
        // broadcasts the resulting connection tier app-wide, so any widget can
        // downgrade itself without knowing how the measurement works.
        ChangeNotifierProvider(create: (_) => NetworkDiagnosticState()..init()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Lab Compilation App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}