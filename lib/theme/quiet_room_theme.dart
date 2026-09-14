import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_theme.dart' show AppTheme; // semantic error fallback parity

/// Quiet Room theme — "Less profile, more person."
///
/// Dark Inkwell canvas (#15131A), Brass accent (#B89968), Bone surfaces where
/// the user appears (#E8E2D5). Fraunces display/body, Courier Prime mono
/// small-caps labels. Corner radii 2/4/8 (never pill). Calm, flat, no shadows.
///
/// Built from the Stitch "Obsidian & Bone" / "Silent Archive" exploration
/// (project 18294427622036459394, 2026-09-07). Reference tokens:
/// mobile-apps/flutter/dejtingapp/design-quiet-room/tokens.json
class QuietRoomTheme {
  QuietRoomTheme._();

  // Convenience aliases (single source of truth = AppColors.quietRoom).
  static const AppColors palette = AppColors.quietRoom;
  static Color get canvas => palette.scaffold;
  static Color get brass => palette.primary;
  static Color get bone => palette.surface;
  static Color get ash => palette.textSecondary;
  static Color get smoke => palette.surfaceElevated;
  static Color get parchment => palette.textPrimary;

  // Calm motion scale (ms).
  static const Duration tapResponse = Duration(milliseconds: 120);
  static const Duration elementEnter = Duration(milliseconds: 240);
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration photoCrossDissolve = Duration(milliseconds: 800);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    extensions: const [AppColors.quietRoom],

    colorScheme: ColorScheme.dark(
      primary: brass,
      onPrimary: palette.onPrimary,
      primaryContainer: smoke,
      onPrimaryContainer: parchment,
      secondary: ash,
      onSecondary: canvas,
      tertiary: bone,
      onTertiary: canvas,
      surface: canvas,
      onSurface: parchment,
      surfaceContainerHighest: smoke,
      onSurfaceVariant: ash,
      error: palette.error,
      onError: canvas,
      outline: ash,
    ),

    scaffoldBackgroundColor: canvas,
    canvasColor: canvas,
    dividerColor: ash,

    // Typography — Fraunces (display/body), Courier Prime (mono labels).
    textTheme: TextTheme(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 32, fontWeight: FontWeight.w400,
        color: parchment, letterSpacing: -0.02,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 26, fontWeight: FontWeight.w400,
        color: parchment, letterSpacing: -0.02,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 24, fontWeight: FontWeight.w400,
        color: parchment, letterSpacing: -0.01,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 20, fontWeight: FontWeight.w400,
        color: parchment, letterSpacing: -0.01,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 18, fontWeight: FontWeight.w400,
        color: parchment,
      ),
      titleMedium: GoogleFonts.fraunces(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: parchment,
      ),
      bodyLarge: GoogleFonts.fraunces(
        fontSize: 16, fontWeight: FontWeight.w300,
        color: parchment, height: 1.55,
      ),
      bodyMedium: GoogleFonts.fraunces(
        fontSize: 14, fontWeight: FontWeight.w300,
        color: ash, height: 1.55,
      ),
      bodySmall: GoogleFonts.fraunces(
        fontSize: 12, fontWeight: FontWeight.w300,
        color: ash, height: 1.5,
      ),
      labelLarge: GoogleFonts.courierPrime(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: brass, letterSpacing: 0.08,
      ),
      labelMedium: GoogleFonts.courierPrime(
        fontSize: 10, fontWeight: FontWeight.w400,
        color: ash, letterSpacing: 0.08,
      ),
      labelSmall: GoogleFonts.courierPrime(
        fontSize: 10, fontWeight: FontWeight.w400,
        color: ash, letterSpacing: 0.05,
      ),
    ),

    // AppBar — minimal, flat, no gradient.
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: parchment,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 20, fontWeight: FontWeight.w400, color: parchment,
      ),
      iconTheme: IconThemeData(color: ash),
    ),

    // Cards — flat bone-less (dark) by default; keep surfaces subtle.
    cardTheme: CardThemeData(
      color: smoke,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(palette.radiusMd),
        side: BorderSide(color: ash.withValues(alpha: 0.4), width: 1),
      ),
    ),

    // Buttons — rectangular (≤8 radius), brass.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brass,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radiusMd),
        ),
        textStyle: GoogleFonts.fraunces(
          fontSize: 16, fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brass,
        side: BorderSide(color: brass, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radiusMd),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brass,
        textStyle: GoogleFonts.fraunces(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Inputs — underline only (museum label), no filled box.
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: ash, width: 1),
        borderRadius: BorderRadius.circular(palette.radiusSm),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: ash, width: 1),
        borderRadius: BorderRadius.circular(palette.radiusSm),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: brass, width: 1.5),
        borderRadius: BorderRadius.circular(palette.radiusSm),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      hintStyle: GoogleFonts.fraunces(color: ash, fontSize: 15, fontStyle: FontStyle.italic),
      labelStyle: GoogleFonts.fraunces(color: ash, fontSize: 14),
    ),

    // Chips — museum labels.
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: brass.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.courierPrime(
        fontSize: 10, color: parchment, letterSpacing: 0.05,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(palette.radiusSm),
        side: BorderSide(color: ash, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    // Bottom nav — flat, brass only on active.
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: canvas,
      selectedItemColor: brass,
      unselectedItemColor: ash,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.02),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: brass,
      unselectedLabelColor: ash,
      indicatorColor: brass,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.fraunces(fontSize: 14),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: brass,
      linearTrackColor: ash,
      linearMinHeight: 2,
    ),

    dividerTheme: DividerThemeData(
      color: ash,
      thickness: 1,
      space: 0,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brass,
      foregroundColor: palette.onPrimary,
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: smoke,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(palette.radiusMd),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: smoke,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(palette.radiusLg)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: smoke,
      contentTextStyle: GoogleFonts.fraunces(color: parchment, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(palette.radiusMd)),
      behavior: SnackBarBehavior.floating,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brass;
        return ash;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brass.withValues(alpha: 0.3);
        return ash.withValues(alpha: 0.3);
      }),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: brass,
      inactiveTrackColor: ash.withValues(alpha: 0.4),
      thumbColor: brass,
      overlayColor: brass.withValues(alpha: 0.1),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: brass,
      textColor: parchment,
    ),
  );
}
