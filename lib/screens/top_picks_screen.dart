import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:dejtingapp/models.dart';
import 'package:dejtingapp/api_services.dart';
import 'package:dejtingapp/services/billing_service.dart';
import 'sparks_store_screen.dart';

/// Top Picks screen — daily curated profiles that require spark credits to contact.
///
/// Shows 5 profiles refreshed every 24h. Each profile card has a spark cost
/// (1 ⚡ to connect). Users can view the profile for free but must spend a spark
/// to send a message.
class TopPicksScreen extends StatefulWidget {
  const TopPicksScreen({super.key});

  @override
  State<TopPicksScreen> createState() => _TopPicksScreenState();
}

class _TopPicksScreenState extends State<TopPicksScreen> {
  List<MatchCandidate> _topPicks = [];
  bool _isLoading = true;
  String? _error;
  int _sparksBalance = 0;
  DateTime? _nextRefreshAt;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _loadTopPicks();
  }

  Future<void> _loadTopPicks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load sparks balance from backend
      EntitlementStatus? status;
      try {
        status = await BillingService.getStatus();
      } catch (e) {
        debugPrint('❌ TopPicks: BillingService.getStatus failed: $e');
      }

      // Try to fetch top picks from backend; fall back to mock data
      List<MatchCandidate> picks;
      try {
        picks = await _fetchTopPicksFromBackend();
      } catch (e) {
        debugPrint('TopPicks backend fetch failed, using mock data: $e');
        picks = await _generateMockTopPicks();
      }

      if (!mounted) return;
      setState(() {
        _topPicks = picks;
        _sparksBalance = status?.availableSparks ?? 0;
        _nextRefreshAt = _calculateNextRefresh();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<MatchCandidate>> _fetchTopPicksFromBackend() async {
    // In production, this calls GET api/matchmaking/top-picks
    // For now, fall through to mock data via the discovery API
    throw UnimplementedError('Backend endpoint not wired yet');
  }

  Future<List<MatchCandidate>> _generateMockTopPicks() async {
    try {
      final candidates = await MatchmakingApiService().getCandidates(pageSize: 20);
      if (candidates.length >= 5) {
        candidates.shuffle();
        return candidates.take(5).toList();
      }
    } catch (e) {
      debugPrint('❌ TopPicks: getCandidates failed: $e');
    }
    return [];
  }

  DateTime _calculateNextRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 6, 0, 0);
    return tomorrow;
  }

  String _formatCountdown(DateTime target) {
    final remaining = target.difference(DateTime.now());
    if (remaining.isNegative) return 'Refreshing soon';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return 'Refreshes in ${hours}h ${minutes}m';
  }

  Future<void> _connectWithSpark(MatchCandidate candidate) async {
    if (_sparksBalance <= 0) {
      _showNoSparksDialog();
      return;
    }

    setState(() => _connecting = true);

    try {
      final result = await BillingServiceSparks.sendSpark(candidate.userId);
      if (!mounted) return;

      if (result.success) {
        _sparksBalance = result.dailyRemaining > 0 ? result.dailyRemaining : result.newBalance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spark sent to ${candidate.displayName}! (1 ⚡ used)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _viewProfile(candidate);
      } else {
        if (result.error == 'No Sparks available') {
          _showNoSparksDialog();
        } else {
          _showNoSparksDialog();
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showNoSparksDialog();
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _showNoSparksDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('No Sparks Left'),
        content: const Text(
          'You\'re out of sparks! Get more sparks to connect with your top picks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              final rootNavigator = Navigator.of(ctx, rootNavigator: true);
              Navigator.pop(ctx);
              rootNavigator.push(
                MaterialPageRoute(builder: (_) => const SparksStoreScreen()),
              ).then((_) => _loadTopPicks());
            },
            child: const Text('Get Sparks'),
          ),
        ],
      ),
    );
  }

  void _viewProfile(MatchCandidate candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(candidate.displayName)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuthenticatedAvatar(
                  profile: UserProfile(
                    userId: candidate.userId,
                    firstName: candidate.displayName.split(' ').first,
                    lastName: '',
                    dateOfBirth: DateTime.now(),
                    photoUrls: candidate.photoUrls,
                  ),
                  radius: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  '${candidate.displayName}, ${candidate.age}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (candidate.bio != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      candidate.bio!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Connect with ⚡'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:top_picks',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Top Picks'),
              const Spacer(),
              // Spark balance indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$_sparksBalance',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Could not load top picks'),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadTopPicks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_topPicks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Top Picks Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for your daily curated picks!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTopPicks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily countdown timer
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _nextRefreshAt != null
                        ? _formatCountdown(_nextRefreshAt!)
                        : '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            'Handpicked for you',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use ⚡ sparks to connect and send a message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
          const SizedBox(height: 16),

          // Top picks profile cards
          ..._topPicks.asMap().entries.map((entry) {
            final index = entry.key;
            final candidate = entry.value;
            return _buildTopPickCard(candidate, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildTopPickCard(MatchCandidate candidate, int rank) {
    final hasSparks = _sparksBalance > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewProfile(candidate),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge + avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AuthenticatedAvatar(
                    profile: UserProfile(
                      userId: candidate.userId,
                      firstName: candidate.displayName.split(' ').first,
                      lastName: '',
                      dateOfBirth: DateTime.now(),
                      photoUrls: candidate.photoUrls,
                    ),
                    radius: 40,
                  ),
                  // Rank badge
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${candidate.displayName}, ${candidate.age}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (candidate.bio != null)
                      Text(
                        candidate.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Compatibility score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${candidate.compatibility.toStringAsFixed(0)}% match',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Spark connect button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: hasSparks && !_connecting
                        ? () => _connectWithSpark(candidate)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasSparks
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(80, 36),
                    ),
                    child: _connecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('⚡', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4),
                              Text('Connect', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
