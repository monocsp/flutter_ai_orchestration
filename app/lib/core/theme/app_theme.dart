import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF0D9488); // teal-600
  static const _surfaceColor = Color(0xFFF8FAFC); // slate-50
  static const _cardColor = Color(0xFFFFFFFF);
  static const _sidebarColor = Color(0xFFF1F5F9); // slate-100
  static const _borderColor = Color(0xFFE2E8F0); // slate-200
  static const _textPrimary = Color(0xFF0F172A); // slate-900
  static const _textSecondary = Color(0xFF475569); // slate-600

  static const stageColors = [
    Color(0xFF0D9488), // teal
    Color(0xFFF97316), // orange
    Color(0xFF6366F1), // indigo
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
  ];

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        surface: _surfaceColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: _surfaceColor,
      cardTheme: const CardThemeData(
        color: _cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: _borderColor),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _sidebarColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: _borderColor,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: _textSecondary,
          fontSize: 13,
        ),
        labelMedium: TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static const sidebarDecoration = BoxDecoration(
    color: _sidebarColor,
    border: Border(right: BorderSide(color: _borderColor)),
  );
}
