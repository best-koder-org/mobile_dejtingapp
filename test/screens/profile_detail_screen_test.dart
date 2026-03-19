import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/profile_detail_screen.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/widgets/voice/voice_prompt_player.dart';
import '../helpers/core_screen_test_helper.dart';

MatchCandidate _dummyCandidate() => MatchCandidate(
      userId: 'test-user-1',
      displayName: 'Alice',
      age: 28,
      bio: 'Coffee lover & adventurer',
      city: 'Stockholm',
      compatibility: 0.85,
      interestsOverlap: ['hiking', 'coffee'],
      occupation: 'Engineer',
      isVerified: true,
    );

MatchCandidate _dummyCandidateWithPhotos() => MatchCandidate(
      userId: 'test-user-2',
      displayName: 'Alice',
      age: 28,
      bio: 'Coffee lover & adventurer',
      city: 'Stockholm',
      compatibility: 0.85,
      interestsOverlap: ['hiking', 'coffee'],
      occupation: 'Engineer',
      isVerified: true,
      photoUrls: [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ],
    );

void main() {
  setUpAll(() => setupTestHttpOverrides());

  group('ProfileDetailScreen', () {
    testWidgets('renders scaffold with candidate', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows placeholder with first letter when no photos', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // No photos => placeholder shows first letter of name
      expect(find.text('A'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows bio text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Coffee lover'), findsOneWidget);
    });

    testWidgets('shows interests', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('hiking'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows compatibility badge', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('85'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Like and Skip buttons when not matched', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(
            candidate: _dummyCandidate(),
            isMatched: false,
            onLike: () {},
            onSkip: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('shows user name in photo gallery overlay', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidateWithPhotos()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Name overlay is rendered on top of the photo gallery
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows user age in photo gallery overlay', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidateWithPhotos()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Age overlay is rendered alongside the name in the photo gallery
      expect(find.text('28'), findsOneWidget);
    });

    testWidgets('shows photo gallery PageView when photos are provided', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidateWithPhotos()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('shows voice prompt player when voice intro is set', (tester) async {
      final candidate = MatchCandidate(
        userId: 'test-user-3',
        displayName: 'Alice',
        age: 28,
        interestsOverlap: const [],
        voicePromptUrl: 'https://example.com/voice.mp3',
      );
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: candidate),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(VoicePromptPlayer), findsOneWidget);
    });

    testWidgets('shows message button when profile is already matched', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(
            candidate: _dummyCandidate(),
            isMatched: true,
            onMessage: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // The message button uses ElevatedButton.icon with chat_bubble icon
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    testWidgets('shows occupation in vitals section', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: ProfileDetailScreen(candidate: _dummyCandidate()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Occupation chip appears exactly once in the vitals section
      expect(find.textContaining('Engineer'), findsOneWidget);
    });
  });
}
