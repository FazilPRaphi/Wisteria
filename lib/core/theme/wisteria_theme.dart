import 'package:flutter/material.dart';

/// Wisteria Design System
///
/// Premium dark clinical AI workstation theme.
/// Deep dark backgrounds, indigo/violet accents,
/// layered surfaces, crisp typography.
class WisteriaColors {
  WisteriaColors._();

  // ── Background layers ──
  static const Color background = Color(0xFF0F0D1A);
  static const Color surfaceLowest = Color(0xFF0E0C19);
  static const Color surfaceLow = Color(0xFF1A1726);
  static const Color surface = Color(0xFF1C1A27);
  static const Color surfaceContainer = Color(0xFF201E2C);
  static const Color surfaceHigh = Color(0xFF2B2836);
  static const Color surfaceHighest = Color(0xFF363342);

  // ── Accent colors ──
  static const Color primary = Color(0xFF818CF8);
  static const Color primaryMuted = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF6D28D9);
  static const Color tertiary = Color(0xFFA78BFA);
  static const Color primaryContainer = Color(0xFF2F3AA3);

  // ── Text colors ──
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFF8FAFC);

  // ── Border colors ──
  static const Color border = Color(0xFF2E2A42);
  static const Color borderSubtle = Color(0xFF242038);
  static const Color borderFocus = Color(0xFF818CF8);

  // ── Semantic colors ──
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // ── Gradient presets ──
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1B30),
      Color(0xFF1A1726),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1),
      Color(0xFF818CF8),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1040),
      Color(0xFF251A4A),
      Color(0xFF1A1726),
    ],
  );
}

class WisteriaSpacing {
  WisteriaSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double section = 40;
  static const double page = 48;
}

class WisteriaRadius {
  WisteriaRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999;
}

class WisteriaElevation {
  WisteriaElevation._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get low => [
        BoxShadow(
          blurRadius: 8,
          offset: const Offset(0, 2),
          color: Colors.black.withValues(alpha: 0.20),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          blurRadius: 16,
          offset: const Offset(0, 4),
          color: Colors.black.withValues(alpha: 0.25),
        ),
      ];

  static List<BoxShadow> get high => [
        BoxShadow(
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
          color: Colors.black.withValues(alpha: 0.35),
        ),
      ];

  static List<BoxShadow> accentGlow(Color color) => [
        BoxShadow(
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
          color: color.withValues(alpha: 0.18),
        ),
      ];
}

ThemeData buildWisteriaTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',

    // ── Color Scheme ──
    colorScheme: const ColorScheme.dark(
      surface: WisteriaColors.surface,
      primary: WisteriaColors.primary,
      primaryContainer: WisteriaColors.primaryContainer,
      secondary: WisteriaColors.secondary,
      tertiary: WisteriaColors.tertiary,
      error: WisteriaColors.error,
      onPrimary: WisteriaColors.textOnPrimary,
      onSurface: WisteriaColors.textPrimary,
      onSurfaceVariant: WisteriaColors.textSecondary,
      outline: WisteriaColors.border,
      outlineVariant: WisteriaColors.borderSubtle,
      surfaceContainerLowest: WisteriaColors.surfaceLowest,
      surfaceContainerLow: WisteriaColors.surfaceLow,
      surfaceContainer: WisteriaColors.surfaceContainer,
      surfaceContainerHigh: WisteriaColors.surfaceHigh,
      surfaceContainerHighest: WisteriaColors.surfaceHighest,
    ),

    scaffoldBackgroundColor: WisteriaColors.background,

    // ── AppBar ──
    appBarTheme: const AppBarTheme(
      backgroundColor: WisteriaColors.background,
      foregroundColor: WisteriaColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: WisteriaColors.textPrimary,
        letterSpacing: -0.3,
      ),
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      color: WisteriaColors.surfaceLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        side: const BorderSide(color: WisteriaColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: WisteriaColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.xl),
        side: const BorderSide(color: WisteriaColors.border, width: 1),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: WisteriaColors.textPrimary,
      ),
    ),

    // ── Input ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WisteriaColors.surfaceLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
        borderSide: const BorderSide(color: WisteriaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
        borderSide: const BorderSide(color: WisteriaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
        borderSide: const BorderSide(
          color: WisteriaColors.primary,
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: WisteriaColors.textSecondary,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: WisteriaColors.textMuted,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    // ── Buttons ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WisteriaColors.primaryMuted,
        foregroundColor: WisteriaColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WisteriaRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WisteriaColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WisteriaRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // ── FAB ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: WisteriaColors.primaryMuted,
      foregroundColor: WisteriaColors.textOnPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
      ),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WisteriaColors.surfaceHigh,
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        color: WisteriaColors.textPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: WisteriaColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── ListTile ──
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // ── Text ──
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: WisteriaColors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: WisteriaColors.textPrimary,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: WisteriaColors.textPrimary,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: WisteriaColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: WisteriaColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: WisteriaColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: WisteriaColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: WisteriaColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: WisteriaColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: WisteriaColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WisteriaColors.textPrimary,
        letterSpacing: 0.3,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: WisteriaColors.textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: WisteriaColors.textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );
}
