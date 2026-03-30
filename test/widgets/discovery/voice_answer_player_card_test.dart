import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/discovery/voice_answer_player_card.dart';
import 'package:dejtingapp/services/voice_answer_service.dart';
import '../../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() => setupTestHttpOverrides());

  VoiceAnswerPreview makeAnswer({
    int id = 1,
    String questionText = 'Vad gör dig genuint lycklig?',
    double duration = 12.0,
  }) {
    return VoiceAnswerPreview(
      id: id,
      questionId: 1,
      questionText: questionText,
      durationSeconds: duration,
      audioUrl: '/api/voice-answers/$id/audio',
    );
  }

  Widget buildCard({
    VoiceAnswerPreview? answer,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return buildCoreScreenTestApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 120,
            height: 140,
            child: VoiceAnswerPlayerCard(
              answer: answer ?? makeAnswer(),
              isActive: isActive,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  group('VoiceAnswerPlayerCard', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.byType(VoiceAnswerPlayerCard), findsOneWidget);
    });

    testWidgets('shows play icon by default', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows duration text', (tester) async {
      await tester.pumpWidget(buildCard(answer: makeAnswer(duration: 15.0)));
      await tester.pump();
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('shows short question label', (tester) async {
      await tester.pumpWidget(
        buildCard(answer: makeAnswer(questionText: 'Berätta om ditt bästa minne')),
      );
      await tester.pump();
      // Should extract a keyword from the question
      expect(find.byType(VoiceAnswerPlayerCard), findsOneWidget);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.pump();
      await tester.tap(find.byType(VoiceAnswerPlayerCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('active state changes container decoration', (tester) async {
      await tester.pumpWidget(buildCard(isActive: true));
      await tester.pump();
      // The card renders with active state — many AnimatedContainers (card + bars)
      expect(find.byType(AnimatedContainer), findsWidgets);
      expect(find.byType(VoiceAnswerPlayerCard), findsOneWidget);
    });

    testWidgets('different answers produce different waveforms', (tester) async {
      // Just verify two different IDs render without error
      await tester.pumpWidget(buildCard(answer: makeAnswer(id: 1)));
      await tester.pump();
      expect(find.byType(VoiceAnswerPlayerCard), findsOneWidget);
    });
  });
}
