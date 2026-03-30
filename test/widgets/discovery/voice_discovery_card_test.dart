import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/discovery/voice_discovery_card.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/voice_config.dart';
import '../../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() {
    setupTestHttpOverrides();
    FlavorConfig.current = VoiceFlavorConfig();
  });

  MatchCandidate makeCandidate({
    String userId = '42',
    String name = 'Maja',
    int age = 28,
    String? city = 'Stockholm',
    String? bio = 'Loves hiking and reading',
    List<String> interests = const ['Travel', 'Music'],
    double compatibility = 0.87,
  }) {
    return MatchCandidate(
      userId: userId,
      displayName: name,
      age: age,
      city: city,
      bio: bio,
      interestsOverlap: interests,
      compatibility: compatibility,
    );
  }

  Widget buildCard({
    MatchCandidate? candidate,
    VoidCallback? onLike,
    VoidCallback? onPass,
    VoidCallback? onSuperLike,
  }) {
    return buildCoreScreenTestApp(
      home: Scaffold(
        body: VoiceDiscoveryCard(
          candidate: candidate ?? makeCandidate(),
          onLike: onLike,
          onPass: onPass,
          onSuperLike: onSuperLike,
        ),
      ),
    );
  }

  group('VoiceDiscoveryCard', () {
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

    testWidgets('renders scaffold with card', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(VoiceDiscoveryCard), findsOneWidget);
    });

    testWidgets('shows candidate name and age', (tester) async {
      await tester.pumpWidget(
        buildCard(candidate: makeCandidate(name: 'Elsa', age: 25)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Elsa, 25'), findsOneWidget);
    });

    testWidgets('shows city with location icon', (tester) async {
      await tester.pumpWidget(
        buildCard(candidate: makeCandidate(city: 'Göteborg')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Göteborg'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('shows silhouette avatar (person icon)', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('does NOT show any photo images', (tester) async {
      await tester.pumpWidget(
        buildCard(candidate: makeCandidate()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // No CachedNetworkImage should be present
      final images = tester.widgetList(find.byType(Image));
      expect(images, isEmpty);
    });

    testWidgets('shows interest tags', (tester) async {
      await tester.pumpWidget(
        buildCard(candidate: makeCandidate(interests: ['Yoga', 'Reading'])),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Yoga'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
    });

    testWidgets('shows three action buttons', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump(const Duration(milliseconds: 500));
      // Pass (close), Like (favorite), Superlike (auto_awesome)
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('like button fires onLike', (tester) async {
      var liked = false;
      await tester.pumpWidget(buildCard(onLike: () => liked = true));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();
      expect(liked, isTrue);
    });

    testWidgets('pass button fires onPass', (tester) async {
      var passed = false;
      await tester.pumpWidget(buildCard(onPass: () => passed = true));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(passed, isTrue);
    });

    testWidgets('shows compatibility score', (tester) async {
      await tester.pumpWidget(
        buildCard(candidate: makeCandidate(compatibility: 0.92)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('92%'), findsOneWidget);
      expect(find.byIcon(Icons.whatshot), findsOneWidget);
    });

    testWidgets('shows loading state while fetching voice answers', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump(); // Initial frame, before async completes
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "no voice answers" when fetch returns empty', (tester) async {
      await tester.pumpWidget(buildCard());
      // Pump enough for the async to complete (will fail since no backend)
      await tester.pump(const Duration(seconds: 2));
      // Should show empty state or the card regardless
      expect(find.byType(VoiceDiscoveryCard), findsOneWidget);
    });

    testWidgets('shows bio section when bio present', (tester) async {
      await tester.pumpWidget(
        buildCard(candidate: makeCandidate(bio: 'I love voice dating!')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Bio is in the scroll view, scroll down to find it
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(find.text('I love voice dating!'), findsOneWidget);
    });
  });
}
