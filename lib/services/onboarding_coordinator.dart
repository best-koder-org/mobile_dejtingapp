/// Centralized onboarding flow coordinator.
///
/// Defines the ordered sequence of onboarding steps, maps each to a route,
/// and provides navigation + progress helpers.
/// Created as part of T026-COORD — does NOT modify existing screens.
class OnboardingCoordinator {
  /// The ordered list of onboarding steps (routes).
  static const List<String> steps = [
    '/onboarding/phone-entry',
    '/onboarding/verify-code',
    '/onboarding/email',
    '/onboarding/community-guidelines',
    '/onboarding/first-name',
    '/onboarding/birthday',
    '/onboarding/gender',
    '/onboarding/orientation',
    '/onboarding/match-preferences',
    '/onboarding/relationship-goals',
    '/onboarding/lifestyle',
    '/onboarding/interests',
    '/onboarding/about-me',
    '/onboarding/photos',
    '/onboarding/location',
    '/onboarding/notifications',
    '/onboarding/complete',
  ];

  /// Total number of steps in the onboarding flow.
  static int get totalSteps => steps.length;

  /// Returns the 0-based index of [route], or -1 if not found.
  static int indexOf(String route) => steps.indexOf(route);

  /// Returns the next route after [currentRoute], or `null` if this is the
  /// last step (or the route is unknown).
  static String? getNextRoute(String currentRoute) {
    final idx = steps.indexOf(currentRoute);
    if (idx < 0 || idx >= steps.length - 1) return null;
    return steps[idx + 1];
  }

  /// Returns the previous route before [currentRoute], or `null` if this is
  /// the first step (or the route is unknown).
  static String? getPreviousRoute(String currentRoute) {
    final idx = steps.indexOf(currentRoute);
    if (idx <= 0) return null;
    return steps[idx - 1];
  }

  /// Returns a progress value between 0.0 and 1.0 for [currentRoute].
  ///
  /// The first step returns a small non-zero value (1/totalSteps) so the
  /// progress bar is never completely empty.  Returns 0.0 for unknown routes.
  static double getProgress(String currentRoute) {
    final idx = steps.indexOf(currentRoute);
    if (idx < 0) return 0.0;
    return (idx + 1) / steps.length;
  }

  /// Whether [currentRoute] is the last step in the flow.
  static bool isLastStep(String currentRoute) {
    return steps.isNotEmpty && currentRoute == steps.last;
  }

  /// Whether [currentRoute] is the first step in the flow.
  static bool isFirstStep(String currentRoute) {
    return steps.isNotEmpty && currentRoute == steps.first;
  }

  /// Returns the route for a given step number (1-based).
  /// Returns `null` for out-of-range values.
  static String? getRouteForStep(int stepNumber) {
    if (stepNumber < 1 || stepNumber > steps.length) return null;
    return steps[stepNumber - 1];
  }

  /// Returns the human-readable step label, e.g. "Step 5 of 16".
  static String getStepLabel(String currentRoute) {
    final idx = steps.indexOf(currentRoute);
    if (idx < 0) return '';
    return 'Step ${idx + 1} of $totalSteps';
  }
}
