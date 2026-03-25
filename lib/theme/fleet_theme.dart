import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Fleet theme — bold neon green on dark, sharper edges, energetic.
class FleetTheme {
  FleetTheme._();

  // ─── Brand Colors ─────────────────────────────────────
  static const primaryColor = Color(0xFF00E676);       // Neon green
  static const primaryLight = Color(0xFF69F0AE);       // Light green
  static const primaryDark = Color(0xFF00C853);        // Deep green
  static const primarySubtle = Color(0x1A00E676);      // 10% green

  static const secondaryColor = Color(0xFF00B0FF);     // Electric blue
  static const tertiaryColor = Color(0xFFFF4081);      // Hot pink — super like

  // ─── Surface Colors (pure dark) ───────────────────────
  static const scaffoldDark = Color(0xFF0A0A0A);       // Pure dark
  static const surfaceColor = Color(0xFF141414);        // Dark cards
  static const surfaceElevated = Color(0xFF1E1E1E);    // Elevated
  static const dividerColor = Color(0xFF2A2A2A);       // Gray dividers

  // ─── Text Colors ──────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textTertiary = Color(0x66FFFFFF);

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
      onSecondary: Colors.black,
      outline: dividerColor,
    ),

    scaffoldBackgroundColor: scaffoldDark,
    dividerColor: dividerColor,

    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.bold,
        color: textPrimary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28, fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, color: textPrimary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, color: textSecondary, height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, color: textTertiary, height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: dividerColor, width: 0.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primarySubtle,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: const BorderSide(color: dividerColor, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textTertiary,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: dividerColor,
      linearMinHeight: 4,
    ),

    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 0.5,
      space: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 2,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primarySubtle;
        return dividerColor;
      }),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: dividerColor,
      thumbColor: primaryColor,
      overlayColor: primarySubtle,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: primaryColor,
      textColor: textPrimary,
    ),
  );
}
