import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/discovery/profile_card.dart';
import '../../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() => setupTestHttpOverrides());

  Widget buildCard({
    String name = 'Anna',
    int age = 28,
    String bio = 'Love hiking and coffee.',
    List<String> photoUrls = const [],
    int? matchScore,
    VoidCallback? onLike,
    VoidCallback? onPass,
  }) {
    return buildCoreScreenTestApp(
      home: Scaffold(
        body: Center(
          child: ProfileCard(
            name: name,
            age: age,
            bio: bio,
            photoUrls: photoUrls,
            matchScore: matchScore,
            onLike: onLike,
            onPass: onPass,
          ),
        ),
      ),
    );
  }

  group('ProfileCard', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.byType(ProfileCard), findsOneWidget);
    });

    testWidgets('shows name and age', (tester) async {
      await tester.pumpWidget(buildCard(name: 'Emma', age: 25));
      await tester.pump();
      expect(find.text('Emma, 25'), findsOneWidget);
    });

    testWidgets('shows bio text', (tester) async {
      await tester.pumpWidget(buildCard(bio: 'I love dancing and cooking.'));
      await tester.pump();
      expect(find.text('I love dancing and cooking.'), findsOneWidget);
    });

    testWidgets('shows match score badge when provided', (tester) async {
      await tester.pumpWidget(buildCard(matchScore: 87));
      await tester.pump();
      expect(find.text('87%'), findsOneWidget);
      expect(find.byIcon(Icons.whatshot), findsOneWidget);
    });

    testWidgets('does not show match score badge when not provided', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.byIcon(Icons.whatshot), findsNothing);
    });

    testWidgets('shows photo placeholder when photoUrls is empty', (tester) async {
      await tester.pumpWidget(buildCard(photoUrls: const []));
      await tester.pump();
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('like button calls onLike callback', (tester) async {
      var wasLiked = false;
      await tester.pumpWidget(buildCard(onLike: () => wasLiked = true));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite));
      expect(wasLiked, isTrue);
    });

    testWidgets('pass button calls onPass callback', (tester) async {
      var wasPassed = false;
      await tester.pumpWidget(buildCard(onPass: () => wasPassed = true));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      expect(wasPassed, isTrue);
    });

    testWidgets('card has rounded corners decoration', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      final containers = tester.widgetList<Container>(find.byType(Container));
      final roundedCard = containers.where((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          final br = dec.borderRadius;
          if (br is BorderRadius) {
            return br.topLeft.x == 24 &&
                br.topRight.x == 24 &&
                br.bottomLeft.x == 24 &&
                br.bottomRight.x == 24;
          }
        }
        return false;
      });
      expect(roundedCard, isNotEmpty,
          reason: 'Card should have uniformly rounded corners with radius 24');
    });
  });
}
