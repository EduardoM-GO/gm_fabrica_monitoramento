import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Primary industrial palette
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceElevated = Color(0xFF334155); // Slate 700
  static const Color surfaceBorder = Color(0xFF475569); // Slate 600

  // Accent and status colors
  static const Color primaryBlue = Color(0xFF38BDF8); // Sky 400
  static const Color primaryBlueDark = Color(0xFF0284C7); // Sky 600
  static const Color successGreen = Color(0xFF22C55E); // Green 500
  static const Color warningAmber = Color(0xFFF59E0B); // Amber 500
  static const Color dangerRed = Color(0xFFEF4444); // Red 500
  static const Color eggOrange = Color(0xFFF97316); // Orange 500
  static const Color purpleAccent = Color(0xFFA855F7); // Purple 500

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: eggOrange,
        surface: surface,
        surfaceContainerLowest: Color(0xFF0A0F1D),
        surfaceContainerLow: Color(0xFF131D31),
        surfaceContainer: Color(0xFF1E293B),
        surfaceContainerHigh: Color(0xFF27354A),
        surfaceContainerHighest: Color(0xFF334155),
        outline: surfaceBorder,
        outlineVariant: Color(0xFF2D3C52),
        error: dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D3C52), width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
