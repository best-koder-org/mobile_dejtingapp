import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Oldies theme — warm gold/cream, larger text, senior-friendly.
class OldiesTheme {
  OldiesTheme._();

  // ─── Brand Colors ─────────────────────────────────────
  static const primaryColor = Color(0xFFD4A017);       // Warm gold
  static const primaryLight = Color(0xFFFFD54F);       // Light gold
  static const primaryDark = Color(0xFFA67C00);        // Deep amber
  static const primarySubtle = Color(0x1AD4A017);      // 10% gold

  static const secondaryColor = Color(0xFF8D6E63);     // Warm brown
  static const tertiaryColor = Color(0xFFE57373);      // Soft coral

  // ─── Surface Colors ───────────────────────────────────
  static const scaffoldDark = Color(0xFF141210);        // Warm dark
  static const surfaceColor = Color(0xFF1E1B18);        // Warm dark cards
  static const surfaceElevated = Color(0xFF2A2520);    // Elevated
  static const dividerColor = Color(0xFF3D3631);        // Warm gray dividers

  // ─── Text Colors ──────────────────────────────────────
  static const textPrimary = Color(0xFFFFF8E1);        // Warm white
  static const textSecondary = Color(0xB3FFF8E1);
  static const textTertiary = Color(0x66FFF8E1);

  // Base font scale factor — 15% larger for readability
  static const double _fontScale = 1.15;

  // ─── Theme Data ───────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryDark,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      error: AppTheme.errorColor,
      onPrimary: Colors.black,
      onSurface: textPrimary,
      onSecondary: Colors.white,
      outline: dividerColor,
    ),

    scaffoldBackgroundColor: scaffoldDark,
    dividerColor: dividerColor,

    textTheme: TextTheme(
      displayLarge: GoogleFonts.merriweather(
        fontSize: 32 * _fontScale, fontWeight: FontWeight.bold,
        color: textPrimary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.merriweather(
        fontSize: 28 * _fontScale, fontWeight: FontWeight.bold, color: textPrimary,
      ),
      headlineLarge: GoogleFonts.merriweather(
        fontSize: 24 * _fontScale, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      headlineMedium: GoogleFonts.merriweather(
        fontSize: 20 * _fontScale, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      titleLarge: GoogleFonts.merriweather(
        fontSize: 18 * _fontScale, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      titleMedium: GoogleFonts.merriweather(
        fontSize: 16 * _fontScale, fontWeight: FontWeight.w500, color: textPrimary,
      ),
      bodyLarge: GoogleFonts.sourceSerif4(
        fontSize: 16 * _fontScale, color: textPrimary, height: 1.6,
      ),
      bodyMedium: GoogleFonts.sourceSerif4(
        fontSize: 14 * _fontScale, color: textSecondary, height: 1.6,
      ),
      bodySmall: GoogleFonts.sourceSerif4(
        fontSize: 12 * _fontScale, color: textTertiary, height: 1.5,
      ),
      labelLarge: GoogleFonts.sourceSerif4(
        fontSize: 14 * _fontScale, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      labelMedium: GoogleFonts.sourceSerif4(
        fontSize: 12 * _fontScale, fontWeight: FontWeight.w500, color: textSecondary,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 20 * _fontScale, fontWeight: FontWeight.w600, color: textPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: dividerColor, width: 0.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: GoogleFonts.sourceSerif4(fontSize: 16 * _fontScale, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.sourceSerif4(fontSize: 14 * _fontScale, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintStyle: GoogleFonts.sourceSerif4(color: textTertiary, fontSize: 14 * _fontScale),
      labelStyle: GoogleFonts.sourceSerif4(color: textSecondary, fontSize: 14 * _fontScale),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primarySubtle,
      labelStyle: GoogleFonts.sourceSerif4(fontSize: 13 * _fontScale, color: textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: dividerColor, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12 * _fontScale, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12 * _fontScale),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textTertiary,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.sourceSerif4(fontSize: 14 * _fontScale, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.sourceSerif4(fontSize: 14 * _fontScale),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: dividerColor,
      linearMinHeight: 4,
    ),

    dividerTheme: const DividerThemeData(
      color: dividerColor, thickness: 0.5, space: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 2,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}
