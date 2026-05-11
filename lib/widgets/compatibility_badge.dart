import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Compatibility Badge (T541)
///
/// A circular gradient badge that visualises a 0.0–1.0 compatibility score.
///
/// * Stroke uses a sweep gradient that interpolates between coral
///   (`#FF7F50`) and teal (`#4ECDC4`); higher scores end on richer teal,
///   lower scores fade toward coral.
/// * Centre text shows the integer percentage (e.g. `87%`) and respects
///   the platform's `MediaQuery.textScaleFactor`.
/// * Default size is 56dp; pass [size] to scale.
/// * Pure widget — does not call any service or fetch data.
/// * Accessibility: exposes a Semantics label like
///   "Compatibility 87 percent".
class CompatibilityBadge extends StatelessWidget {
  const CompatibilityBadge({
    super.key,
    required this.score,
    this.size = 56.0,
  });

  /// Compatibility score, clamped to the closed interval `[0.0, 1.0]`.
  final double score;

  /// Diameter of the badge in logical pixels. Defaults to 56dp.
  final double size;

  /// Coral — start of gradient (low scores).
  static const Color _coral = Color(0xFFFF7F50);

  /// Teal — end of gradient (high scores).
  static const Color _teal = Color(0xFF4ECDC4);

  /// Score above which the gradient terminates in richer teal.
  static const double _gradientThreshold = 0.5;

  @override
  Widget build(BuildContext context) {
    final clamped = score.isNaN ? 0.0 : score.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final strokeWidth = math.max(3.0, size / 14.0);

    // Below threshold the gradient leans coral; above it leans teal.
    final endColor = clamped >= _gradientThreshold
        ? _teal
        : Color.lerp(_coral, _teal, clamped / _gradientThreshold)!;

    return Semantics(
      label: 'Compatibility $percent percent',
      container: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BadgePainter(
            progress: clamped,
            startColor: _coral,
            endColor: endColor,
            strokeWidth: strokeWidth,
          ),
          child: Center(
            child: Text(
              '$percent%',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color startColor;
  final Color endColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    // Background ring (subtle).
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withAlpha(38); // ~15%
    canvas.drawCircle(centre, radius, bg);

    if (progress <= 0) return;

    // Progress arc with coral→teal sweep gradient.
    final sweep = 2 * math.pi * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [startColor, endColor],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.progress != progress ||
      old.startColor != startColor ||
      old.endColor != endColor ||
      old.strokeWidth != strokeWidth;
}
