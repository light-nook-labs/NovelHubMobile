import 'package:flutter/material.dart';

class AppColors {
  // Primary - Deep Indigo
  static const Color primary = Color(0xFF5B5FE9);
  static const Color primaryLight = Color(0xFF8B8FFF);
  static const Color primaryDark = Color(0xFF3D41C7);

  // Accent - Warm Coral
  static const Color accent = Color(0xFFFF6B6B);

  // Secondary - Teal
  static const Color secondary = Color(0xFF26A69A);

  // Status colors
  static const Color ongoing = Color(0xFF66BB6A);   // Green
  static const Color completed = Color(0xFF5B5FE9);  // Indigo
  static const Color stopped = Color(0xFF9E9E9E);    // Grey

  // Background
  static const Color scaffoldLight = Color(0xFFF8F9FA);
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
