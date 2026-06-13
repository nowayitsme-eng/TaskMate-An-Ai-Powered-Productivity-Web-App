import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === New Light-Mode Color Palette ===
  // Primary: Indigo
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryLight = Color(0xFF818CF8); // indigo-400
  static const Color primaryDark = Color(0xFF3730A3); // indigo-800
  static const Color primarySurface = Color(0xFFEEF2FF); // indigo-50

  // Secondary: Emerald
  static const Color secondary = Color(0xFF10B981); // emerald-500
  static const Color secondaryLight = Color(0xFF6EE7B7); // emerald-300
  static const Color secondaryDark = Color(0xFF047857); // emerald-700
  static const Color secondarySurface = Color(0xFFECFDF5); // emerald-50

  // Accent: Amber
  static const Color accent = Color(0xFFF59E0B); // amber-500
  static const Color accentLight = Color(0xFFFCD34D); // amber-300
  static const Color accentSurface = Color(0xFFFFFBEB); // amber-50

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color dark = Color(0xFF1E293B); // slate-800
  static const Color darker = Color(0xFF0F172A); // slate-900

  // Text
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF94A3B8); // slate-400

  // Borders & dividers
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderLight = Color(0xFFF1F5F9); // slate-100

  // Status Colors
  static const Color danger = Color(0xFFEF4444); // red-500
  static const Color dangerLight = Color(0xFFFCA5A5); // red-300
  static const Color dangerSurface = Color(0xFFFEF2F2); // red-50

  // Extra pastels for stat cards
  static const Color skyBlue = Color(0xFF0EA5E9); // sky-500
  static const Color skySurface = Color(0xFFF0F9FF); // sky-50
  static const Color rosePink = Color(0xFFF43F5E); // rose-500
  static const Color roseSurface = Color(0xFFFFF1F2); // rose-50

  // Legacy glass (for dark sheets)
  static const Color glass = Color(0x0DFFFFFF);

  // Gray shades (kept for compatibility)
  static const Color gray = Color(0xFF94A3B8);
  static const Color grayLight = Color(0xFFE2E8F0);

  // ─── Shadows ─────────────────────────────────────────────────────────────────

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Light Theme ─────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primarySurface,
        onPrimaryContainer: primaryDark,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondarySurface,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: borderLight,
        error: danger,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: border,
          disabledForegroundColor: textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle: GoogleFonts.inter(color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: border, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: borderLight,
        selectedColor: primarySurface,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        showCheckmark: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearMinHeight: 8,
        linearTrackColor: borderLight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          elevation: WidgetStateProperty.all(4),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: border),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Dark Theme (kept for reference/compatibility) ────────────────────────────

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darker,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: dark,
        onSurface: Colors.white,
        error: danger,
        onError: Colors.white,
      ),
    );
  }
}
