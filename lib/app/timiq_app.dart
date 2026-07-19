import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../domain/models.dart';
import '../presentation/onboarding_screen.dart';
import '../presentation/shell_screen.dart';
import '../presentation/widgets/timiq_components.dart';

class TimiqApp extends StatelessWidget {
  const TimiqApp({required this.controller, super.key});

  final TimiqController controller;

  ThemeMode _themeMode(TimiqThemeMode mode) {
    switch (mode) {
      case TimiqThemeMode.dark:
        return ThemeMode.dark;
      case TimiqThemeMode.light:
        return ThemeMode.light;
      case TimiqThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TimiqScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'TimIQ',
            debugShowCheckedModeBanner: false,
            theme: TimiqTheme.light(),
            darkTheme: TimiqTheme.dark(),
            themeMode: _themeMode(controller.settings.themeMode),
            home: controller.fatalError == null
                ? controller.settings.onboardingCompleted
                    ? const TimiqShell()
                    : const OnboardingScreen()
                : _FatalScreen(message: controller.fatalError!),
          );
        },
      ),
    );
  }
}

class _FatalScreen extends StatelessWidget {
  const _FatalScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TimiqSpace.lg),
            child: TimiqEmptyState(
              icon: Icons.shield_outlined,
              title: 'Data zůstala v bezpečí',
              message:
                  '$message\n\nZkuste aplikaci znovu otevřít. Pokud problém '
                  'přetrvá, nevynucujte mazání dat aplikace.',
            ),
          ),
        ),
      ),
    );
  }
}
