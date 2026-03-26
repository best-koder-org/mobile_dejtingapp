import 'package:dejtingapp/theme/voice_theme.dart';
import 'package:flutter/material.dart';
import 'flavor_config.dart';

/// "Voice" flavor — blind dating, hear them first. Love is Blind concept.
class VoiceFlavorConfig extends FlavorConfig {
  @override
  String get flavorId => 'voice';

  @override
  String get appName => 'Voice';

  @override
  ThemeData get theme => VoiceTheme.darkTheme;

  @override
  FlavorFeatureFlags get featureFlags => const FlavorFeatureFlags(
    dailySwipeLimit: 8,
    showCompatibilityScores: true,
    prominentVoicePrompts: true,
    showProfilePrompts: true,
    photoForwardDiscovery: false,
    hidePhotosInDiscovery: true,
    voiceAnswersRequired: 3,
    photoRevealThreshold: 15,
  );

  @override
  FlavorCopy get copy => const FlavorCopy(
    welcomeTitle: 'Hear them first',
    welcomeSubtitle: 'Fall for their voice, not their face',
    discoverEmptyTitle: 'No more voices for today',
    discoverEmptySubtitle: 'Come back tomorrow for new connections',
    onboardingGoalQuestion: 'What matters most to you?',
    onboardingGoalOptions: [
      'Personality & humor',
      'Deep conversations',
      'Genuine connection',
      'Someone who gets me',
    ],
  );
}
