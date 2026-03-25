import 'package:flutter/material.dart';

/// Feature flags that differ between app flavors.
class FlavorFeatureFlags {
  /// Maximum daily swipe limit (0 = unlimited).
  final int dailySwipeLimit;

  /// Whether to show compatibility scores on profiles.
  final bool showCompatibilityScores;

  /// Whether voice prompts are prominently displayed.
  final bool prominentVoicePrompts;

  /// Whether to show text prompts on profiles ("I geek out on...").
  final bool showProfilePrompts;

  /// Whether discovery is photo-forward (larger images, less text).
  final bool photoForwardDiscovery;

  const FlavorFeatureFlags({
    required this.dailySwipeLimit,
    required this.showCompatibilityScores,
    required this.prominentVoicePrompts,
    required this.showProfilePrompts,
    required this.photoForwardDiscovery,
  });
}

/// Copy/tone strings that differ between flavors.
class FlavorCopy {
  final String welcomeTitle;
  final String welcomeSubtitle;
  final String discoverEmptyTitle;
  final String discoverEmptySubtitle;
  final String onboardingGoalQuestion;
  final List<String> onboardingGoalOptions;

  const FlavorCopy({
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.discoverEmptyTitle,
    required this.discoverEmptySubtitle,
    required this.onboardingGoalQuestion,
    required this.onboardingGoalOptions,
  });
}

/// Abstract flavor configuration — each flavor implements this.
abstract class FlavorConfig {
  /// Singleton current flavor — set once at app startup.
  static late FlavorConfig current;

  /// Machine-readable flavor identifier sent to backend.
  String get flavorId;

  /// Human-readable app name shown in title bars.
  String get appName;

  /// The ThemeData for this flavor.
  ThemeData get theme;

  /// Feature flags controlling behavior differences.
  FlavorFeatureFlags get featureFlags;

  /// Flavor-specific copy/tone.
  FlavorCopy get copy;
}
