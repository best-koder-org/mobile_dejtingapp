import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DatingApp dark premium theme — matches Welcome screen's immersive aesthetic
/// Coral #FF7F50 → Purple #7F13EC gradient, dark surfaces, high contrast
class AppTheme {
  AppTheme._();

  // ─── Brand Colors (matched to Welcome screen) ────────
  static const primaryColor = Color(0xFFFF7F50);      // Coral — primary CTA
  static const primaryLight = Color(0xFFFFAB91);       // Light coral
  static const primaryDark = Color(0xFFE65100);        // Deep coral
  static const primarySubtle = Color(0x1AFF7F50);      // 10% coral for chips/bg

  static const secondaryColor = Color(0xFF7F13EC);     // Purple accent (gradient end)
  static const tertiaryColor = Color(0xFF00E676);      // Green — success/verified
  static const tealAccent = Color(0xFF4ECDC4);          // Teal — super like

  // ─── Surface Colors (dark premium) ────────────────────
  static const scaffoldDark = Color(0xFF0D0D1A);       // Near-black scaffold
  static const surfaceColor = Color(0xFF1A1A2E);        // Dark navy cards
  static const surfaceDark = Color(0xFF1A1A2E);         // Deep navy — immersive bg
  static const surfaceDarkAlt = Color(0xFF16213E);      // Slightly lighter navy
  static const surfaceElevated = Color(0xFF252540);     // Elevated cards/modals

  // ─── Chat bubbles (Hinge-style) ───────────────────────
  static const chatBubbleMe = Color(0xFFFF7F50);        // Coral — my messages
  static const chatBubbleOther = Color(0xFFF1F3F5);      // Light (Hinge-style) — other person's bubbles
  static const dividerColor = Color(0xFF2A2A45);        // Subtle dark dividers

  // ─── Text Colors ──────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);         // White — primary text
  static const textSecondary = Color(0xB3FFFFFF);       // 70% white
  static const textTertiary = Color(0x66FFFFFF);        // 40% white
  static const textOnPrimary = Color(0xFFFFFFFF);       // White on coral
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkSecondary = Color(0xB3FFFFFF);

  // ─── Semantic Colors ──────────────────────────────────
  static const successColor = Color(0xFF00E676);
  static const errorColor = Color(0xFFFF5252);
  static const warningColor = Color(0xFFFFB74D);
  static const infoColor = Color(0xFF64B5F6);

  // ─── Gradient Presets (Welcome screen style) ──────────
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7F50), Color(0xFFFF6B6B)],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
  );

  static const shimmerGradient = LinearGradient(
    colors: [Color(0xFFFF7F50), Color(0xFF7F13EC), Color(0xFFFF7F50)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceColor, scaffoldDark],
  );

  // ─── Spacing (8pt grid) ───────────────────────────────
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;

  // ─── Border Radii ─────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 100;

  // ─── Helper: Dark card decoration ─────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: dividerColor, width: 0.5),
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: surfaceElevated,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: dividerColor, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── Legacy alias (keep for existing code) ────────────
  static const scaffoldLight = scaffoldDark;

  // ─── Dark Theme ───────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryDark,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: textOnPrimary,
      onSurface: textPrimary,
      onSecondary: textOnPrimary,
      outline: dividerColor,
    ),

    scaffoldBackgroundColor: scaffoldDark,
    dividerColor: dividerColor,

    // Typography — Poppins headings, Inter body (white text)
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.bold,
        color: textPrimary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
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

    // AppBar — dark glass-like
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
      ),
    ),

    // Cards — dark glass
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: dividerColor, width: 0.5),
      ),
    ),

    // Buttons — coral CTAs
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
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
          borderRadius: BorderRadius.circular(26),
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

    // Inputs — dark filled
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
    ),

    // Chips — dark with coral accent
    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primarySubtle,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: const BorderSide(color: dividerColor, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Bottom Nav — dark
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textTertiary,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
    ),

    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: dividerColor,
      linearMinHeight: 4,
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 0.5,
      space: 0,
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimary,
      elevation: 2,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // Switch
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

    // Slider
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: dividerColor,
      thumbColor: primaryColor,
      overlayColor: primarySubtle,
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      iconColor: primaryColor,
      textColor: textPrimary,
    ),
  );

  // ─── Legacy alias ─────────────────────────────────────
  static ThemeData lightTheme = darkTheme;
}
