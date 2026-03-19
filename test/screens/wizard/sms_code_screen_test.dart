import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/config/dev_mode.dart';
import 'package:dejtingapp/screens/wizard/sms_code_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('SMS Code Screen', () {
    late bool savedDevMode;

    setUp(() {
      savedDevMode = DevMode.enabled;
      // Disable DevMode to prevent auto-fill timers in tests
      DevMode.enabled = false;
    });

    tearDown(() {
      DevMode.enabled = savedDevMode;
    });

    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const SmsCodeScreen(),
        routeName: '/onboarding/verify-code',
      );
    }

    testWidgets('renders verification title from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: enterVerificationCode = "Enter verification\ncode"
      expect(find.textContaining('verification'), findsWidgets);
      // Drain the resend timer
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('shows 6 digit input fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsNWidgets(6));
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('shows code sent fallback description', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: codeSentToPhoneFallback = "We sent a 6-digit code to your phone number."
      expect(find.textContaining('6-digit code'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('shows resend timer initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: resendCodeIn = "Resend code in {seconds}s"
      expect(find.textContaining('Resend code in'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('has back navigation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('shows SMS rates info', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: smsRatesInfo = "Standard SMS rates may apply..."
      expect(find.textContaining('SMS rates'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('wraps content in SingleChildScrollView to prevent keyboard overflow', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });
  });
}
