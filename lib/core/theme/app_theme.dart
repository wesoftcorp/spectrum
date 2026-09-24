import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apertix design token palette.
abstract final class ApertixColors {
  // Primary — Electric Violet & Cyber Cyan
  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFFA29BFE);
  static const cyanAccent = Color(0xFF00F2FE);
  static const cyanGlow = Color(0xFF4FACFE);

  // Secondary — Emerald & Mint
  static const secondary = Color(0xFF00FFA3);
  static const secondaryLight = Color(0xFF55EFC4);

  // Accent & Alerts
  static const accent = Color(0xFFFF5E7E);
  static const warning = Color(0xFFFFB800);
  static const error = Color(0xFFFF4757);
  static const success = Color(0xFF00FFA3);
  static const info = Color(0xFF00D2D3);

  // Dark Studio palette (Obsidian & Nordic Frost)
  static const darkBackground = Color(0xFF090A0F);
  static const darkSurface = Color(0xFF10131E);
  static const darkSurfaceElevated = Color(0xFF171A2B);
  static const darkCard = Color(0xFF151928);
  static const darkBorder = Color(0xFF22283E);
  static const darkBorderGlow = Color(0x3300F2FE);
  static const darkTextPrimary = Color(0xFFF1F3F9);
  static const darkTextSecondary = Color(0xFF8F99B0);
  static const darkTextMuted = Color(0xFF5C6479);

  // Light Studio palette
  static const lightBackground = Color(0xFFF6F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFEDF2F7);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightTextPrimary = Color(0xFF1A202C);
  static const lightTextSecondary = Color(0xFF64748B);
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
          isDark ? const Color(0xFF28254A) : const Color(0xFFEDE9FF),
      onPrimaryContainer:
          isDark ? ApertixColors.primaryLight : ApertixColors.primary,
      secondary: ApertixColors.secondary,
      onSecondary: Colors.black,
      secondaryContainer:
          isDark ? const Color(0xFF0A3423) : const Color(0xFFD9F8EF),
      onSecondaryContainer:
          isDark ? ApertixColors.secondaryLight : const Color(0xFF007A55),
      error: ApertixColors.error,
      onError: Colors.white,
      errorContainer:
          isDark ? const Color(0xFF4A1A22) : const Color(0xFFFFE0E0),
      onErrorContainer: isDark ? const Color(0xFFFF8E9B) : ApertixColors.error,
      surface:
          isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
      onSurface:
          isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary,
      onSurfaceVariant: isDark
          ? ApertixColors.darkTextSecondary
          : ApertixColors.lightTextSecondary,
      surfaceContainerHighest:
          isDark ? ApertixColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
      outline: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
      shadow: Colors.black.withValues(alpha: 0.4),
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
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2032),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2C3450), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        waitDuration: const Duration(milliseconds: 500),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ApertixColors.cyanAccent,
        inactiveTrackColor: isDark ? const Color(0xFF20273D) : const Color(0xFFCBD5E1),
        thumbColor: ApertixColors.cyanAccent,
        overlayColor: ApertixColors.cyanAccent.withValues(alpha: 0.15),
        trackHeight: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF1C2237) : ApertixColors.darkSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? const Color(0xFF2E385B) : Colors.transparent,
            width: 1,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
