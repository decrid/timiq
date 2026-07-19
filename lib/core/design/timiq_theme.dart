import 'dart:ui';

import 'package:flutter/material.dart';

abstract final class TimiqColors {
  static const background = Color(0xFF0B0D14);
  static const surface = Color(0xFF131620);
  static const elevated = Color(0xFF1A1E2B);
  static const primary = Color(0xFF7C6CFF);
  static const primaryGlow = Color(0xFF9A8CFF);
  static const text = Color(0xFFF4F3F8);
  static const muted = Color(0xFF8E92A3);
  static const border = Color(0xFF292D3D);
  static const danger = Color(0xFFFF667D);
  static const success = Color(0xFF4DD6A0);
  static const warning = Color(0xFFFFB454);

  static const lightBackground = Color(0xFFF5F4FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightElevated = Color(0xFFECEAF5);
  static const lightText = Color(0xFF171923);
  static const lightMuted = Color(0xFF686B7A);
  static const lightBorder = Color(0xFFDCD9E8);

  static const categoryPalette = <Color>[
    Color(0xFF4D8DFF),
    Color(0xFFFF9F43),
    Color(0xFF9A8CFF),
    Color(0xFF4DD6A0),
    Color(0xFFFF6FAE),
    Color(0xFF6C7CFF),
    Color(0xFFFFC857),
    Color(0xFF48C6D9),
    Color(0xFFE26DFF),
    Color(0xFF78D45B),
  ];
}

abstract final class TimiqSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class TimiqRadius {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const pill = 999.0;
}

abstract final class TimiqMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 280);
  static const calm = Duration(milliseconds: 900);
}

class TimiqPalette extends ThemeExtension<TimiqPalette> {
  const TimiqPalette({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.primaryGlow,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final Color primaryGlow;

  static const dark = TimiqPalette(
    background: TimiqColors.background,
    surface: TimiqColors.surface,
    elevated: TimiqColors.elevated,
    text: TimiqColors.text,
    muted: TimiqColors.muted,
    border: TimiqColors.border,
    primary: TimiqColors.primary,
    primaryGlow: TimiqColors.primaryGlow,
  );

  static const light = TimiqPalette(
    background: TimiqColors.lightBackground,
    surface: TimiqColors.lightSurface,
    elevated: TimiqColors.lightElevated,
    text: TimiqColors.lightText,
    muted: TimiqColors.lightMuted,
    border: TimiqColors.lightBorder,
    primary: TimiqColors.primary,
    primaryGlow: Color(0xFF6656E8),
  );

  @override
  TimiqPalette copyWith({
    Color? background,
    Color? surface,
    Color? elevated,
    Color? text,
    Color? muted,
    Color? border,
    Color? primary,
    Color? primaryGlow,
  }) {
    return TimiqPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryGlow: primaryGlow ?? this.primaryGlow,
    );
  }

  @override
  TimiqPalette lerp(ThemeExtension<TimiqPalette>? other, double t) {
    if (other is! TimiqPalette) return this;
    return TimiqPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
    );
  }
}

extension TimiqThemeContext on BuildContext {
  TimiqPalette get timiq =>
      Theme.of(this).extension<TimiqPalette>() ?? TimiqPalette.dark;
}

abstract final class TimiqTheme {
  static ThemeData dark() => _build(Brightness.dark, TimiqPalette.dark);
  static ThemeData light() => _build(Brightness.light, TimiqPalette.light);

  static ThemeData _build(Brightness brightness, TimiqPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.primaryGlow,
        onSecondary: Colors.white,
        error: TimiqColors.danger,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.text,
      ),
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: TextStyle(
        fontSize: 48,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
        color: palette.text,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: palette.text,
      ),
      headlineMedium: TextStyle(
        fontSize: 23,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: palette.text,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: palette.text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: palette.text,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: palette.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: palette.text,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: palette.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: palette.text,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: palette.muted,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.text, size: 22),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.muted,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TimiqRadius.small),
          ),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: palette.border,
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          side: BorderSide(color: palette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.border,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TimiqRadius.medium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: palette.text,
          side: BorderSide(color: palette.border),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TimiqRadius.medium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryGlow,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TimiqRadius.small),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.elevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TimiqSpace.md,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          borderSide: const BorderSide(color: TimiqColors.danger),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary.withValues(alpha: 0.55)
              : palette.border,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primaryGlow
              : palette.muted,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.large),
          side: BorderSide(color: palette.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TimiqRadius.large),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.elevated,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          side: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}
