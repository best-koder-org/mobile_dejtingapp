import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/services/onboarding_coordinator.dart';
import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/dejting_config.dart';
import 'package:dejtingapp/flavors/voice_config.dart';

void main() {
  group('OnboardingCoordinator', () {
    test('dejting flavor does NOT include voice-answers step', () {
      FlavorConfig.current = DejtingFlavorConfig();
      final steps = OnboardingCoordinator.steps;
      expect(steps.contains('/onboarding/voice-answers'), isFalse);
      expect(steps.length, 17); // base step count
    });

    test('voice flavor includes voice-answers step after photos', () {
      FlavorConfig.current = VoiceFlavorConfig();
      final steps = OnboardingCoordinator.steps;
      expect(steps.contains('/onboarding/voice-answers'), isTrue);
      expect(steps.length, 18); // base + 1

      final photosIdx = steps.indexOf('/onboarding/photos');
      final voiceIdx = steps.indexOf('/onboarding/voice-answers');
      expect(voiceIdx, photosIdx + 1);
    });

    test('getNextRoute works with voice step', () {
      FlavorConfig.current = VoiceFlavorConfig();
      final next = OnboardingCoordinator.getNextRoute('/onboarding/photos');
      expect(next, '/onboarding/voice-answers');
    });

    test('getNextRoute from voice step goes to location', () {
      FlavorConfig.current = VoiceFlavorConfig();
      final next = OnboardingCoordinator.getNextRoute('/onboarding/voice-answers');
      expect(next, '/onboarding/location');
    });

    test('progress calculation includes voice step', () {
      FlavorConfig.current = VoiceFlavorConfig();
      final progress = OnboardingCoordinator.getProgress('/onboarding/voice-answers');
      expect(progress, greaterThan(0.0));
      expect(progress, lessThan(1.0));
    });
  });
}
