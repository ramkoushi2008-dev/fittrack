// THEME LOCK: dark — source: domain signal (fitness/energy app)
// Scaffold.backgroundColor = AppTheme.backgroundDark — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFFC6F135);
  static const Color primaryDark = Color(0xFFA8D520);
  static const Color primaryContainer = Color(0xFF2A3A0A);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFCF6679);
  static const Color info = Color(0xFF64B5F6);

  // Dark surfaces
  static const Color backgroundDark = Color(0xFF141515);
  static const Color surfaceDark = Color(0xFF1E2020);
  static const Color surfaceVariantDark = Color(0xFF252828);
  static const Color cardDark = Color(0xFF1E2020);
  static const Color cardElevatedDark = Color(0xFF252828);

  // Text
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);

  // Metric colors
  static const Color stepsColor = Color(0xFF64B5F6);
  static const Color waterColor = Color(0xFF4FC3F7);
  static const Color proteinColor = Color(0xFFFFB74D);
  static const Color sleepColor = Color(0xFFBA68C8);
  static const Color workoutColor = Color(0xFFC6F135);
  static const Color caloriesColor = Color(0xFFFF7043);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Color(0xFF1A1A1A),
      primaryContainer: Color(0xFFE8F5C0),
      secondary: primaryDark,
      onSecondary: Colors.white,
      surface: Color(0xFFF5F5F5),
      onSurface: Color(0xFF1A1A1A),
      error: error,
      onError: Colors.white,
      outline: Color(0xFFCCCCCC),
      outlineVariant: Color(0xFFEEEEEE),
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF1A1A1A),
      primaryContainer: primaryContainer,
      onPrimaryContainer: primary,
      secondary: primaryDark,
      onSecondary: Color(0xFF1A1A1A),
      surface: surfaceDark,
      onSurface: textPrimary,
      error: error,
      onError: Colors.white,
      outline: Color(0xFF3A3A3A),
      outlineVariant: Color(0xFF2A2A2A),
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: textSecondary,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.manropeTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary),
    appBarTheme: AppBarThemeData(
      backgroundColor: backgroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: error),
      ),
      labelStyle: GoogleFonts.manrope(color: textSecondary),
      hintStyle: GoogleFonts.manrope(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantDark,
      selectedColor: primary,
      labelStyle: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ),
  );
}
