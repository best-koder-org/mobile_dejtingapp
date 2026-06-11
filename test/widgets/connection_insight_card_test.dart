import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/models/match_insight.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/widgets/connection_insight_card.dart';

/// Test helpers — creates a minimal app wrapper for widget tests.
Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

final _testHook = ConnectionHook(
  headline: 'You both enjoy dance',
  body: '',
  evidenceChips: ['Dance', 'Music'],
  suggestedPrompt: 'Ask what song always gets them moving',
  tone: 'warm',
  confidenceLabel: 'Strong signal',
);

final _testMatchProfile = UserProfile(
  id: '1',
  userId: 'user2',
  firstName: 'Sofia',
  lastName: '',
  dateOfBirth: DateTime(1994, 5, 10),
  interests: ['Dance', 'Music'],
);

final _testCurrentProfile = UserProfile(
  id: '2',
  userId: 'user1',
  firstName: 'Alex',
  lastName: '',
  dateOfBirth: DateTime(1993, 8, 15),
  interests: ['Dance', 'Cooking'],
);

void main() {
  group('ConnectionInsightCard', () {
    testWidgets('renders headline, avatars, chips, and prompt', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ConnectionInsightCard(
          hook: _testHook,
          matchProfile: _testMatchProfile,
          currentUserProfile: _testCurrentProfile,
        ),
      ));

      // Should render the "What brings you together" header
      expect(find.text('What brings you together'), findsOneWidget);

      // Should render the headline
      expect(find.text('You both enjoy dance'), findsOneWidget);

      // Should render evidence chips
      expect(find.text('Dance'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);

      // Should render confidence label
      expect(find.text('Strong signal'), findsOneWidget);

      // Should render the suggested prompt
      expect(find.text('Ask what song always gets them moving'), findsOneWidget);
    });

    testWidgets('renders caution-style card with honest language', (tester) async {
      final cautionHook = ConnectionHook(
        headline: 'Different rhythms here — worth checking early',
        body: '',
        evidenceChips: ['Spontaneous', 'Plans ahead'],
        suggestedPrompt: 'Ask how they like plans to happen',
        tone: 'honest',
        confidenceLabel: 'Different rhythms',
      );

      await tester.pumpWidget(buildTestApp(
        ConnectionInsightCard(
          hook: cautionHook,
          matchProfile: _testMatchProfile,
        ),
      ));

      expect(find.text('What brings you together'), findsOneWidget);
      expect(
        find.text('Different rhythms here — worth checking early'),
        findsOneWidget,
      );
      expect(find.text('Different rhythms'), findsOneWidget);
      expect(find.text('Spontaneous'), findsOneWidget);
      expect(find.text('Ask how they like plans to happen'), findsOneWidget);
    });

    testWidgets('tap on prompt fills message controller', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(buildTestApp(
        ConnectionInsightCard(
          hook: _testHook,
          matchProfile: _testMatchProfile,
          currentUserProfile: _testCurrentProfile,
          messageController: controller,
        ),
      ));

      // Tap the suggested prompt container
      await tester.tap(find.text('Ask what song always gets them moving'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Ask what song always gets them moving');
    });

    testWidgets('works without currentUserProfile (only shows match avatar)',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        ConnectionInsightCard(
          hook: _testHook,
          matchProfile: _testMatchProfile,
        ),
      ));

      // Should still render core content
      expect(find.text('What brings you together'), findsOneWidget);
      expect(find.text('You both enjoy dance'), findsOneWidget);
      expect(find.text('Dance'), findsOneWidget);
    });
  });
}
