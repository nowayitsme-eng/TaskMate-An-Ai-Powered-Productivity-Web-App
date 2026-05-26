import 'package:flutter/material.dart';

class AppTheme {
  // === Modern Color Scheme ===
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFC4B5FD);
  static const Color primaryDark = Color(0xFF6D28D9);
  
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF6EE7B7);
  static const Color secondaryDark = Color(0xFF047857);
  
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  
  static const Color dark = Color(0xFF1E293B);
  static const Color background = Color(0xFF0F172A);
  static const Color light = Color(0xFFF8FAFC);
  
  static const Color gray = Color(0xFF94A3B8);
  static const Color grayLight = Color(0xFFE2E8F0);
  
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFCA5A5);
  static const Color dangerDark = Color(0xFFDC2626);
  
  static const Color glass = Color(0x26FFFFFF); // 15% white

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background, // We'll use a gradient in the actual UI where needed
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: dark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: danger,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: primary.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: grayLight),
        hintStyle: TextStyle(color: grayLight.withValues(alpha: 0.5)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.03),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
