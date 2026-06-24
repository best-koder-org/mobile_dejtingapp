import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Data model for a single user's 7-axis radar profile.
class RadarProfileData {
  final double emotionalStability;
  final double socialEnergy;
  final double openness;
  final double warmth;
  final double lifeStructure;
  final double intimacyComfort;
  final double conflictStyle;
  final double confidence;

  const RadarProfileData({
    required this.emotionalStability,
    required this.socialEnergy,
    required this.openness,
    required this.warmth,
    required this.lifeStructure,
    required this.intimacyComfort,
    required this.conflictStyle,
    this.confidence = 1.0,
  });

  List<double> get values => [
        emotionalStability,
        socialEnergy,
        openness,
        warmth,
        lifeStructure,
        intimacyComfort,
        conflictStyle,
      ];

  static const List<String> axisLabels = [
    'Stabilitet',
    'Social energi',
    'Öppenhet',
    'Värme',
    'Struktur',
    'Intimitet',
    'Konfliktstil',
  ];
}

/// 7-axis radar chart.
///
/// Shows the user's polygon in coral and optionally a match's polygon in teal.
/// At low confidence, the polygon is faded; at high confidence it's vivid.
class RadarChartWidget extends StatelessWidget {
  final RadarProfileData profile;

  /// Optional second profile to overlay (e.g. a match's profile).
  final RadarProfileData? compareProfile;

  final double size;
  final bool showLabels;

  const RadarChartWidget({
    super.key,
    required this.profile,
    this.compareProfile,
    this.size = 260,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          profile: profile,
          compareProfile: compareProfile,
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final RadarProfileData profile;
  final RadarProfileData? compareProfile;
  final bool showLabels;

  static const int _axes = 7;
  static const double _labelPadding = 22.0;

  _RadarPainter({
    required this.profile,
    this.compareProfile,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _labelPadding;

    _drawGrid(canvas, center, radius);
    if (showLabels) _drawLabels(canvas, center, radius, size);
    if (compareProfile != null) {
      _drawPolygon(canvas, center, radius, compareProfile!, const Color(0xFF26C6DA), 0.3);
    }
    _drawPolygon(canvas, center, radius, profile, AppTheme.primaryColor, 0.3 * profile.confidence.clamp(0.3, 1.0));
    _drawPolygonOutline(canvas, center, radius, profile, AppTheme.primaryColor, profile.confidence);
    if (compareProfile != null) {
      _drawPolygonOutline(canvas, center, radius, compareProfile!, const Color(0xFF26C6DA), 1.0);
    }
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i < _axes; i++) {
        final angle = _axisAngle(i);
        final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 0; i < _axes; i++) {
      final angle = _axisAngle(i);
      canvas.drawLine(center, Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)), spokePaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    const style = TextStyle(color: Color(0xFFAAAAAA), fontSize: 10);
    for (int i = 0; i < _axes; i++) {
      final angle = _axisAngle(i);
      final labelRadius = radius + _labelPadding - 4;
      final p = Offset(center.dx + labelRadius * cos(angle), center.dy + labelRadius * sin(angle));
      final tp = TextPainter(
        text: TextSpan(text: RadarProfileData.axisLabels[i], style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, RadarProfileData data, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_buildPath(center, radius, data.values), paint);
  }

  void _drawPolygonOutline(Canvas canvas, Offset center, double radius, RadarProfileData data, Color color, double confidence) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5 + 0.5 * confidence.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(_buildPath(center, radius, data.values), paint);
  }

  Path _buildPath(Offset center, double radius, List<double> values) {
    final path = Path();
    for (int i = 0; i < _axes; i++) {
      final angle = _axisAngle(i);
      final r = radius * values[i].clamp(0.0, 1.0);
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  /// Angles start at the top (-π/2) and go clockwise.
  static double _axisAngle(int i) => (2 * pi * i / _axes) - pi / 2;

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.profile != profile || oldDelegate.compareProfile != compareProfile;
}
