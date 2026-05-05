import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/compatibility_bar_comparison.dart';

void main() {
  Widget buildWidget({
    required List<DimensionScore> dimensions,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.dark(),
      home: Scaffold(
        body: CompatibilityBarComparison(dimensions: dimensions),
      ),
    );
  }

  group('CompatibilityBarComparison', () {
    testWidgets('renders all dimension labels', (tester) async {
      await tester.pumpWidget(buildWidget(dimensions: const [
        DimensionScore(label: 'Openness', userScore: 0.8, matchScore: 0.6),
        DimensionScore(
            label: 'Conscientiousness', userScore: 0.5, matchScore: 0.7),
        DimensionScore(label: 'Extraversion', userScore: 0.3, matchScore: 0.9),
        DimensionScore(label: 'Agreeableness', userScore: 0.6, matchScore: 0.4),
        DimensionScore(label: 'Values', userScore: 0.75, matchScore: 0.55),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Openness'), findsOneWidget);
      expect(find.text('Conscientiousness'), findsOneWidget);
      expect(find.text('Extraversion'), findsOneWidget);
      expect(find.text('Agreeableness'), findsOneWidget);
      expect(find.text('Values'), findsOneWidget);
    });

    testWidgets('handles empty dimensions list without error', (tester) async {
      await tester.pumpWidget(buildWidget(dimensions: const []));
      await tester.pumpAndSettle();

      expect(find.byType(CompatibilityBarComparison), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('clamps out-of-range scores in semantics labels', (tester) async {
      await tester.pumpWidget(buildWidget(dimensions: const [
        DimensionScore(
            label: 'Agreeableness', userScore: 1.5, matchScore: -0.2),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Agreeableness'), findsOneWidget);

      // Scores are clamped: 1.5 → 100 %, -0.2 → 0 %
      final semanticsWidgets =
          tester.widgetList<Semantics>(find.byType(Semantics));
      final labels = semanticsWidgets
          .map((s) => s.label)
          .whereType<String>()
          .toList();

      expect(
        labels.any((l) => l.contains('100 percent') && l.contains('0 percent')),
        isTrue,
      );
    });

    testWidgets('semantics label matches expected format', (tester) async {
      await tester.pumpWidget(buildWidget(dimensions: const [
        DimensionScore(label: 'Openness', userScore: 0.8, matchScore: 0.6),
      ]));
      await tester.pumpAndSettle();

      final semanticsWidgets =
          tester.widgetList<Semantics>(find.byType(Semantics));
      final labels = semanticsWidgets
          .map((s) => s.label)
          .whereType<String>()
          .toList();

      expect(
        labels.contains(
            'Openness — you 80 percent, match 60 percent'),
        isTrue,
      );
    });

    testWidgets('custom theme colours are used for bars', (tester) async {
      const customPrimary = Color(0xFFE91E63);
      const customSecondary = Color(0xFF009688);
      final customTheme = ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: customPrimary,
          secondary: customSecondary,
        ),
      );

      await tester.pumpWidget(buildWidget(
        dimensions: const [
          DimensionScore(label: 'Values', userScore: 0.7, matchScore: 0.5),
        ],
        theme: customTheme,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CompatibilityBarComparison), findsOneWidget);

      final bars = tester
          .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator))
          .toList();

      expect(bars.any((b) => b.color == customPrimary), isTrue);
      expect(bars.any((b) => b.color == customSecondary), isTrue);
    });

    testWidgets('renders two progress bars per dimension', (tester) async {
      await tester.pumpWidget(buildWidget(dimensions: const [
        DimensionScore(label: 'Openness', userScore: 0.8, matchScore: 0.6),
        DimensionScore(label: 'Attachment', userScore: 0.5, matchScore: 0.3),
      ]));
      await tester.pumpAndSettle();

      // Two dimensions × two bars each = four LinearProgressIndicators
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });

    testWidgets('bars reach target values after animation completes',
        (tester) async {
      await tester.pumpWidget(buildWidget(dimensions: const [
        DimensionScore(label: 'Openness', userScore: 0.8, matchScore: 0.6),
      ]));
      await tester.pumpAndSettle();

      final bars = tester
          .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator))
          .toList();

      // Two bars: user bar (0.8) then match bar (0.6)
      expect(bars.length, equals(2));
      expect(bars[0].value, closeTo(0.8, 0.01));
      expect(bars[1].value, closeTo(0.6, 0.01));
    });
  });
}
