import 'package:dejtingapp/theme/darkness_theme.dart';
import 'package:flutter/material.dart';
import 'flavor_config.dart';

/// "Darkness" flavor — BDSM, kink, alt-sexual, body-positive. Deep black + neon.
class DarknessFlavorConfig extends FlavorConfig {
  @override
  String get flavorId => 'darkness';

  @override
  String get appName => 'Darkness';

  @override
  ThemeData get theme => DarknessTheme.darkTheme;

  @override
  FlavorFeatureFlags get featureFlags => const FlavorFeatureFlags(
    dailySwipeLimit: 0, // unlimited
    showCompatibilityScores: false,
    prominentVoicePrompts: false,
    showProfilePrompts: false,
    photoForwardDiscovery: true,
    privateAlbums: true,
    coupleProfiles: true,
    incognitoMode: true,
  );

  @override
  FlavorCopy get copy => const FlavorCopy(
    welcomeTitle: 'Beyond the surface',
    welcomeSubtitle: 'Your desires. Your rules.',
    discoverEmptyTitle: 'No one nearby right now',
    discoverEmptySubtitle: 'Try expanding your distance or check back later',
    onboardingGoalQuestion: 'What are you exploring?',
    onboardingGoalOptions: [
      'Casual encounters',
      'Kink & BDSM',
      'Open relationships',
      'Just curious',
    ],
  );
}
