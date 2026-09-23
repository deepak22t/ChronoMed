import 'package:flutter/material.dart';

/// ChronoMed Design System
///
/// Principles:
/// 1. One primary brand color (Glacial Blue) + neutrals + semantic-only accents.
/// 2. Restrained typography — hierarchy through weight and size, not decoration.
/// 3. Strict 8-point spatial grid.
abstract final class ChronoTheme {
  // ── 1. Obsidian Foundation ─────────────────────────────────────────────────
  static const Color obsidian       = Color(0xFF0C0F15);
  static const Color surface        = Color(0xFF121620);
  static const Color surfaceCard    = Color(0xFF171D2A);
  static const Color surfaceElevated = Color(0xFF1E2536);
  static const Color border         = Color(0xFF263044);
  static const Color borderSubtle   = Color(0xFF1B2232);

  // ── 2. Two-Color Palette ───────────────────────────────────────────────────
  // Primary: Glacial Blue — trust, time, active state
  static const Color primary        = Color(0xFF60A5FA);
  static const Color cyan           = Color(0xFF60A5FA);   // compat alias
  static const Color cyanDim        = Color(0xFF3B82F6);
  static const Color cyanSurface    = Color(0x1F60A5FA);

  // Secondary: Muted Sage — taken, wellness, completion
  static const Color secondary      = Color(0xFF34D399);
  static const Color emerald        = Color(0xFF34D399);   // compat alias
  static const Color emeraldDim     = Color(0xFF10B981);
  static const Color emeraldSurface = Color(0x1F34D399);

  // Safety: Soft Coral Rose — conflicts and clinical warnings ONLY
  static const Color rose           = Color(0xFFFB7185);
  static const Color roseSurface    = Color(0x1AFB7185);

  // Semantic role aliases (used by business logic, do not remove)
  static const Color doseScheduled  = primary;
  static const Color doseTaken      = secondary;
  static const Color doseMissed     = rose;
  static const Color mealWindow     = secondary;
  static const Color sleepZone      = Color(0xFF94A3B8);
  static const Color fastingZone    = rose;

  // ── 3. Typography ─────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF1F5F9);
  static const Color textSecondary  = Color(0xFF94A3B8);
  static const Color textMuted      = Color(0xFF64748B);
  static const Color textDim        = Color(0xFF475569);
  static const String monoFont      = 'JetBrainsMono';

  // ── 4. Spacing & Radius ────────────────────────────────────────────────────
  static const double spaceXSmall   = 4.0;
  static const double spaceSmall    = 8.0;
  static const double spaceMedium   = 12.0;
  static const double spaceDefault  = 16.0;
  static const double spaceLarge    = 24.0;

  static const double radiusSmall   = 8.0;
  static const double radiusDefault = 12.0;
  static const double radiusLarge   = 16.0;
  static const double radiusPill    = 24.0;

  // ── 5. Global Material 3 Theme ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        error: rose,
        surface: surface,
        onPrimary: obsidian,
        onSecondary: obsidian,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusDefault)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusDefault)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: textDim, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge:     TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        titleMedium:    TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge:      TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
        bodyMedium:     TextStyle(color: textSecondary, fontSize: 12.5, height: 1.4),
        bodySmall:      TextStyle(color: textMuted, fontSize: 11, height: 1.3),
        labelLarge:     TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        modalBackgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ── 6. Shared Card Decoration ─────────────────────────────────────────────
  /// Standard card decoration. Used where a container needs a border and
  /// background consistent with the design system.
  static BoxDecoration cardDecoration({
    Color backgroundColor = surfaceCard,
    Color borderColor = border,
    double radius = radiusDefault,
    bool isHighlighted = false,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isHighlighted ? primary.withOpacity(0.5) : borderColor,
        width: 1.0,
      ),
    );
  }
}
