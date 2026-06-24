import 'package:dejtingapp/services/psykolog_service.dart';
import 'package:dejtingapp/widgets/theme_visualization_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── helpers ────────────────────────────────────────────────────────────────

PsykologTheme _theme({
  required String label,
  required String axis,
  double intensity = 0.8,
}) =>
    PsykologTheme(
      id: label.hashCode,
      label: label,
      intensity: intensity,
      axis: axis,
      createdAt: DateTime(2024),
    );

Widget _wrap(Widget w) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: w)),
      ),
    );

// ── tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ThemeVisualizationWidget (T569)', () {
    testWidgets('renders nothing when themes list is empty', (tester) async {
      await tester.pumpWidget(_wrap(const ThemeVisualizationWidget(themes: [])));
      expect(find.byType(ThemeVisualizationWidget), findsOneWidget);
      // No axis headers rendered
      expect(find.text('Personlighet'), findsNothing);
      expect(find.text('Anknytning'), findsNothing);
      expect(find.text('Värderingar'), findsNothing);
    });

    testWidgets('renders axis header for each group present', (tester) async {
      final themes = [
        _theme(label: 'Öppenhet', axis: 'BigFive'),
        _theme(label: 'Trygg', axis: 'Attachment'),
        _theme(label: 'Äventyr', axis: 'Values'),
      ];
      await tester.pumpWidget(_wrap(ThemeVisualizationWidget(themes: themes)));

      expect(find.text('Personlighet'), findsOneWidget);
      expect(find.text('Anknytning'), findsOneWidget);
      expect(find.text('Värderingar'), findsOneWidget);
    });

    testWidgets('renders chip label for each theme', (tester) async {
      final themes = [
        _theme(label: 'Medveten', axis: 'BigFive', intensity: 0.9),
        _theme(label: 'Nyfiken', axis: 'BigFive', intensity: 0.6),
        _theme(label: 'Trygg', axis: 'Attachment', intensity: 0.7),
      ];
      await tester.pumpWidget(_wrap(ThemeVisualizationWidget(themes: themes)));

      expect(find.text('Medveten'), findsOneWidget);
      expect(find.text('Nyfiken'), findsOneWidget);
      expect(find.text('Trygg'), findsOneWidget);
    });

    testWidgets('only shows axis groups present in theme list', (tester) async {
      final themes = [
        _theme(label: 'Öppenhet', axis: 'BigFive'),
      ];
      await tester.pumpWidget(_wrap(ThemeVisualizationWidget(themes: themes)));

      expect(find.text('Personlighet'), findsOneWidget);
      // Absent axes should not render headers
      expect(find.text('Anknytning'), findsNothing);
      expect(find.text('Värderingar'), findsNothing);
    });

    testWidgets('caps themes at maxPerAxis', (tester) async {
      final themes = List.generate(
        12,
        (i) => _theme(label: 'Label$i', axis: 'BigFive', intensity: 0.5),
      );
      await tester.pumpWidget(_wrap(ThemeVisualizationWidget(themes: themes, maxPerAxis: 5)));

      // Only 5 out of 12 chip texts should be rendered
      int rendered = 0;
      for (int i = 0; i < 12; i++) {
        if (tester.any(find.text('Label$i'))) rendered++;
      }
      expect(rendered, equals(5));
    });

    testWidgets('sorts themes within axis by intensity descending', (tester) async {
      final themes = [
        _theme(label: 'Låg', axis: 'Values', intensity: 0.2),
        _theme(label: 'Hög', axis: 'Values', intensity: 0.9),
        _theme(label: 'Medel', axis: 'Values', intensity: 0.5),
      ];
      await tester.pumpWidget(_wrap(ThemeVisualizationWidget(themes: themes)));

      // All three should be visible
      expect(find.text('Hög'), findsOneWidget);
      expect(find.text('Medel'), findsOneWidget);
      expect(find.text('Låg'), findsOneWidget);
    });

    testWidgets('uses fallback meta for unknown axis', (tester) async {
      final themes = [
        _theme(label: 'Mystisk', axis: 'UnknownAxis'),
      ];
      await tester.pumpWidget(_wrap(ThemeVisualizationWidget(themes: themes)));
      expect(find.text('Mystisk'), findsOneWidget);
      expect(find.text('Övrigt'), findsOneWidget);
    });
  });
}
