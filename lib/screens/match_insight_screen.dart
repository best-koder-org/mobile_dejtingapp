import 'package:flutter/material.dart';

import '../models/match_insight.dart';
import '../services/match_insight_service.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_badge.dart';

/// Match Insight Card screen (T543)
///
/// Renders the 4-section "Why You Matched" card:
///  1. ✅ Why You Connected — top compatibility reasons.
///  2. ⚠️ Areas of Difference — friction points (max 3).
///  3. 🌱 Where This Could Go — complementary growth (may be empty).
///  4. 📚 What You Could Learn — locked premium section (placeholder gating).
///
/// Fetches the insight on first build via [MatchInsightService.fetchInsight].
/// Loading / error / 404 states are handled inline.
class MatchInsightScreen extends StatefulWidget {
  const MatchInsightScreen({
    super.key,
    required this.matchId,
    this.otherUserName,
    MatchInsightService? insightService,
    this.isPremium = false,
  }) : _injectedService = insightService;

  /// Backend match id (int — see [MatchInsight.matchId]).
  final int matchId;

  /// Optional display name to title the screen ("Match with Maja").
  final String? otherUserName;

  /// When false (default) the premium section renders locked.
  final bool isPremium;

  final MatchInsightService? _injectedService;

  @override
  State<MatchInsightScreen> createState() => _MatchInsightScreenState();
}

class _MatchInsightScreenState extends State<MatchInsightScreen> {
  late final MatchInsightService _service;
  late Future<MatchInsight?> _future;

  @override
  void initState() {
    super.initState();
    _service = widget._injectedService ?? MatchInsightService();
    _future = _service.fetchInsight(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.otherUserName != null
        ? 'Match with ${widget.otherUserName}'
        : 'Match Insight';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<MatchInsight?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Could not load insight.\n${snapshot.error}',
              onRetry: _retry,
            );
          }
          final insight = snapshot.data;
          if (insight == null) {
            return const _EmptyState();
          }
          return _InsightBody(
            insight: insight,
            isPremium: widget.isPremium,
          );
        },
      ),
    );
  }

  void _retry() {
    setState(() {
      _future = _service.fetchInsight(widget.matchId);
    });
  }
}

class _InsightBody extends StatelessWidget {
  const _InsightBody({required this.insight, required this.isPremium});

  final MatchInsight insight;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final reasons = insight.reasons;
    final friction = insight.frictions.take(3).toList(growable: false);
    final growth = insight.growth ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Center(
          child: CompatibilityBadge(
            score: insight.overallScore.clamp(0.0, 1.0),
            size: 120,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${(insight.overallScore.clamp(0.0, 1.0) * 100).round()}% compatible',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _InsightSection(
          icon: '✅',
          title: 'Why You Connected',
          items: reasons,
          emptyHint: 'No standout signals yet — keep chatting!',
          semanticsKey: 'section-reasons',
        ),
        const SizedBox(height: 16),
        _InsightSection(
          icon: '⚠️',
          title: 'Areas of Difference',
          items: friction,
          emptyHint: 'No notable friction detected.',
          semanticsKey: 'section-friction',
        ),
        const SizedBox(height: 16),
        _InsightSection(
          icon: '🌱',
          title: 'Where This Could Go',
          items: growth,
          emptyHint: 'Insight pending — answer more questions to unlock.',
          semanticsKey: 'section-growth',
        ),
        const SizedBox(height: 16),
        _PremiumSection(isPremium: isPremium),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.emptyHint,
    required this.semanticsKey,
  });

  final String icon;
  final String title;
  final List<String> items;
  final String emptyHint;
  final String semanticsKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsKey,
      container: true,
      child: Card(
        color: AppTheme.surfaceElevated,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Text(
                  emptyHint,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  const _PremiumSection({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'section-premium',
      container: true,
      child: Card(
        color: AppTheme.surfaceElevated,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'What You Could Learn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!isPremium)
                    const Icon(Icons.lock_outline,
                        size: 18, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isPremium
                    ? 'Deep AI analysis of your conversation styles, '
                        'attachment patterns, and likely growth edges.'
                    : 'Upgrade to Premium to unlock AI-generated guidance '
                        'on your conversation styles and growth edges.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Insight not ready yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We need a few more answers from both of you '
              'before we can generate this match insight.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
