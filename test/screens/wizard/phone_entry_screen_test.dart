import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/config/dev_mode.dart';
import 'package:dejtingapp/screens/wizard/phone_entry_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Phone Entry Screen', () {
    late bool savedDevMode;

    setUp(() {
      savedDevMode = DevMode.enabled;
      DevMode.enabled = false;
    });

    tearDown(() {
      DevMode.enabled = savedDevMode;
    });

    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const PhoneEntryScreen(),
        routeName: '/onboarding/phone-entry',
      );
    }

    testWidgets('renders phone title from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: onboardingPhoneTitle = "Can we get your number?"
      expect(find.textContaining('get your number'), findsOneWidget);
    });

    testWidgets('has phone number text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows phone number hint', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: phoneNumberHint = "Phone number"
      expect(find.text('Phone number'), findsOneWidget);
    });

    testWidgets('defaults to Sweden +46 country code', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('+46'), findsOneWidget);
    });

    testWidgets('Continue button is disabled when empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Continue enables with valid phone (9+ digits)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextField), '701234567');
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Continue stays disabled with too few digits', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('has progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has back and close navigation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('has country code dropdown trigger', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('shows info box about continue action', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('has screen:onboarding-phone-entry semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const PhoneEntryScreen(),
        routeName: '/onboarding/phone-entry',
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-phone-entry'),
        findsOneWidget,
      );
    });
  });
}