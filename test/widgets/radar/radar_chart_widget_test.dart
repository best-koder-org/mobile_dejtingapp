import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/radar/radar_chart_widget.dart';

void main() {
  final sampleData = RadarChartData(
    labels: const ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
    values: const [0.8, 0.5, 0.9, 0.3, 0.7, 0.6, 0.4],
  );

  Widget buildWidget({double size = 280}) =>
      MaterialApp(home: Scaffold(body: Center(child: RadarChartWidget(data: sampleData, size: size))));

  group('RadarChartWidget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.byType(RadarChartWidget), findsOneWidget);
    });

    testWidgets('accepts custom size', (tester) async {
      await tester.pumpWidget(buildWidget(size: 200));
      await tester.pump();
      final widget = tester.widget<RadarChartWidget>(find.byType(RadarChartWidget));
      expect(widget.size, 200);
    });

    test('RadarChartData fromJson maps axes', () {
      final data = RadarChartData.fromRadarProfile({
        'emotionalStability': 0.8, 'socialEnergy': 0.5,
        'openness': 0.9, 'warmth': 0.3, 'lifeStructure': 0.7,
        'intimacyComfort': 0.6, 'conflictStyle': 0.4,
      });
      expect(data.values.length, 7);
      expect(data.values[0], 0.8);
      expect(data.labels[0], 'Trygghet');
    });
  });
}
