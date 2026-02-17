import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';
import '../services/onboarding_coordinator.dart';

/// Provides [OnboardingData] to all wizard screens via the widget tree.
///
/// Usage in any wizard screen:
/// ```dart
/// final onboarding = OnboardingProvider.of(context);
/// onboarding.data.firstName = _ctrl.text;
/// onboarding.goNext(context);
/// ```
///
/// **Why InheritedWidget?** Zero dependencies. No package needed.
/// Swap to Riverpod later if you want — only this file changes.
class OnboardingProvider extends InheritedWidget {
  final OnboardingData data;

  const OnboardingProvider({
    super.key,
    required this.data,
    required super.child,
  });

  /// Access from any descendant widget.
  static OnboardingProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<OnboardingProvider>();
    assert(result != null, 'No OnboardingProvider found in context');
    return result!;
  }

  /// Nullable version for screens that might run outside the wizard.
  static OnboardingProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OnboardingProvider>();
  }

  // ── Navigation helpers (delegate to OnboardingCoordinator) ────

  /// Navigate to the next wizard screen. Screens never need to know
  /// which route comes next — just call `onboarding.goNext(context)`.
  void goNext(BuildContext context, {String? currentRoute}) {
    final route = currentRoute ?? ModalRoute.of(context)?.settings.name;
    if (route == null) return;
    final next = OnboardingCoordinator.getNextRoute(route);
    if (next != null) {
      Navigator.pushNamed(context, next);
    }
  }

  /// Navigate back.
  void goBack(BuildContext context) => Navigator.pop(context);

  /// Abort the wizard entirely.
  void abort(BuildContext context) =>
      Navigator.popUntil(context, (route) => route.isFirst);

  /// Get progress for the current route (0.0–1.0).
  double progress(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    return OnboardingCoordinator.getProgress(route);
  }

  /// Step label, e.g. "Step 5 of 16".
  String stepLabel(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    return OnboardingCoordinator.getStepLabel(route);
  }

  @override
  bool updateShouldNotify(OnboardingProvider oldWidget) => false;
}
