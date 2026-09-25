import 'package:flutter/material.dart';

import 'api.dart';
import 'app_controller.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'session_store.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolarOpsApp());
}

class SolarOpsApp extends StatefulWidget {
  const SolarOpsApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<SolarOpsApp> createState() => _SolarOpsAppState();
}

class _SolarOpsAppState extends State<SolarOpsApp> {
  late final AppController _controller;
  late final bool _ownsController;
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        AppController(
          api: OpsApiClient(),
          sessionStore: SecureSessionStore(),
        );
    _controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() => setState(() => _dark = !_dark);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Solar Ops',
          themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: _body(),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: brightness == Brightness.light
          ? const Color(0xFFF8F9FC)
          : const Color(0xFF111318),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (!_controller.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_controller.authenticated) {
      return LoginScreen(
        controller: _controller,
        isDark: _dark,
        onToggleTheme: _toggleTheme,
      );
    }

    if (_controller.data == null) {
      return _LoadFailure(
        controller: _controller,
        isDark: _dark,
        onToggleTheme: _toggleTheme,
      );
    }

    return HomeShell(
      controller: _controller,
      isDark: _dark,
      onToggleTheme: _toggleTheme,
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({
    required this.controller,
    required this.isDark,
    required this.onToggleTheme,
  });

  final AppController controller;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load operations data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.error ??
                        'Check the network connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        controller.loading ? null : controller.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.logout,
                    child: const Text('Sign out'),
                  ),
                  IconButton(
                    tooltip: 'Change theme',
                    onPressed: onToggleTheme,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
