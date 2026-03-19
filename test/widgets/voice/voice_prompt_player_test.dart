import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/voice/voice_prompt_player.dart';
import '../../helpers/core_screen_test_helper.dart';

void main() {
  setUpAll(() => setupTestHttpOverrides());

  Widget buildPlayer({
    String voicePromptUrl = 'https://example.com/prompt.m4a',
    String displayName = 'Alice Andersson',
  }) {
    return buildCoreScreenTestApp(
      home: Scaffold(
        body: Center(
          child: VoicePromptPlayer(
            voicePromptUrl: voicePromptUrl,
            displayName: displayName,
          ),
        ),
      ),
    );
  }

  group('VoicePromptPlayer', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildPlayer());
      await tester.pump();
      expect(find.byType(VoicePromptPlayer), findsOneWidget);
    });

    testWidgets('shows play button initially', (tester) async {
      await tester.pumpWidget(buildPlayer());
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
    });

    testWidgets('shows VOICE PROMPT label', (tester) async {
      await tester.pumpWidget(buildPlayer());
      await tester.pump();
      expect(find.text('VOICE PROMPT'), findsOneWidget);
    });

    testWidgets('shows subtitle with display name', (tester) async {
      await tester.pumpWidget(buildPlayer(displayName: 'Alice Andersson'));
      await tester.pump();
      expect(find.text("Hear Alice's voice"), findsOneWidget);
    });

    testWidgets('shows duration indicator', (tester) async {
      await tester.pumpWidget(buildPlayer());
      await tester.pump();
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('shows Play text on button', (tester) async {
      await tester.pumpWidget(buildPlayer());
      await tester.pump();
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('waveform container is rendered', (tester) async {
      await tester.pumpWidget(buildPlayer());
      await tester.pump();
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final waveformBox = sizedBoxes.where((s) => s.height == 40);
      expect(waveformBox, isNotEmpty, reason: 'Waveform SizedBox with height 40 should exist');
    });
  });
}
