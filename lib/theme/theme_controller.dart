import 'package:flutter/material.dart';
import 'quiet_room_theme.dart';

/// Dev-only skin switcher for the SPIKE.
///
/// Lets us flip the running app between the existing Coral theme and the new
/// Quiet Room theme (see `lib/theme/quiet_room_theme.dart`) without a rebuild,
/// so the design can be reviewed on real screens.
///
/// This is intentionally dev-only and isolated: it overrides the ThemeData for
/// the navigator content when active. When skin == coral (default), no override
/// is applied, so the existing app renders byte-identical to today.
enum AppSkin { coral, quietRoom }

class ThemeController {
  ThemeController._();

  /// Current skin. Defaults to Coral → no visual change.
  static final ValueNotifier<AppSkin> skin = ValueNotifier(AppSkin.coral);

  /// Toggle helper for dev UI (no-op when already on the requested skin).
  static void select(AppSkin value) => skin.value = value;

  /// Returns a ThemeData override for the skin, or null when no override should
  /// be applied (coral => rely on the flavor's own theme).
  static ThemeData? overrideFor(AppSkin value) {
    switch (value) {
      case AppSkin.coral:
        return null;
      case AppSkin.quietRoom:
        return QuietRoomTheme.darkTheme;
    }
  }
}
