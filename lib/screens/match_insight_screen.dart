import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../backend_url.dart';
import '../models/match_insight.dart';
import '../services/api_service.dart' show AppState;
import '../services/match_insight_service.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_badge.dart';
import '../widgets/radar_chart_widget.dart';
import 'radar_profile_screen.dart' show RadarProfileScreen;

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
    this.otherKeycloakId,
    MatchInsightService? insightService,
    this.isPremium = false,
    this.radarHttpClient,
    this.radarTokenProvider,
  }) : _injectedService = insightService;

  /// Backend match id (int — see [MatchInsight.matchId]).
  final int matchId;

  /// Optional display name to title the screen ("Match with Maja").
  final String? otherUserName;

  /// Optional keycloak ID of the other user, used to render the radar comparison.
  final String? otherKeycloakId;

  /// When false (default) the premium section renders locked.
  final bool isPremium;

  /// Optional HTTP client for radar section (testing).
  final http.Client? radarHttpClient;

  /// Optional token provider for radar section (testing).
  final Future<String?> Function()? radarTokenProvider;

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
            otherKeycloakId: widget.otherKeycloakId,
            radarHttpClient: widget.radarHttpClient,
            radarTokenProvider: widget.radarTokenProvider,
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
  const _InsightBody({
    required this.insight,
    required this.isPremium,
    this.otherKeycloakId,
    this.radarHttpClient,
    this.radarTokenProvider,
  });

  final MatchInsight insight;
  final bool isPremium;
  final String? otherKeycloakId;
  final http.Client? radarHttpClient;
  final Future<String?> Function()? radarTokenProvider;

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
        if (otherKeycloakId != null)
          _RadarSection(
            otherKeycloakId: otherKeycloakId!,
            httpClient: radarHttpClient,
            tokenProvider: radarTokenProvider,
          ),
        if (otherKeycloakId != null) const SizedBox(height: 16),
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

/// Compact radar compatibility card for the match insight screen (T591).
///
/// Loads the compare radar profile and shows a mini [RadarChartWidget].
/// Tapping navigates to the full [RadarProfileScreen].
class _RadarSection extends StatefulWidget {
  const _RadarSection({
    required this.otherKeycloakId,
    this.httpClient,
    this.tokenProvider,
  });

  final String otherKeycloakId;
  final http.Client? httpClient;
  final Future<String?> Function()? tokenProvider;

  @override
  State<_RadarSection> createState() => _RadarSectionState();
}

class _RadarSectionState extends State<_RadarSection> {
  RadarProfileData? _mine;
  RadarProfileData? _theirs;
  bool _loading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tokenFn = widget.tokenProvider ?? AppState().getOrRefreshAuthToken;
      final token = await tokenFn();
      if (token == null) {
        if (mounted) setState(() { _loading = false; });
        return;
      }
      final client = widget.httpClient ?? http.Client();
      final base = ApiUrls.matchmakingService;
      final resp = await client.get(
        Uri.parse(
            '$base/api/compatibility/radar/compare/${Uri.encodeComponent(widget.otherKeycloakId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final mine = _parse(body['mine'] as Map<String, dynamic>?);
        final theirs = _parse(body['theirs'] as Map<String, dynamic>?);
        if (mounted) {
          setState(() {
            _mine = mine;
            _theirs = theirs;
            _hasData = mine != null || theirs != null;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _loading = false; });
  }

  static RadarProfileData? _parse(Map<String, dynamic>? data) {
    if (data == null) return null;
    final axes = data['axes'] as Map<String, dynamic>? ?? {};
    return RadarProfileData(
      emotionalStability: (axes['emotionalStability'] as num?)?.toDouble() ?? 0.5,
      socialEnergy: (axes['socialEnergy'] as num?)?.toDouble() ?? 0.5,
      openness: (axes['openness'] as num?)?.toDouble() ?? 0.5,
      warmth: (axes['warmth'] as num?)?.toDouble() ?? 0.5,
      lifeStructure: (axes['lifeStructure'] as num?)?.toDouble() ?? 0.5,
      intimacyComfort: (axes['intimacyComfort'] as num?)?.toDouble() ?? 0.5,
      conflictStyle: (axes['conflictStyle'] as num?)?.toDouble() ?? 0.5,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!_hasData) return const SizedBox.shrink();

    return Semantics(
      identifier: 'section-radar',
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
                  const Icon(Icons.radar, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Kompatibilitetsprofil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RadarProfileScreen(
                          keycloakId: AppState().userId ?? '',
                          compareKeycloakId: widget.otherKeycloakId,
                        ),
                      ),
                    ),
                    child: const Text('Visa mer'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: RadarChartWidget(
                  profile: _mine ??
                      RadarProfileData(
                        emotionalStability: 0.5, socialEnergy: 0.5,
                        openness: 0.5, warmth: 0.5, lifeStructure: 0.5,
                        intimacyComfort: 0.5, conflictStyle: 0.5, confidence: 0,
                      ),
                  compareProfile: _theirs,
                  size: 200,
                  showLabels: true,
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
