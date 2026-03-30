import 'dejting_config.dart';
import 'package:flutter/material.dart';

/// Feature flags that differ between app flavors.
class FlavorFeatureFlags {
  // ─── Existing flags ───────────────────────────────────
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

  // ─── Voice flags ──────────────────────────────────────
  /// Hide photos in discovery — show silhouette instead.
  final bool hidePhotosInDiscovery;

  /// Number of voice answers required during onboarding (0 = none).
  final int voiceAnswersRequired;

  /// Messages before photo reveal button activates (0 = disabled).
  final int photoRevealThreshold;

  // ─── Darkness flags ───────────────────────────────────
  /// Whether private photo albums (reveal-on-request) are enabled.
  final bool privateAlbums;

  /// Whether couple/group profiles are enabled.
  final bool coupleProfiles;

  /// Whether incognito browsing mode is available.
  final bool incognitoMode;

  // ─── Oldies flags ─────────────────────────────────────
  /// Whether accessibility mode is enabled (large fonts, high contrast, big tap targets).
  final bool accessibilityMode;

  /// Whether in-app video chat is enabled.
  final bool videoChatEnabled;

  /// Whether daily curated picks mode replaces infinite swiping.
  final bool dailyPicksMode;

  const FlavorFeatureFlags({
    required this.dailySwipeLimit,
    required this.showCompatibilityScores,
    required this.prominentVoicePrompts,
    required this.showProfilePrompts,
    required this.photoForwardDiscovery,
    // New flags — all default false/0 so existing configs don't break
    this.hidePhotosInDiscovery = false,
    this.voiceAnswersRequired = 0,
    this.photoRevealThreshold = 0,
    this.privateAlbums = false,
    this.coupleProfiles = false,
    this.incognitoMode = false,
    this.accessibilityMode = false,
    this.videoChatEnabled = false,
    this.dailyPicksMode = false,
  });
}

/// Copy/tone strings that differ between flavors.
class FlavorCopy {
  final String welcomeTitle;
  final String welcomeSubtitle;
  final String discoverEmptyTitle;
  final String discoverEmptySubtitle;
  final String discoverSubtitle;
  final String onboardingGoalQuestion;
  final List<String> onboardingGoalOptions;

  const FlavorCopy({
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.discoverEmptyTitle,
    required this.discoverEmptySubtitle,
    this.discoverSubtitle = '',
    required this.onboardingGoalQuestion,
    required this.onboardingGoalOptions,
  });
}

/// Abstract flavor configuration — each flavor implements this.
abstract class FlavorConfig {
  /// Singleton current flavor — set once at app startup.
  /// Defaults to DejtingFlavorConfig if not explicitly set.
  static FlavorConfig? _current;
  static FlavorConfig get current => _current ?? DejtingFlavorConfig();
  static set current(FlavorConfig config) => _current = config;

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
