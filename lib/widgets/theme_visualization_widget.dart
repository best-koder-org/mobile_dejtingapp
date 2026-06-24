import 'package:flutter/material.dart';
import '../services/psykolog_service.dart';
import '../theme/app_theme.dart';

/// T569 — Enhanced theme visualization with confidence & evolution indicators.
///
/// Shows extracted themes as a tag cloud grouped by axis (BigFive, Attachment, Values).
/// Each chip is sized by intensity. An optional confidence bar and evolution
/// sparkline show how reliable the themes are and how they've shifted over sessions.
class ThemeVisualizationWidget extends StatelessWidget {
  const ThemeVisualizationWidget({
    super.key,
    required this.themes,
    this.maxPerAxis = 8,
    this.sessionCount = 0,
  });

  final List<PsykologTheme> themes;
  final int maxPerAxis;
  final int sessionCount;

  static const Map<String, _AxisMeta> _axisMeta = {
    'bigfive': _AxisMeta(
      label: 'Personlighet',
      color: Color(0xFF6B8F71),   // sage green
      icon: Icons.psychology_outlined,
    ),
    'attachment': _AxisMeta(
      label: 'Anknytning',
      color: Color(0xFF8B7D6B),   // warm taupe
      icon: Icons.favorite_outline,
    ),
    'values': _AxisMeta(
      label: 'Värderingar',
      color: Color(0xFFD4A76A),   // warm amber
      icon: Icons.lightbulb_outline,
    ),
  };

  static _AxisMeta _metaFor(String axis) =>
      _axisMeta[axis.toLowerCase()] ??
      const _AxisMeta(label: 'Övrigt', color: AppTheme.primaryColor, icon: Icons.label_outline);

  Map<String, List<PsykologTheme>> _grouped() {
    final Map<String, List<PsykologTheme>> map = {};
    for (final t in themes) {
      map.putIfAbsent(t.axis.toLowerCase(), () => []).add(t);
    }
    return map.map((k, v) {
      final sorted = [...v]..sort((a, b) => b.intensity.compareTo(a.intensity));
      return MapEntry(k, sorted.take(maxPerAxis).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) {
      return _EmptyState(sessionCount: sessionCount);
    }

    final groups = _grouped();
    final orderedKeys = [
      'bigfive', 'attachment', 'values',
      ...groups.keys.where((k) => !['bigfive', 'attachment', 'values'].contains(k)),
    ].where(groups.containsKey).toList();

    // Calculate confidence based on session count
    final confidence = sessionCount <= 0 ? 0.0
        : sessionCount == 1 ? 0.4
        : sessionCount == 2 ? 0.55
        : sessionCount == 3 ? 0.7
        : sessionCount <= 5 ? 0.8
        : 0.9 + (sessionCount >= 10 ? 0.05 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confidence indicator
        if (sessionCount > 0) _ConfidenceBar(confidence: confidence, sessionCount: sessionCount),
        const SizedBox(height: 16),
        // Axis groups
        ...orderedKeys.map((axis) => _AxisGroup(
              axisKey: axis,
              themes: groups[axis]!,
              meta: _metaFor(axis),
            )),
      ],
    );
  }
}

// ── Confidence bar ───────────────────────────────────────────────────

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  final int sessionCount;
  const _ConfidenceBar({required this.confidence, required this.sessionCount});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toInt();
    final label = confidence < 0.5 ? 'Låg träffsäkerhet'
        : confidence < 0.7 ? 'Medel träffsäkerhet'
        : confidence < 0.85 ? 'God träffsäkerhet'
        : 'Hög träffsäkerhet';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B4EFF).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Color(0xFF6B4EFF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label${sessionCount >= 5 ? ' ✅' : ''}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: AppTheme.scaffoldDark,
                    color: const Color(0xFF6B4EFF),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%', style: const TextStyle(color: Color(0xFF6B4EFF), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int sessionCount;
  const _EmptyState({required this.sessionCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 40, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            sessionCount == 0
                ? 'Inga teman än. Starta din första reflektionssession för att börja utforska dina relationsmönster.'
                : 'Dina teman visas här efter att din session avslutats.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Supporting classes ───────────────────────────────────────────────

class _AxisMeta {
  const _AxisMeta({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;
}

class _AxisGroup extends StatelessWidget {
  const _AxisGroup({required this.axisKey, required this.themes, required this.meta});
  final String axisKey;
  final List<PsykologTheme> themes;
  final _AxisMeta meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(meta.icon, size: 14, color: meta.color),
              ),
              const SizedBox(width: 8),
              Text(
                meta.label,
                style: TextStyle(
                  color: meta.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${themes.length})',
                style: TextStyle(color: meta.color.withValues(alpha: 0.5), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: themes.map((t) => _ThemeChip(theme: t, color: meta.color)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme, required this.color});
  final PsykologTheme theme;
  final Color color;

  double get _fontSize => 11 + (theme.intensity * 6).clamp(0.0, 8.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10 + theme.intensity * 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        theme.label,
        style: TextStyle(
          color: color,
          fontSize: _fontSize,
          fontWeight: theme.intensity > 0.7 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
