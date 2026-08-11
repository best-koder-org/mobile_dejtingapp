import 'dart:math';
import 'package:flutter/material.dart';

/// A 7-axis radar chart rendered with CustomPainter.
///
/// T630: Confidence parameter controls opacity tiers:
///   <60% → faded + dashed lines
///   60-80% → soft
///   80-90% → vivid
///   95%+ → gold accent ring
/// Supports animated transitions via [animationValue] (0.0→1.0).
///
/// T631: Optional [comparisonData] shows a previous polygon
/// in muted tones. Shows "Prior" label when comparison is active.
class RadarChartWidget extends StatefulWidget {
  final RadarChartData data;
  final RadarChartData? comparisonData;
  final double size;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;
  final Color gridColor;
  final double? confidence;
  final Animation<double>? animation;

  const RadarChartWidget({
    super.key,
    required this.data,
    this.comparisonData,
    this.size = 280,
    this.fillColor = const Color(0xFF6B4EFF),
    this.strokeColor = const Color(0xFF6B4EFF),
    this.labelColor = const Color(0xFFB0A8C0),
    this.gridColor = const Color(0xFF2A2A3A),
    this.confidence,
    this.animation,
  });

  @override
  State<RadarChartWidget> createState() => _RadarChartWidgetState();
}

class _RadarChartWidgetState extends State<RadarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _anim = widget.animation ??
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conf = widget.confidence ?? 1.0;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RadarPainter(
              values: widget.data.values,
              labels: widget.data.labels,
              comparisonValues: widget.comparisonData?.values,
              fillColor: widget.fillColor,
              strokeColor: widget.strokeColor,
              labelColor: widget.labelColor,
              gridColor: widget.gridColor,
              confidence: conf,
              progress: _anim.value,
            ),
          ),
        );
      },
    );
  }
}

/// Data model for the radar chart.
class RadarChartData {
  final List<String> labels;
  final List<double> values;

  const RadarChartData({required this.labels, required this.values})
      : assert(labels.length == values.length),
        assert(labels.length >= 3);

  factory RadarChartData.fromRadarProfile(Map<String, dynamic> json,
      {bool usePrevious = false}) {
    final source = usePrevious && json['previousAxes'] != null
        ? json['previousAxes'] as Map<String, dynamic>
        : json['axes'] as Map<String, dynamic>? ?? json;
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
        (source['emotionalStability'] as num?)?.toDouble() ?? 0.5,
        (source['socialEnergy'] as num?)?.toDouble() ?? 0.5,
        (source['openness'] as num?)?.toDouble() ?? 0.5,
        (source['warmth'] as num?)?.toDouble() ?? 0.5,
        (source['lifeStructure'] as num?)?.toDouble() ?? 0.5,
        (source['intimacyComfort'] as num?)?.toDouble() ?? 0.5,
        (source['conflictStyle'] as num?)?.toDouble() ?? 0.5,
      ],
    );
  }
}

