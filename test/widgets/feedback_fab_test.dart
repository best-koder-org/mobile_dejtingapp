import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/services/feedback_service.dart';
import 'package:dejtingapp/widgets/feedback_fab.dart';

class _FakeFeedbackService implements FeedbackService {
  int callCount = 0;
  Map<String, dynamic>? lastArgs;
  bool throwOnSubmit = false;

  @override
  Future<Map<String, dynamic>> submit({
    File? audioFile,
    String? noteText,
    int durationSec = 0,
    String? screen,
    String? appVersion,
  }) async {
    callCount++;
    lastArgs = {
      'audioFile': audioFile?.path,
      'noteText': noteText,
      'durationSec': durationSec,
      'screen': screen,
      'appVersion': appVersion,
    };
    if (throwOnSubmit) throw Exception('boom');
    return {'id': 42};
  }

  @override
  // ignore: unused_element
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(children: [const SizedBox.expand(), child]),
    ),
  );
}

void main() {
  testWidgets('FeedbackFab is visible in debug mode', (tester) async {
    await tester.pumpWidget(_wrap(const FeedbackFab()));
    expect(find.byKey(const Key('feedback-fab')), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('Tapping FAB opens the feedback sheet', (tester) async {
    await tester.pumpWidget(_wrap(const FeedbackFab()));
    await tester.tap(find.byKey(const Key('feedback-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feedback-mic-hold')), findsOneWidget);
    expect(find.byKey(const Key('feedback-note-input')), findsOneWidget);
    expect(find.byKey(const Key('feedback-send-button')), findsOneWidget);
  });

  testWidgets('Sending text-only feedback calls service.submit and shows toast',
      (tester) async {
    final fake = _FakeFeedbackService();
    await tester.pumpWidget(_wrap(FeedbackFab(service: fake)));

    await tester.tap(find.byKey(const Key('feedback-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('feedback-note-input')), 'The badge is great!');
    await tester.tap(find.byKey(const Key('feedback-send-button')));
    await tester.pumpAndSettle();

    expect(fake.callCount, 1);
    expect(fake.lastArgs?['noteText'], 'The badge is great!');
    expect(fake.lastArgs?['audioFile'], isNull);
    expect(find.text('Feedback sent — thanks!'), findsOneWidget);
  });

  testWidgets('Send without note or audio shows validation snackbar',
      (tester) async {
    final fake = _FakeFeedbackService();
    await tester.pumpWidget(_wrap(FeedbackFab(service: fake)));

    await tester.tap(find.byKey(const Key('feedback-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feedback-send-button')));
    await tester.pumpAndSettle();

    expect(fake.callCount, 0);
    expect(find.text('Record a memo or type a note first'), findsOneWidget);
  });

  testWidgets('Service failure shows error snackbar', (tester) async {
    final fake = _FakeFeedbackService()..throwOnSubmit = true;
    await tester.pumpWidget(_wrap(FeedbackFab(service: fake)));

    await tester.tap(find.byKey(const Key('feedback-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('feedback-note-input')), 'crash test');
    await tester.tap(find.byKey(const Key('feedback-send-button')));
    await tester.pumpAndSettle();

    expect(fake.callCount, 1);
    expect(find.textContaining('Feedback failed'), findsOneWidget);
  });
}
