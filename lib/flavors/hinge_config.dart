import 'package:dejtingapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'flavor_config.dart';

/// "Dejting" / Hinge flavor — serious relationships, warm coral theme, intentional pace.
class HingeFlavorConfig extends FlavorConfig {
  @override
  String get flavorId => 'hinge';

  @override
  String get appName => 'Dejting';

  @override
  ThemeData get theme => AppTheme.darkTheme;

  @override
  FlavorFeatureFlags get featureFlags => const FlavorFeatureFlags(
    dailySwipeLimit: 10,
    showCompatibilityScores: true,
    prominentVoicePrompts: true,
    showProfilePrompts: true,
    photoForwardDiscovery: false,
  );

  @override
  FlavorCopy get copy => const FlavorCopy(
    welcomeTitle: 'Find your person',
    welcomeSubtitle: 'Designed to be deleted',
    discoverEmptyTitle: 'You\'ve seen everyone for today',
    discoverEmptySubtitle: 'Come back tomorrow for new suggestions',
    onboardingGoalQuestion: 'What are you looking for?',
    onboardingGoalOptions: [
      'Long-term relationship',
      'Serious dating',
      'Something meaningful',
    ],
  );
}
