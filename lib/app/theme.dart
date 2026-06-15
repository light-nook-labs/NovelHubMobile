import 'package:flutter/material.dart';

/// Warm color palette - no cold colors (blue, indigo, cyan, purple, fuchsia)
class AppColors {
  static const Color primary = Color(0xFFFF8C00); // Dark Orange
  static const Color primaryLight = Color(0xFFFFB347);
  static const Color primaryDark = Color(0xFFE07000);
  static const Color secondary = Color(0xFFE8A317); // Gold
  static const Color accent = Color(0xFFFF6B35); // Orange Red

  // Status colors
  static const Color ongoing = Color(0xFF4CAF50); // Green
  static const Color completed = Color(0xFF2196F3); // Blue
  static const Color stopped = Color(0xFF9E9E9E); // Grey

  // Background
  static const Color scaffoldLight = Color(0xFFF5F5F5);
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.scaffoldLight,
    cardTheme: const CardThemeData(
      color: AppColors.cardLight,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.scaffoldDark,
    cardTheme: const CardThemeData(
      color: AppColors.cardDark,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
    ),
  );
}
