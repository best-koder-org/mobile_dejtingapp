import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/messages_screen.dart';
import 'package:dejtingapp/models.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  testWidgets('MessagesScreen renders scaffold', (tester) async {
    await tester.pumpWidget(
      buildCoreScreenTestApp(home: const MessagesScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Scaffold), findsWidgets);
  });
}

