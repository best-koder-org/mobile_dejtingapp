import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Convenience accessors so screens can resolve the ACTIVE palette/theme
/// instead of hardcoding `AppTheme.*` static constants.
extension AppThemeContext on BuildContext {
  /// Semantic color + shape tokens for the active theme.
  AppColors get appColors => AppColors.of(this);

  /// Font family for display/headline text, or null to keep the theme default
  /// (Coral) — allows a serif hero under Quiet Room without changing Coral.
  String? get displayFontFamily => appColors.displayFontFamily;
}
