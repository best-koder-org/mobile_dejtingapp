import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Semantic color + shape tokens resolved from the ACTIVE theme at runtime.
///
/// This is the dynamic-palette foundation that lets screens stop hardcoding
/// `AppTheme.*` static constants and instead read `context.appColors`, so that
/// switching the app ThemeData (e.g. Coral -> Quiet Room) re-skins every
/// palette-driven screen.
///
/// ⚠️ REGRESSION CONTRACT: the `.coral` factory values MUST stay byte-identical
/// to the existing `AppTheme.*` constants (see `lib/theme/app_theme.dart`).
/// A widget test pins this equality so the Coral app can never drift visually.
class AppColors extends ThemeExtension<AppColors> {
  // ─── Brand ─────────────────────────────────────────────
  final Color primary; // primary CTA / active accent
  final Color onPrimary; // text/icon placed on primary
  final Color primarySubtle; // ~10% tint of primary (chips, fills)
  final Color secondary; // secondary accent
  final Color tertiary; // success-ish tertiary (kept for parity)

  // ─── Surfaces ──────────────────────────────────────────
  final Color scaffold; // page canvas
  final Color surface; // cards
  final Color surfaceElevated; // elevated cards / input fill / modals
  final Color divider; // hairline borders

  // ─── Text ──────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ─── Semantic ──────────────────────────────────────────
  final Color success;
  final Color error;

  // ─── Shape ─────────────────────────────────────────────
  final double radiusSm; // inputs, chips
  final double radiusMd; // cards
  final double radiusLg; // large surfaces / dialogs

  // ─── Type ──────────────────────────────────────────────
  /// Display/headline font family. null = theme default (Coral keeps today's
  /// render). Quiet Room uses a serif (Fraunces) for the hero/headlines.
  final String? displayFontFamily;

  // ─── Hero (welcome) ───────────────────────────────────
  /// Full-bleed hero gradient stops. Coral == current `AppTheme.brandGradient`
  /// (coral→purple). Quiet Room == inkwell→smoke (calm, no chroma).
  final Color heroGradientBegin;
  final Color heroGradientEnd;
  /// Floating hero card surface. Coral == translucent black (as today);
  /// Quiet Room == smoke (elevated ink).
  final Color heroPanelColor;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primarySubtle,
    required this.secondary,
    required this.tertiary,
    required this.scaffold,
    required this.surface,
    required this.surfaceElevated,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.error,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    this.displayFontFamily,
    this.heroGradientBegin = const Color(0xFFFF7F50),
    this.heroGradientEnd = const Color(0xFF7F13EC),
    this.heroPanelColor = const Color(0xD8000000),
  });

  /// Coral — MUST match `AppTheme` constants in app_theme.dart EXACTLY.
  static const AppColors coral = AppColors(
    primary: Color(0xFFFF7F50),
    onPrimary: Color(0xFFFFFFFF),
    primarySubtle: Color(0x1AFF7F50),
    secondary: Color(0xFF7F13EC),
    tertiary: Color(0xFF00E676),
    scaffold: Color(0xFF0D0D1A),
    surface: Color(0xFF1A1A2E),
    surfaceElevated: Color(0xFF252540),
    divider: Color(0xFF2A2A45),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textTertiary: Color(0x66FFFFFF),
    success: Color(0xFF00E676),
    error: Color(0xFFFF5252),
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    // displayFontFamily intentionally null → identical to today's render.
    // heroGradientBegin/End default to coral→purple (== brandGradient).
    // heroPanelColor defaults to translucent black (== today's hero card).
  );

  /// Quiet Room — Inkwell / Brass / Bone / Ash / Smoke / Parchment.
  /// (From the Stitch "Obsidian & Bone"/"Silent Archive" design system.)
  static const AppColors quietRoom = AppColors(
    primary: Color(0xFFB89968), // Brass — the one warm thing
    onPrimary: Color(0xFF15131A), // Inkwell text on brass
    primarySubtle: Color(0x1AB89968),
    secondary: Color(0xFF847C75), // Ash
    tertiary: Color(0xFFE8E2D5), // Bone
    scaffold: Color(0xFF15131A), // Inkwell canvas
    surface: Color(0xFFE8E2D5), // Bone — surfaces the user is on
    surfaceElevated: Color(0xFF2A2530), // Smoke — elevated/placeholders
    divider: Color(0xFF847C75), // Ash hairlines
    textPrimary: Color(0xFFF1ECE0), // Parchment — primary text on ink
    textSecondary: Color(0xFF847C75), // Ash captions
    textTertiary: Color(0x99B89968), // Dimmed brass
    success: Color(0xFFB89968),
    error: Color(0xFFE57373),
    radiusSm: 2,
    radiusMd: 4,
    radiusLg: 8,
    displayFontFamily: 'Fraunces',
    heroGradientBegin: Color(0xFF15131A), // Inkwell
    heroGradientEnd: Color(0xFF2A2530), // Smoke
    heroPanelColor: Color(0xFF2A2530), // Smoke hero card
  );

  /// Resolve from context; falls back to Coral so screens are safe in tests
  /// where no extension is attached (parity with the old static constants).
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? coral;

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primarySubtle,
    Color? secondary,
    Color? tertiary,
    Color? scaffold,
    Color? surface,
    Color? surfaceElevated,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? error,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    String? displayFontFamily,
    Color? heroGradientBegin,
    Color? heroGradientEnd,
    Color? heroPanelColor,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      error: error ?? this.error,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      displayFontFamily: displayFontFamily ?? this.displayFontFamily,
      heroGradientBegin: heroGradientBegin ?? this.heroGradientBegin,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      heroPanelColor: heroPanelColor ?? this.heroPanelColor,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySubtle: Color.lerp(primarySubtle, other.primarySubtle, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      displayFontFamily:
          t < 0.5 ? displayFontFamily : other.displayFontFamily,
      heroGradientBegin: Color.lerp(heroGradientBegin, other.heroGradientBegin, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      heroPanelColor: Color.lerp(heroPanelColor, other.heroPanelColor, t)!,
    );
  }
}
