import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/widgets/radar_chart_widget.dart';

void main() {
  const testProfile = RadarProfileData(
    emotionalStability: 0.8,
    socialEnergy: 0.6,
    openness: 0.7,
    warmth: 0.9,
    lifeStructure: 0.5,
    intimacyComfort: 0.65,
    conflictStyle: 0.4,
    confidence: 0.9,
  );

  const compareProfile = RadarProfileData(
    emotionalStability: 0.6,
    socialEnergy: 0.8,
    openness: 0.5,
    warmth: 0.7,
    lifeStructure: 0.6,
    intimacyComfort: 0.75,
    conflictStyle: 0.55,
    confidence: 0.7,
  );

  group('RadarChartWidget', () {
    testWidgets('renders without compare profile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChartWidget(profile: testProfile),
            ),
          ),
        ),
      );
      expect(find.byType(RadarChartWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with compare overlay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChartWidget(
                profile: testProfile,
                compareProfile: compareProfile,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(RadarChartWidget), findsOneWidget);
    });

    testWidgets('respects size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChartWidget(profile: testProfile, size: 200),
            ),
          ),
        ),
      );
      final widget = tester.widget<RadarChartWidget>(find.byType(RadarChartWidget));
      expect(widget.size, 200);
    });

    testWidgets('showLabels defaults to true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChartWidget(profile: testProfile),
            ),
          ),
        ),
      );
      final widget = tester.widget<RadarChartWidget>(find.byType(RadarChartWidget));
      expect(widget.showLabels, isTrue);
    });

    testWidgets('low confidence profile renders without error', (tester) async {
      const lowConfProfile = RadarProfileData(
        emotionalStability: 0.5,
        socialEnergy: 0.5,
        openness: 0.5,
        warmth: 0.5,
        lifeStructure: 0.5,
        intimacyComfort: 0.5,
        conflictStyle: 0.5,
        confidence: 0.1,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChartWidget(profile: lowConfProfile),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('RadarProfileData', () {
    test('values list has 7 items', () {
      expect(testProfile.values.length, 7);
    });

    test('axisLabels has 7 labels', () {
      expect(RadarProfileData.axisLabels.length, 7);
    });
  });
}
