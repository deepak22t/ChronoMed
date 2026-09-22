import 'package:flutter/material.dart';

/// ChronoMed Production Design System — Phase 1 Normalization
///
/// Principles:
/// 1. Strict 2-Color Palette: Precision Medical Cyan (Primary Accent) +
///    Clinical Mint/Emerald (Secondary/Confirmation Accent) on a Deep Obsidian base.
/// 2. Zero AI Rainbow Glitz: Muted, high-contrast, clinical dark mode.
/// 3. Strict 8-Point Spatial Hierarchy & Symmetrical Padding.
abstract final class ChronoTheme {
  // ── 1. Monochromatic Neutral Foundation ──────────────────────────────────
  static const Color obsidian = Color(0xFF090A0F);        // Primary app background
  static const Color surface = Color(0xFF0F131C);         // Headers, bars, rails
  static const Color surfaceCard = Color(0xFF141A26);     // Cards, containers
  static const Color surfaceElevated = Color(0xFF1C2436); // Modals, inputs, active tabs
  static const Color border = Color(0xFF222B3D);          // 1px hairline border
  static const Color borderSubtle = Color(0xFF19202E);    // Secondary dividers

  // ── 2. Strict 2-Color Palette (Primary + Confirmation) ───────────────────
  // Color 1: Precision Medical Cyan (Brand, Actions, Active State, Time badges)
  static const Color cyan = Color(0xFF22D3EE);
  static const Color cyanDim = Color(0xFF0891B2);
  static const Color cyanSurface = Color(0x1A22D3EE);     // 10% opacity

  // Color 2: Clinical Emerald / Mint (Confirmed, Taken Doses, Adherence)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDim = Color(0xFF047857);
  static const Color emeraldSurface = Color(0x1A10B981);  // 10% opacity

  // Guardrail Tone: Soft Rose (Strictly reserved for clinical infeasibility/conflict alerts)
  static const Color rose = Color(0xFFF43F5E);
  static const Color roseSurface = Color(0x1AF43F5E);

  // Backward-compatibility aliases mapped strictly to neutral/primary tokens
  static const Color amber = Color(0xFF22D3EE);           // Mapped to Cyan (no more jarring yellow)
  static const Color violet = Color(0xFF94A3B8);          // Mapped to cool Slate
  static const Color doseScheduled = cyan;
  static const Color doseTaken = emerald;
  static const Color doseMissed = rose;
  static const Color mealWindow = emerald;
  static const Color sleepZone = Color(0xFF94A3B8);
  static const Color fastingZone = rose;

  // ── 3. High-Contrast Typography Palette ───────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);     // 98% brightness
  static const Color textSecondary = Color(0xFF94A3B8);   // Cool slate body
  static const Color textMuted = Color(0xFF64748B);       // Subtitle / Eyebrow
  static const Color textDim = Color(0xFF475569);         // Inactive / Disabled
  static const String monoFont = 'JetBrainsMono';

  // ── 4. Spatial Geometry & Symmetrical Spacing ─────────────────────────────
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 12.0;
  static const double spaceDefault = 16.0;
  static const double spaceLarge = 24.0;

  static const double radiusSmall = 8.0;
  static const double radiusDefault = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusPill = 24.0;

  // ── 5. Global Material 3 Theme Data ───────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: emerald,
        error: rose,
        surface: surface,
        onPrimary: obsidian,
        onSecondary: obsidian,
        onSurface: textPrimary,
      ),
      // App Bar
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
      // Cards
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      // Primary Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusDefault)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusDefault)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      // Form Input Fields
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
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: textDim, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      // Dividers
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 12.5, height: 1.4),
        bodySmall: TextStyle(color: textMuted, fontSize: 11, height: 1.3),
        labelLarge: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        modalBackgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ── 6. Reusable High-Level UI Components ──────────────────────────────────

  /// Standardized clean container decoration with symmetric borders.
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
        color: isHighlighted ? cyan : borderColor,
        width: isHighlighted ? 1.5 : 1.0,
      ),
    );
  }

  /// Minimalist, non-glowing clinical status badge.
  static Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Symmetrical, clean telemetry metric tile.
  static Widget metricTile({
    required String label,
    required String value,
    Color valueColor = textPrimary,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: textMuted),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: monoFont,
            ),
          ),
        ],
      ),
    );
  }
}
