import 'package:flutter/material.dart';

import 'app_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolarOpsApp());
}

class SolarOpsApp extends StatelessWidget {
  const SolarOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: appPurple,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F7F8),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: appPurple,
      brightness: Brightness.dark,
      surface: const Color(0xFF17171A),
    );

    InputDecorationTheme inputs(Color fill) => InputDecorationTheme(
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: appPurple, width: 1.3),
          ),
        );

    return MaterialApp(
      title: 'Solar Ops',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: inputs(const Color(0xFFF3F3F5)),
        navigationBarTheme: const NavigationBarThemeData(height: 72),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF111113),
        inputDecorationTheme: inputs(const Color(0xFF202024)),
        navigationBarTheme: const NavigationBarThemeData(height: 72),
      ),
      home: const SolarOpsRoot(),
    );
  }
}
