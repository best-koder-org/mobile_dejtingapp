import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/wizard/notification_permission_screen.dart';
import '../../helpers/onboarding_test_helper.dart';

void main() {
  group('Notification Permission Screen', () {
    Widget buildSubject() {
      return buildOnboardingTestHarness(
        screen: const NotificationPermissionScreen(),
        routeName: '/onboarding/notifications',
      );
    }

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows notifications icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('shows header from l10n', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: enableNotifications = "Enable notifications"
      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('shows accent subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: neverMissAMatch = "Never miss a match"
      expect(find.text('Never miss a match'), findsOneWidget);
    });

    testWidgets('shows explanation text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: notificationDescription contains "notified"
      expect(find.textContaining('notified'), findsOneWidget);
    });

    testWidgets('shows Enable Notifications button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: enableNotificationsBtn = "Enable Notifications"
      expect(find.text('Enable Notifications'), findsOneWidget);
    });

    testWidgets('shows Not now skip button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: notNow = "Not now"
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('Not now button navigates to complete screen', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('complete'), findsOneWidget);
    });

    testWidgets('has Skip button in app bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // l10n: skipButton = "Skip"
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('bottom buttons are protected from system navigation bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate((w) => w is SafeArea && !w.top && w.bottom),
        findsOneWidget,
      );
    });

    testWidgets('has screen:onboarding-notifications semantics label', (tester) async {
      await tester.pumpWidget(buildOnboardingTestHarness(
        screen: const NotificationPermissionScreen(),
        routeName: '/onboarding/notifications',
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Semantics && (w as Semantics).properties.label == 'screen:onboarding-notifications'),
        findsOneWidget,
      );
    });
  });
}