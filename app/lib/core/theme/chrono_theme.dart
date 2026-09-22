import 'package:flutter/material.dart';

/// ChronoMed Calm Health Design System
///
/// Principles:
/// 1. Zero Eye-Strain: Replaces harsh neon cyan with soothing Soft Glacial Blue (#60A5FA)
///    and Muted Sage (#34D399) over Warm Obsidian Charcoal (#0C0F15).
/// 2. Restorative & Human-Centered: Subtle contrast, warm silk typography, 
///    and zero cartoon emojis.
/// 3. Strict 8-Point Spatial Hierarchy & Symmetrical Padding.
abstract final class ChronoTheme {
  // ── 1. Warm Obsidian Charcoal Foundation (Zero Glare) ─────────────────────
  static const Color obsidian = Color(0xFF0C0F15);        // Deep calming charcoal base
  static const Color surface = Color(0xFF121620);         // Header & bar surfaces
  static const Color surfaceCard = Color(0xFF171D2A);     // Content cards & tiles
  static const Color surfaceElevated = Color(0xFF1E2536); // Modals, inputs, active pills
  static const Color border = Color(0xFF263044);          // Subtle hairline 1px border
  static const Color borderSubtle = Color(0xFF1B2232);    // Low-contrast dividers

  // ── 2. Gentle 2-Color Palette (Calm Primary + Healing Sage) ───────────────
  // Primary Accent: Soft Glacial Blue (Trust, Calm, Time Badges, Active Focus)
  static const Color primary = Color(0xFF60A5FA);
  static const Color cyan = Color(0xFF60A5FA);            // Alias for seamless compatibility
  static const Color cyanDim = Color(0xFF3B82F6);
  static const Color cyanSurface = Color(0x1F60A5FA);     // 12% soft blue wash

  // Secondary Accent: Muted Sage / Herbal Mint (Taken Doses, Wellness, Adherence)
  static const Color secondary = Color(0xFF34D399);
  static const Color emerald = Color(0xFF34D399);         // Alias for seamless compatibility
  static const Color emeraldDim = Color(0xFF10B981);
  static const Color emeraldSurface = Color(0x1F34D399);  // 12% soft sage wash

  // Safety Tone: Soft Coral Rose (Strictly reserved for clinical conflict alerts)
  static const Color rose = Color(0xFFFB7185);
  static const Color roseSurface = Color(0x1AFB7185);

  // Deprecated AI-rainbow aliases mapped to calming neutral/primary tones
  static const Color amber = Color(0xFF60A5FA);           // Mapped to Glacial Blue
  static const Color violet = Color(0xFF94A3B8);          // Mapped to cool Slate
  static const Color doseScheduled = primary;
  static const Color doseTaken = secondary;
  static const Color doseMissed = rose;
  static const Color mealWindow = secondary;
  static const Color sleepZone = Color(0xFF94A3B8);
  static const Color fastingZone = rose;

  // ── 3. High-Legibility Typography Palette ─────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);     // Warm silk white
  static const Color textSecondary = Color(0xFF94A3B8);   // Cool slate body text
  static const Color textMuted = Color(0xFF64748B);       // Subtitle / Eyebrow metadata
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

  // ── 5. Global Material 3 Theme Configuration ──────────────────────────────
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
      // Primary Buttons
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
      // Inputs
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
      // Dividers
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
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

  // ── 6. Reusable High-End UI Components ────────────────────────────────────

  /// Symmetrical card decoration with zero harsh glare.
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

  /// Calm, non-screaming clinical badge.
  static Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Metric tile with calm typography and muted icon.
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
                  fontSize: 10,
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
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFamily: monoFont,
            ),
          ),
        ],
      ),
    );
  }
}
