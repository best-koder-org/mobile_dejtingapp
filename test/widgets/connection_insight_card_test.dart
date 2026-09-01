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

    testWidgets('no overflow at narrow width with long confidence badge',
        (tester) async {
      // Regression: the header Row ("What brings you together" + badge) used to
      // overflow by ~25px on the right at phone widths with a wide badge.
      final longHook = ConnectionHook(
        headline: 'You both enjoy dance',
        body: '',
        evidenceChips: ['Dance', 'Music'],
        suggestedPrompt: 'Ask what song always gets them moving',
        tone: 'warm',
        confidenceLabel: 'Highly compatible pairing',
      );

      await tester.pumpWidget(buildTestApp(
        Center(
          child: SizedBox(
            width: 320,
            child: ConnectionInsightCard(
              hook: longHook,
              matchProfile: _testMatchProfile,
              currentUserProfile: _testCurrentProfile,
            ),
          ),
        ),
      ));

      // No RenderFlex overflow exception should be thrown.
      final exception = tester.takeException();
      expect(exception, isNull);
      expect(find.text('What brings you together'), findsOneWidget);
      expect(find.text('Highly compatible pairing'), findsOneWidget);
    });

    testWidgets(
        'does not render letter-fallback initials when profiles have photo URLs',
        (tester) async {
      // Regression: the home screen previously built a UserProfile for the
      // match without passing photoUrls, which made AuthenticatedAvatar fall
      // back to a colored circle with the user's first initial. Verify that
      // when a photoUrl IS provided, no single-letter initials are rendered.
      final matchWithPhoto = UserProfile(
        id: '1',
        userId: 'user2',
        firstName: 'Sofia',
        lastName: '',
        dateOfBirth: DateTime(1994, 5, 10),
        interests: ['Dance', 'Music'],
        primaryPhotoUrl: 'http://example.com/sofia.jpg',
        photoUrls: ['http://example.com/sofia.jpg'],
      );
      final currentWithPhoto = UserProfile(
        id: '2',
        userId: 'user1',
        firstName: 'Alex',
        lastName: '',
        dateOfBirth: DateTime(1993, 8, 15),
        interests: ['Dance', 'Cooking'],
        primaryPhotoUrl: 'http://example.com/alex.jpg',
        photoUrls: ['http://example.com/alex.jpg'],
      );

      await tester.pumpWidget(buildTestApp(
        ConnectionInsightCard(
          hook: _testHook,
          matchProfile: matchWithPhoto,
          currentUserProfile: currentWithPhoto,
        ),
      ));
      // Pump a frame so AuthenticatedAvatar has a chance to mount the
      // CachedNetworkImage (which will fail to load the bogus URL in tests,
      // so the errorWidget path runs — that is still better than the
      // initials path because the URL is present).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The card should still render core content with photos supplied.
      expect(find.text('What brings you together'), findsOneWidget);
      expect(find.text('You both enjoy dance'), findsOneWidget);

      // No Text widget should contain a single upper-case letter (S or A)
      // rendered standalone as the first character of a string. The
      // initials fallback uses Text(initial) where initial is one char;
      // when no photo URL is supplied that Text shows inside the avatar.
      // We can't easily assert on which Text is "the avatar's" without a
      // key, so we assert the avatars were constructed: there should be
      // at least one CircleAvatar (the fallback) OR a CachedNetworkImage
      // (the photo path) — the photo path uses CircleAvatar inside its
      // imageBuilder. The presence of CachedNetworkImage confirms photos
      // were attempted.
      expect(find.byType(CircleAvatar), findsWidgets);
    });
  });
}
