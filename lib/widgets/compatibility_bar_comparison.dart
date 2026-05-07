import 'package:flutter/material.dart';

/// Holds one dimension's scores for [CompatibilityBarComparison].
class DimensionScore {
  const DimensionScore({
    required this.label,
    required this.userScore,
    required this.matchScore,
  });

  final String label;

  /// User's normalised score: 0.0 – 1.0 (clamped if out of range).
  final double userScore;

  /// Match's normalised score: 0.0 – 1.0 (clamped if out of range).
  final double matchScore;
}

/// Compatibility Bar Comparison widget (T542)
///
/// Renders one row per [DimensionScore]: label on the left, then two stacked
/// horizontal bars — user above, match below — animated from 0 on first build.
/// Bar colours are sourced from [Theme.of(context).colorScheme] — no hard-coded
/// hex values. A single [AnimationController] drives all bars (≤300 ms).
class CompatibilityBarComparison extends StatefulWidget {
  const CompatibilityBarComparison({
    super.key,
    required this.dimensions,
  });

  final List<DimensionScore> dimensions;

  @override
  State<CompatibilityBarComparison> createState() =>
      _CompatibilityBarComparisonState();
}

class _CompatibilityBarComparisonState extends State<CompatibilityBarComparison>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final dim in widget.dimensions)
              _DimensionRow(
                dimension: dim,
                progress: _animation.value,
                userColor: colorScheme.primary,
                matchColor: colorScheme.secondary,
              ),
          ],
        );
      },
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.dimension,
    required this.progress,
    required this.userColor,
    required this.matchColor,
  });

  final DimensionScore dimension;
  final double progress;
  final Color userColor;
  final Color matchColor;

  @override
  Widget build(BuildContext context) {
    final userScore = dimension.userScore.clamp(0.0, 1.0);
    final matchScore = dimension.matchScore.clamp(0.0, 1.0);
    final userPct = (userScore * 100).round();
    final matchPct = (matchScore * 100).round();

    return Semantics(
      label:
          '${dimension.label} — you $userPct percent, match $matchPct percent',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                dimension.label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: (userScore * progress).clamp(0.0, 1.0),
                    color: userColor,
                    backgroundColor: userColor.withValues(alpha: 0.2),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 3),
                  LinearProgressIndicator(
                    value: (matchScore * progress).clamp(0.0, 1.0),
                    color: matchColor,
                    backgroundColor: matchColor.withValues(alpha: 0.2),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
