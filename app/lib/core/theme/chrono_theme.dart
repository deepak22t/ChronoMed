import 'package:flutter/material.dart';

/// ChronoMed Production Design System
/// Dark-first clinical aesthetic: Obsidian background, Cyan/Emerald accents.
abstract final class ChronoTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color obsidian = Color(0xFF07090E);
  static const Color surface = Color(0xFF0F1117);
  static const Color surfaceElevated = Color(0xFF161B27);
  static const Color surfaceCard = Color(0xFF1C2333);
  static const Color border = Color(0xFF252D3D);

  static const Color cyan = Color(0xFF22D3EE);
  static const Color cyanDim = Color(0xFF0891B2);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDim = Color(0xFF047857);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);
  static const Color violet = Color(0xFF8B5CF6);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color textDim = Color(0xFF64748B);

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color doseScheduled = amber;
  static const Color doseTaken = emerald;
  static const Color doseMissed = rose;
  static const Color fastingZone = Color(0xFFFCA5A5); // rose/100
  static const Color mealWindow = Color(0xFF6EE7B7);  // emerald/300
  static const Color sleepZone = Color(0xFF818CF8);   // indigo/400

  // ── Typography ────────────────────────────────────────────────────────────
  static const String monoFont = 'JetBrainsMono';

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
      // AppBar
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Divider
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      // Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: cyan, size: 22),
        unselectedIconTheme: IconThemeData(color: textMuted, size: 22),
        selectedLabelTextStyle: TextStyle(color: cyan, fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: textMuted, fontSize: 11),
        indicatorColor: Color(0xFF0E7490),
        useIndicator: true,
      ),
      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
        labelLarge: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: const Color(0xFF0E7490),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  /// A glowing accent badge chip.
  static Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// A horizontal metric tile.
  static Widget metricTile({
    required String label,
    required String value,
    Color valueColor = textPrimary,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: textMuted),
                const SizedBox(width: 4),
              ],
              Text(label, style: const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: monoFont)),
        ],
      ),
    );
  }
}
