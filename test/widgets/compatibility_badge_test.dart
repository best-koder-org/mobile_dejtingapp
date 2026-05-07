import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/compatibility_badge.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('CompatibilityBadge', () {
    testWidgets('renders integer percentage for low score (≤30%)',
        (tester) async {
      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 0.21)));
      expect(find.text('21%'), findsOneWidget);
    });

    testWidgets('renders integer percentage for mid score (50%)',
        (tester) async {
      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 0.50)));
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('renders integer percentage for high score (≥85%)',
        (tester) async {
      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 0.87)));
      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('handles boundary values 0% and 100%', (tester) async {
      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 0.0)));
      expect(find.text('0%'), findsOneWidget);

      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 1.0)));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('clamps out-of-range scores', (tester) async {
      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: -0.5)));
      expect(find.text('0%'), findsOneWidget);

      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 1.7)));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        _wrap(const CompatibilityBadge(score: 0.6, size: 96)),
      );
      final box = tester.getSize(find.byType(CompatibilityBadge));
      expect(box.width, 96);
      expect(box.height, 96);
    });

    testWidgets('exposes Semantics label with percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const CompatibilityBadge(score: 0.87)));
      final semantics = tester.getSemantics(find.byType(CompatibilityBadge));
      expect(semantics.label, contains('Compatibility 87 percent'));
      handle.dispose();
    });
  });
}
