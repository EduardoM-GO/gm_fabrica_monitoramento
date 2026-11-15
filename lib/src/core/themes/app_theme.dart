import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';

class AppTheme {
  AppTheme._();

  // Superfícies Tonais Cacau Espresso Industrial (Material 3 Dark)
  static const Color background = Color(0xFF120E0C);
  static const Color surfaceContainerLowest = Color(0xFF0D0A08);
  static const Color surfaceContainerLow = Color(0xFF1A1412);
  static const Color surface = Color(0xFF211A17);
  static const Color surfaceElevated = Color(0xFF2B221E);
  static const Color surfaceContainerHighest = Color(0xFF362B26);
  static const Color surfaceBorder = Color(0xFF52433C);
  static const Color outlineVariant = Color(0xFF3D312B);

  // Paleta Cacau, Ouro Nobre & Refrigeração Semântica
  static const Color cocoaGold = Color(0xFFE5B869);
  static const Color cocoaGoldContainer = Color(0xFF4A3614);
  static const Color onCocoaGold = Color(0xFF261904);
  static const Color onCocoaGoldContainer = Color(0xFFFFDEA6);

  static const Color eggOrange = Color(0xFFF59E0B);
  static const Color secondaryContainer = Color(0xFF472D0B);
  static const Color onSecondaryContainer = Color(0xFFFFDDB3);

  // Tokens de Refrigeração / Cristalização (Tertiary) e Status Semântico
  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color primaryBlueDark = Color(0xFF0284C7);
  static const Color coolingContainer = Color(0xFF0C3449);
  static const Color onCoolingContainer = Color(0xFFBFE8FF);

  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF4C1414);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color purpleAccent = Color(0xFFA855F7);

  // Tipografia e Contraste
  static const Color textPrimary = Color(0xFFF7F2EE);
  static const Color textSecondary = Color(0xFFC7B8B0);
  static const Color textMuted = Color(0xFF8C7B72);

  static const String fontHeading = 'Roca One';
  static const String fontBody = 'Geologica';

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: cocoaGold,
      onPrimary: onCocoaGold,
      primaryContainer: cocoaGoldContainer,
      onPrimaryContainer: onCocoaGoldContainer,
      secondary: eggOrange,
      onSecondary: Color(0xFF291800),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: primaryBlue,
      onTertiary: Color(0xFF002638),
      tertiaryContainer: coolingContainer,
      onTertiaryContainer: onCoolingContainer,
      error: dangerRed,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: surfaceBorder,
      outlineVariant: outlineVariant,
    );

    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: fontBody,
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      fontFamily: fontBody,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontFamily: fontHeading,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontFamily: fontHeading,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontFamily: fontHeading,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontFamily: fontHeading,
          fontWeight: FontWeight.w800,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontFamily: fontBody,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: outlineVariant, width: 1.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
          side: const BorderSide(color: surfaceBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(
          fontFamily: fontBody,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
