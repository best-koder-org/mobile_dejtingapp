import 'package:dejtingapp/flavors/flavor_config.dart';

/// Centralized onboarding flow coordinator.
///
/// Defines the ordered sequence of onboarding steps, maps each to a route,
/// and provides navigation + progress helpers.
/// Created as part of T026-COORD — does NOT modify existing screens.
class OnboardingCoordinator {
  /// The base ordered list of onboarding steps.
  static const List<String> _baseSteps = [
    '/onboarding/phone-entry',
    '/onboarding/verify-code',
    '/onboarding/community-guidelines',
    '/onboarding/first-name',
    '/onboarding/birthday',
    '/onboarding/gender',
    '/onboarding/orientation',
    '/onboarding/match-preferences',
    '/onboarding/age-range',
    '/onboarding/relationship-goals',
    '/onboarding/lifestyle',
    '/onboarding/interests',
    '/onboarding/about-me',
    '/onboarding/photos',
    '/onboarding/location',
    '/onboarding/notifications',
    '/onboarding/complete',
  ];

  /// Returns the effective step list, including flavor-specific steps.
  /// Voice flavor inserts '/onboarding/voice-answers' after photos.
  static List<String> get steps {
    final flags = FlavorConfig.current.featureFlags;
    if (flags.voiceAnswersRequired > 0) {
      final list = List<String>.from(_baseSteps);
      final photosIdx = list.indexOf('/onboarding/photos');
      if (photosIdx >= 0) {
        list.insert(photosIdx + 1, '/onboarding/voice-answers');
      }
      return list;
    }
    return _baseSteps;
  }

  /// Total number of steps in the onboarding flow.
  static int get totalSteps => steps.length;

  /// Returns the 0-based index of [route], or -1 if not found.
  static int indexOf(String route) => steps.indexOf(route);

  /// Returns the next route after [currentRoute], or `null` if this is the
  /// last step (or the route is unknown).
  static String? getNextRoute(String currentRoute) {
    final s = steps;
    final idx = s.indexOf(currentRoute);
    if (idx < 0 || idx >= s.length - 1) return null;
    return s[idx + 1];
  }

  /// Returns the previous route before [currentRoute], or `null` if this is
  /// the first step (or the route is unknown).
  static String? getPreviousRoute(String currentRoute) {
    final s = steps;
    final idx = s.indexOf(currentRoute);
    if (idx <= 0) return null;
    return s[idx - 1];
  }

  /// Returns a progress value between 0.0 and 1.0 for [currentRoute].
  ///
  /// The first step returns a small non-zero value (1/totalSteps) so the
  /// progress bar is never completely empty.  Returns 0.0 for unknown routes.
  static double getProgress(String currentRoute) {
    final s = steps;
    final idx = s.indexOf(currentRoute);
    if (idx < 0) return 0.0;
    return (idx + 1) / s.length;
  }

  /// Whether [currentRoute] is the last step in the flow.
  static bool isLastStep(String currentRoute) {
    final s = steps;
    return s.isNotEmpty && currentRoute == s.last;
  }

  /// Whether [currentRoute] is the first step in the flow.
  static bool isFirstStep(String currentRoute) {
    final s = steps;
    return s.isNotEmpty && currentRoute == s.first;
  }

  /// Returns the route for a given step number (1-based).
  /// Returns `null` for out-of-range values.
  static String? getRouteForStep(int stepNumber) {
    final s = steps;
    if (stepNumber < 1 || stepNumber > s.length) return null;
    return s[stepNumber - 1];
  }

  /// Returns the human-readable step label, e.g. "Step 5 of 16".
  static String getStepLabel(String currentRoute) {
    final s = steps;
    final idx = s.indexOf(currentRoute);
    if (idx < 0) return '';
    return 'Step ${idx + 1} of ${s.length}';
  }
}
