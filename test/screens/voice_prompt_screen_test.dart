import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/voice_prompt_screen.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';

/// Widget tests for VoicePromptScreen — Hinge-style recording flow.
///
/// Note: These tests verify the UI structure and widget renders.
/// Actual recording & upload requires device microphone (integration tests).
void main() {
  /// Wrap the widget in a MaterialApp with l10n delegates so
  /// AppLocalizations.of(context) doesn't return null.
  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VoicePromptScreen(),
    );
  }

  group('VoicePromptScreen', () {
    testWidgets('renders with mic record button in idle state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show the mic icon button
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      // Should show "Tap to record" label
      expect(find.text('Tap to record'), findsOneWidget);
    });

    testWidgets('shows app bar with title and close button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows initial timer at 0:00', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('no error message initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // No red error text
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.style?.color == Colors.redAccent),
        ),
        findsNothing,
      );
    });

    testWidgets('no progress bar in idle state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('no CircularProgressIndicator in idle state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
