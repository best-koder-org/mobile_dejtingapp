import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/psykolog_chat_screen.dart';
import 'package:dejtingapp/services/psykolog_service.dart';
import '../helpers/core_screen_test_helper.dart';

PsykologSessionInfo _mockSession() => PsykologSessionInfo(
      id: 1,
      sessionNumber: 1,
      startedAt: DateTime.now(),
      status: PsykologSessionStatus.active,
      themeCount: 0,
    );

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'read') return null;
        if (call.method == 'readAll') return <String, String>{};
        if (call.method == 'write') return null;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, dynamic>{};
        return null;
      },
    );
  });

  group('PsykologChatScreen', () {
    testWidgets('shows AppBar with session number', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: PsykologChatScreen(session: _mockSession())),
      );
      await tester.pump();

      expect(find.textContaining('Session 1'), findsOneWidget);
    });

    testWidgets('shows welcome assistant message', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: PsykologChatScreen(session: _mockSession())),
      );
      await tester.pump();

      expect(find.textContaining('Välkommen'), findsOneWidget);
    });

    testWidgets('shows text input field', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: PsykologChatScreen(session: _mockSession())),
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: PsykologChatScreen(session: _mockSession())),
      );
      await tester.pump();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows end session button', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: PsykologChatScreen(session: _mockSession())),
      );
      await tester.pump();

      expect(find.text('Avsluta'), findsOneWidget);
    });
  });
}
