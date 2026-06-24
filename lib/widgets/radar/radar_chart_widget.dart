import 'dart:math';
import 'package:flutter/material.dart';

/// A 7-axis radar chart rendered with CustomPainter.
///
/// Axes: EmotionalStability, SocialEnergy, Openness, Warmth,
///       LifeStructure, IntimacyComfort, ConflictStyle
class RadarChartWidget extends StatelessWidget {
  final RadarChartData data;
  final double size;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;
  final Color gridColor;

  const RadarChartWidget({
    super.key,
    required this.data,
    this.size = 280,
    this.fillColor = const Color(0xFF6B4EFF),
    this.strokeColor = const Color(0xFF6B4EFF),
    this.labelColor = const Color(0xFFB0A8C0),
    this.gridColor = const Color(0xFF2A2A3A),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _RadarPainter(
          values: data.values,
          labels: data.labels,
          fillColor: fillColor,
          strokeColor: strokeColor,
          labelColor: labelColor,
          gridColor: gridColor,
        ),
      ),
    );
  }
}

/// Data model for the radar chart.
class RadarChartData {
  final List<String> labels;
  final List<double> values; // 0.0–1.0

  const RadarChartData({required this.labels, required this.values})
      : assert(labels.length == values.length),
        assert(labels.length >= 3);

  factory RadarChartData.fromRadarProfile(Map<String, dynamic> json) {
    return RadarChartData(
      labels: const [
        'Trygghet',
        'Energi',
        'Öppenhet',
        'Värme',
        'Struktur',
        'Intimitet',
        'Konflikt',
      ],
      values: [
        (json['emotionalStability'] as num?)?.toDouble() ?? 0.5,
        (json['socialEnergy'] as num?)?.toDouble() ?? 0.5,
        (json['openness'] as num?)?.toDouble() ?? 0.5,
        (json['warmth'] as num?)?.toDouble() ?? 0.5,
        (json['lifeStructure'] as num?)?.toDouble() ?? 0.5,
        (json['intimacyComfort'] as num?)?.toDouble() ?? 0.5,
        (json['conflictStyle'] as num?)?.toDouble() ?? 0.5,
      ],
    );
  }
}

// ── CustomPainter ────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;
  final Color gridColor;

  _RadarPainter({
    required this.values,
    required this.labels,
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final n = values.length;

    final points = <Offset>[];

    // Calculate data points
    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final val = values[i].clamp(0.0, 1.0);
      final r = radius * val;
      points.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }

    // Draw grid rings
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final gridPaths = [0.25, 0.5, 0.75, 1.0];
    for (final level in gridPaths) {
      final ringPath = Path();
      for (var i = 0; i <= n; i++) {
        final angle = (2 * pi * (i % n) / n) - pi / 2;
        final r = radius * level;
        final point = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        if (i == 0) {
          ringPath.moveTo(point.dx, point.dy);
        } else {
          ringPath.lineTo(point.dx, point.dy);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    // Draw axis lines from center to each vertex
    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        axisPaint,
      );
    }

    // Draw data fill
    if (values.any((v) => v > 0)) {
      final fillPath = Path();
      for (var i = 0; i < points.length; i++) {
        if (i == 0) {
          fillPath.moveTo(points[i].dx, points[i].dy);
        } else {
          fillPath.lineTo(points[i].dx, points[i].dy);
        }
      }
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = fillColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = strokeColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Draw data points
    for (final p in points) {
      canvas.drawCircle(p, 4.5, Paint()..color = strokeColor..style = PaintingStyle.fill);
      canvas.drawCircle(p, 6, Paint()..color = strokeColor.withValues(alpha: 0.25)..style = PaintingStyle.fill);
    }

    // Draw labels
    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final labelRadius = radius + 28;

      // Position label outside the chart
      var x = center.dx + labelRadius * cos(angle);
      var y = center.dy + labelRadius * sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 70);

      // Center the text around the anchor point
      x -= tp.width / 2;
      y -= tp.height / 2;

      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values || old.labels != labels;
}
