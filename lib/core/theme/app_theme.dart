import 'package:flutter/material.dart';

/// Spectrum / Apertix design token palette — tuned for maximum visual comfort and reduced eye strain.
typedef SpectrumColors = ApertixColors;

abstract final class ApertixColors {
  // Primary — Calming Cobalt-Sapphire Blue
  static const primary = Color(0xFF4F6EF7);
  static const primaryLight = Color(0xFF819AFA);
  static const cyanAccent = Color(0xFF38BDF8); // Calming Sky Azure (non-neon, soft on eyes)
  static const cyanGlow = Color(0xFF60A5FA);

  // Secondary — Soothing Sage & Seafoam Teal
  static const secondary = Color(0xFF2DD4BF);
  static const secondaryLight = Color(0xFF5EEAD4);

  // Accent & Alerts (Soft, balanced hues, zero jarring neon)
  static const accent = Color(0xFFF472B6);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFF87171);
  static const success = Color(0xFF34D399);
  static const info = Color(0xFF38BDF8);

  // Dark Studio palette (Soothing Velvet Slate & Deep Charcoal)
  static const darkBackground = Color(0xFF12141A);
  static const darkSurface = Color(0xFF191D26);
  static const darkSurfaceElevated = Color(0xFF222734);
  static const darkCard = Color(0xFF1D212C);
  static const darkBorder = Color(0xFF2B3242);
  static const darkBorderGlow = Color(0x2638BDF8);
  static const darkTextPrimary = Color(0xFFEBF0F7);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF64748B);

  // Light Studio palette (Soothing Alabaster Mist & Soft Linen)
  static const lightBackground = Color(0xFFF6F8FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFEEF2F7);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E7F0);
  static const lightTextPrimary = Color(0xFF1E293B);
  static const lightTextSecondary = Color(0xFF5A6A85);
  static const lightTextMuted = Color(0xFF8B9CB2);
}

/// Apertix Material 3 theme factory with Glassmorphism & High-Tech styling.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: ApertixColors.primary,
      onPrimary: Colors.white,
      primaryContainer:
          isDark ? const Color(0xFF242E47) : const Color(0xFFE8EEFD),
      onPrimaryContainer:
          isDark ? ApertixColors.primaryLight : ApertixColors.primary,
      secondary: ApertixColors.secondary,
      onSecondary: isDark ? Colors.black87 : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF15332E) : const Color(0xFFE0F7F4),
      onSecondaryContainer:
          isDark ? ApertixColors.secondaryLight : const Color(0xFF0F766E),
      error: ApertixColors.error,
      onError: Colors.white,
      errorContainer:
          isDark ? const Color(0xFF3E1F24) : const Color(0xFFFFECEE),
      onErrorContainer: isDark ? const Color(0xFFFCA5A5) : ApertixColors.error,
      surface:
          isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
      onSurface:
          isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary,
      onSurfaceVariant: isDark
          ? ApertixColors.darkTextSecondary
          : ApertixColors.lightTextSecondary,
      surfaceContainerHighest:
          isDark ? ApertixColors.darkSurfaceElevated : const Color(0xFFEDF2F7),
      outline: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
      shadow: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
      inverseSurface:
          isDark ? ApertixColors.lightSurface : ApertixColors.darkSurface,
      onInverseSurface: isDark
          ? ApertixColors.lightTextPrimary
          : ApertixColors.darkTextPrimary,
    );

    const fontStack = ['Segoe UI', 'Inter', 'Roboto', 'sans-serif'];

    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        letterSpacing: -0.8,
      ),
      displayMedium: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      bodyMedium: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamilyFallback: fontStack,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
        letterSpacing: 0.4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isDark ? ApertixColors.darkBackground : ApertixColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? ApertixColors.darkSurface.withValues(alpha: 0.95) : ApertixColors.lightSurface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      cardTheme: CardThemeData(
        color: isDark ? ApertixColors.darkCard : ApertixColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
            width: 1,
          ),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? ApertixColors.darkSurfaceElevated : ApertixColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? ApertixColors.darkSurfaceElevated : const Color(0xFFEEF2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ApertixColors.primary,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? ApertixColors.darkSurfaceElevated : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? ApertixColors.darkBorder : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        waitDuration: const Duration(milliseconds: 500),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ApertixColors.primary,
        inactiveTrackColor: isDark ? const Color(0xFF283142) : const Color(0xFFCBD5E1),
        thumbColor: ApertixColors.primary,
        overlayColor: ApertixColors.primary.withValues(alpha: 0.15),
        trackHeight: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ApertixColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? ApertixColors.darkSurfaceElevated : ApertixColors.lightTextPrimary,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? ApertixColors.darkBorder : Colors.transparent,
            width: 1,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
