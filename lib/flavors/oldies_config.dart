import 'package:dejtingapp/theme/oldies_theme.dart';
import 'package:flutter/material.dart';
import 'flavor_config.dart';

/// "Oldies" flavor — senior dating 50-65+, warm gold theme, accessibility-first.
class OldiesFlavorConfig extends FlavorConfig {
  @override
  String get flavorId => 'oldies';

  @override
  String get appName => 'Oldies';

  @override
  ThemeData get theme => OldiesTheme.darkTheme;

  @override
  FlavorFeatureFlags get featureFlags => const FlavorFeatureFlags(
    dailySwipeLimit: 8,
    showCompatibilityScores: true,
    prominentVoicePrompts: false,
    showProfilePrompts: true,
    photoForwardDiscovery: false,
    accessibilityMode: true,
    videoChatEnabled: true,
    dailyPicksMode: true,
  );

  @override
  FlavorCopy get copy => const FlavorCopy(
    welcomeTitle: 'Never too late',
    welcomeSubtitle: 'Find companionship at your pace',
    discoverEmptyTitle: 'That\'s everyone for today',
    discoverEmptySubtitle: 'We\'ll have new picks for you tomorrow',
    onboardingGoalQuestion: 'What brings you here?',
    onboardingGoalOptions: [
      'Companionship',
      'New romance',
      'Activity partner',
      'Let\'s see what happens',
    ],
  );
}
