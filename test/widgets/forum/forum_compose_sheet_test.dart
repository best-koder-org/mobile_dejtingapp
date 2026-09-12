import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/services/forum_service.dart';
import 'package:dejtingapp/widgets/forum/forum_compose_sheet.dart';

/// The recorder and transcriber are injected as callbacks, so these tests exercise the whole
/// dictation interaction without touching the microphone plugin or the network.
void main() {
  Widget harness({
    Future<void> Function()? onStart,
    Future<String?> Function()? onStop,
    Future<ForumResult<int>> Function(String text, String channel)? onSubmit,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: ForumComposeSheet(
          onSubmit: onSubmit ?? (_, __) async => ForumResult.success(1, 201),
          onStartDictation: onStart,
          onStopDictation: onStop,
        ),
      ),
    );
  }

  group('ForumComposeSheet dictation', () {
    testWidgets('hides the microphone when dictation is unavailable', (tester) async {
      // Web builds cannot record, and the screen passes null callbacks there.
      await tester.pumpWidget(harness());

      expect(find.byIcon(Icons.mic_none), findsNothing);
      expect(find.byIcon(Icons.stop_circle), findsNothing);
    });

    testWidgets('shows the microphone when dictation is available', (tester) async {
      await tester.pumpWidget(harness(
        onStart: () async {},
        onStop: () async => null,
      ));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('first tap records, second tap stops and fills the field', (tester) async {
      var started = 0;
      var stopped = 0;

      await tester.pumpWidget(harness(
        onStart: () async => started++,
        onStop: () async {
          stopped++;
          return 'Dikterad text';
        },
      ));

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();

      expect(started, 1);
      expect(stopped, 0);
      // Now recording: the icon becomes a stop button and the hint changes.
      expect(find.byIcon(Icons.stop_circle), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsNothing);

      await tester.tap(find.byIcon(Icons.stop_circle));
      await tester.pumpAndSettle();

      expect(stopped, 1);
      expect(find.text('Dikterad text'), findsOneWidget);
      // Back to idle, ready for another take.
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('a failed transcription leaves the field alone and returns to idle',
        (tester) async {
      await tester.pumpWidget(harness(
        onStart: () async {},
        onStop: () async => null, // caller already explained why
      ));

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.stop_circle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    });

    testWidgets('the transcript is editable and capped at 200 characters', (tester) async {
      await tester.pumpWidget(harness(
        onStart: () async {},
        onStop: () async => 'kort text',
      ));

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.stop_circle));
      await tester.pumpAndSettle();

      // Dictation fills the same capped field the user could have typed into.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, ForumService.maxTextLength);
      expect(field.controller!.text, 'kort text');
    });
  });
}
