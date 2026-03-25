import 'package:dejtingapp/theme/fleet_theme.dart';
import 'package:flutter/material.dart';
import 'flavor_config.dart';

/// "Fleet" flavor — casual/social, neon green theme, fast pace.
class FleetFlavorConfig extends FlavorConfig {
  @override
  String get flavorId => 'fleet';

  @override
  String get appName => 'Fleet';

  @override
  ThemeData get theme => FleetTheme.darkTheme;

  @override
  FlavorFeatureFlags get featureFlags => const FlavorFeatureFlags(
    dailySwipeLimit: 0, // unlimited
    showCompatibilityScores: false,
    prominentVoicePrompts: false,
    showProfilePrompts: false,
    photoForwardDiscovery: true,
  );

  @override
  FlavorCopy get copy => const FlavorCopy(
    welcomeTitle: 'Meet people nearby',
    welcomeSubtitle: 'Swipe. Match. Meet.',
    discoverEmptyTitle: 'No one nearby right now',
    discoverEmptySubtitle: 'Try expanding your distance or check back later',
    onboardingGoalQuestion: 'What\'s your vibe?',
    onboardingGoalOptions: [
      'Casual',
      'Open to anything',
      'Just here to meet people',
      'Friends first',
    ],
  );
}
