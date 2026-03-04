import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/services/onboarding_coordinator.dart';

void main() {
  group('OnboardingCoordinator', () {
    test('has 17 steps', () {
      expect(OnboardingCoordinator.totalSteps, 17);
    });

    test('steps start with phone-entry and end with complete', () {
      expect(OnboardingCoordinator.steps.first, '/onboarding/phone-entry');
      expect(OnboardingCoordinator.steps.last, '/onboarding/complete');
    });

    test('indexOf returns correct positions', () {
      expect(OnboardingCoordinator.indexOf('/onboarding/phone-entry'), 0);
      expect(OnboardingCoordinator.indexOf('/onboarding/first-name'), 3);
      expect(OnboardingCoordinator.indexOf('/onboarding/complete'), 16);
      expect(OnboardingCoordinator.indexOf('/nonexistent'), -1);
    });

    test('getNextRoute returns correct next step', () {
      expect(
        OnboardingCoordinator.getNextRoute('/onboarding/phone-entry'),
        '/onboarding/verify-code',
      );
      expect(
        OnboardingCoordinator.getNextRoute('/onboarding/first-name'),
        '/onboarding/birthday',
      );
      expect(
        OnboardingCoordinator.getNextRoute('/onboarding/notifications'),
        '/onboarding/complete',
      );
    });

    test('getNextRoute returns null for last step', () {
      expect(
        OnboardingCoordinator.getNextRoute('/onboarding/complete'),
        isNull,
      );
    });

    test('getNextRoute returns null for unknown route', () {
      expect(
        OnboardingCoordinator.getNextRoute('/nonexistent'),
        isNull,
      );
    });

    test('getPreviousRoute returns correct prev step', () {
      expect(
        OnboardingCoordinator.getPreviousRoute('/onboarding/verify-code'),
        '/onboarding/phone-entry',
      );
      expect(
        OnboardingCoordinator.getPreviousRoute('/onboarding/birthday'),
        '/onboarding/first-name',
      );
    });

    test('getPreviousRoute returns null for first step', () {
      expect(
        OnboardingCoordinator.getPreviousRoute('/onboarding/phone-entry'),
        isNull,
      );
    });

    test('getProgress returns increasing values', () {
      final first =
          OnboardingCoordinator.getProgress('/onboarding/phone-entry');
      final mid = OnboardingCoordinator.getProgress('/onboarding/gender');
      final last = OnboardingCoordinator.getProgress('/onboarding/complete');

      expect(first, greaterThan(0));
      expect(mid, greaterThan(first));
      expect(last, equals(1.0));
    });

    test('getProgress returns 0 for unknown route', () {
      expect(OnboardingCoordinator.getProgress('/nonexistent'), 0.0);
    });

    test('isFirstStep and isLastStep', () {
      expect(
          OnboardingCoordinator.isFirstStep('/onboarding/phone-entry'), isTrue);
      expect(
          OnboardingCoordinator.isFirstStep('/onboarding/birthday'), isFalse);
      expect(
          OnboardingCoordinator.isLastStep('/onboarding/complete'), isTrue);
      expect(
          OnboardingCoordinator.isLastStep('/onboarding/birthday'), isFalse);
    });

    test('getRouteForStep (1-based)', () {
      expect(
          OnboardingCoordinator.getRouteForStep(1), '/onboarding/phone-entry');
      expect(OnboardingCoordinator.getRouteForStep(4), '/onboarding/first-name');
      expect(OnboardingCoordinator.getRouteForStep(17), '/onboarding/complete');
      expect(OnboardingCoordinator.getRouteForStep(0), isNull);
      expect(OnboardingCoordinator.getRouteForStep(99), isNull);
    });

    test('getStepLabel returns human-readable string', () {
      expect(
        OnboardingCoordinator.getStepLabel('/onboarding/phone-entry'),
        'Step 1 of 17',
      );
      expect(
        OnboardingCoordinator.getStepLabel('/onboarding/complete'),
        'Step 17 of 17',
      );
    });

    test('step order is correct', () {
      const expectedOrder = [
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
      expect(OnboardingCoordinator.steps, expectedOrder);
    });
  });
}