// ── CustomPainter ────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<double>? comparisonValues;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;
  final Color gridColor;
  final double confidence;
  final double progress;

  _RadarPainter({
    required this.values,
    required this.labels,
    this.comparisonValues,
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
    required this.gridColor,
    required this.confidence,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final n = values.length;

    // ── Calculate opacity tier ─────────────────────────────────
    final double fillAlpha;
    final double strokeAlpha;
    final bool useGoldRing;
    final bool useDashed;
    final Color finalStrokeColor;

    if (confidence >= 0.95) {
      fillAlpha = 0.3;
      strokeAlpha = 1.0;
      useGoldRing = true;
      useDashed = false;
      finalStrokeColor = const Color(0xFFFFD700);
    } else if (confidence >= 0.80) {
      fillAlpha = 0.3;
      strokeAlpha = 0.8;
      useGoldRing = false;
      useDashed = false;
      finalStrokeColor = strokeColor;
    } else if (confidence >= 0.60) {
      fillAlpha = 0.18;
      strokeAlpha = 0.5;
      useGoldRing = false;
      useDashed = false;
      finalStrokeColor = strokeColor;
    } else {
      fillAlpha = 0.08;
      strokeAlpha = 0.25;
      useGoldRing = false;
      useDashed = true;
      finalStrokeColor = strokeColor;
    }

    // ── Draw comparison (previous) polygon if available ─────────
    if (comparisonValues != null && comparisonValues!.length == n) {
      final prevPoints = <Offset>[];
      for (var i = 0; i < n; i++) {
        final angle = (2 * pi * i / n) - pi / 2;
        final val = comparisonValues![i].clamp(0.0, 1.0) * progress;
        final r = radius * val;
        prevPoints.add(Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        ));
      }

      final prevFill = Paint()
        ..color = Colors.blueGrey.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      final prevPath = Path()..moveTo(prevPoints[0].dx, prevPoints[0].dy);
      for (var i = 1; i < n; i++) {
        prevPath.lineTo(prevPoints[i].dx, prevPoints[i].dy);
      }
      prevPath.close();
      canvas.drawPath(prevPath, prevFill);

      final prevStroke = Paint()
        ..color = Colors.blueGrey.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(prevPath, prevStroke);

      for (final p in prevPoints) {
        canvas.drawCircle(p, 2, Paint()..color = Colors.blueGrey.withValues(alpha: 0.35));
      }
    }

    // ── Draw main data polygon ─────────────────────────────────
    final dataPoints = <Offset>[];
    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final val = values[i].clamp(0.0, 1.0) * progress;
      final r = radius * val;
      dataPoints.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }

    // Grid rings (faded for low confidence)
    final gridAlpha = confidence < 0.6 ? 0.15 : 0.3;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: gridAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    if (useDashed) {
      _drawDashedGrid(canvas, center, radius, n, gridPaint);
    } else {
      for (var level = 1; level <= 4; level++) {
        final r = radius * level / 4;
        final path = Path();
        for (var i = 0; i < n; i++) {
          final angle = (2 * pi * i / n) - pi / 2;
          final x = center.dx + r * cos(angle);
          final y = center.dy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, gridPaint);
      }
    }

    // Axis lines
    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        Paint()
          ..color = gridColor.withValues(alpha: gridAlpha)
          ..strokeWidth = 0.5,
      );
    }

    // Data polygon fill
    final dataPath = Path()..moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (var i = 1; i < n; i++) {
      dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = finalStrokeColor.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill,
    );

    // Data polygon stroke (dashed for low confidence)
    final strokePaint = Paint()
      ..color = finalStrokeColor.withValues(alpha: strokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = useGoldRing ? 3.0 : 2.5;

    if (useDashed) {
      _drawDashedPath(canvas, dataPath, strokePaint);
    } else {
      canvas.drawPath(dataPath, strokePaint);
    }

    // Gold ring for 95%+
    if (useGoldRing) {
      canvas.drawPath(
        dataPath,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Data point dots
    for (final p in dataPoints) {
      canvas.drawCircle(p, useGoldRing ? 5.0 : 4.5, Paint()..color = finalStrokeColor);
      canvas.drawCircle(
        p, useGoldRing ? 7.0 : 6.0,
        Paint()..color = finalStrokeColor.withValues(alpha: 0.2),
      );
    }

    // Labels at outer edges
    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final labelRadius = radius + size.width * 0.08;
      final labelPoint = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: labelColor.withValues(alpha: strokeAlpha + 0.2),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: size.width * 0.2);
      tp.paint(canvas, labelPoint - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawDashedGrid(Canvas canvas, Offset center, double radius, int n, Paint paint) {
    for (var level = 1; level <= 4; level++) {
      final r = radius * level / 4;
      for (var i = 0; i < n; i++) {
        final a1 = (2 * pi * i / n) - pi / 2;
        final a2 = (2 * pi * (i + 1) / n) - pi / 2;
        _drawDashedLine(
          canvas,
          Offset(center.dx + r * cos(a1), center.dy + r * sin(a1)),
          Offset(center.dx + r * cos(a2), center.dy + r * sin(a2)),
          paint,
        );
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Approximate dashed effect by drawing segments
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + 6).clamp(0.0, metric.length).toDouble();
        if (end > start) {
          final segment = metric.extractPath(start, end);
          canvas.drawPath(segment, paint);
        }
        distance += 10;
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = sqrt(dx * dx + dy * dy);
    final dashLen = 4.0;
    final gapLen = 4.0;
    double drawn = 0;
    while (drawn < len) {
      final start = drawn;
      final end = (drawn + dashLen).clamp(0, len);
      canvas.drawLine(
        Offset(p1.dx + dx * start / len, p1.dy + dy * start / len),
        Offset(p1.dx + dx * end / len, p1.dy + dy * end / len),
        paint,
      );
      drawn = end + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.comparisonValues != comparisonValues ||
      oldDelegate.confidence != confidence ||
      oldDelegate.progress != progress ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor;
}
