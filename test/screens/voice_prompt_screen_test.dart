import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/voice_prompt_screen.dart';
import '../helpers/core_screen_test_helper.dart';

/// Widget tests for VoicePromptScreen — Hinge-style recording flow.
///
/// Note: These tests verify the UI structure and widget renders.
/// Actual recording & upload requires device microphone (integration tests).
void main() {
  group('VoicePromptScreen', () {
    Widget buildSubject() =>
        buildCoreScreenTestApp(home: const VoicePromptScreen());

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows voice prompt title heading in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Voice Prompt'), findsOneWidget);
    });

    testWidgets('shows record button with microphone icon in idle state',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.text('Tap to record'), findsOneWidget);
    });

    testWidgets('shows prompt instruction text in idle state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('Record a short voice intro so matches can hear your vibe'),
        findsOneWidget,
      );
    });

    testWidgets('recording controls (stop/cancel) not visible in idle state',
        (tester) async {
      // Stop and cancel controls are only shown while recording is active.
      // In idle state neither the stop button nor the cancel-recording close
      // icon should be present (only the AppBar close icon is shown).
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop_rounded), findsNothing);
    });

    testWidgets('navigation back works via AppBar close button', (tester) async {
      // Push VoicePromptScreen onto a navigator stack so Navigator.pop() has
      // a destination to return to.
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VoicePromptScreen(),
                ),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(VoicePromptScreen), findsOneWidget);

      // Tap the AppBar close button — should pop back.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(VoicePromptScreen), findsNothing);
    });

    testWidgets('shows AppBar with close icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows initial timer at 0:00', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('no error message visible initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.style?.color == Colors.redAccent),
        ),
        findsNothing,
      );
    });

    testWidgets('no linear progress bar in idle state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('no uploading indicator in idle state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
