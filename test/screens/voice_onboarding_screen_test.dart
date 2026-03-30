import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/voice_onboarding_screen.dart';
import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/voice_config.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() {
    setupTestHttpOverrides();
    // Set Voice flavor so VoiceOnboardingScreen has access to feature flags
    FlavorConfig.current = VoiceFlavorConfig();
  });

  group('VoiceOnboardingScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 1200);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('renders scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VoiceOnboardingScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Voice Intro title', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VoiceOnboardingScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Voice Intro'), findsOneWidget);
    });

    testWidgets('shows close button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VoiceOnboardingScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows loading indicator on start (before questions load)', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const VoiceOnboardingScreen()),
      );
      // First frame should show loading (no questions loaded yet)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
