import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:dejtingapp/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/billing_service.dart';
import 'package:dejtingapp/services/swipe_service.dart';
import 'package:dejtingapp/services/api_service.dart';
import '../models.dart';
import '../api_services.dart';
import 'enhanced_chat_screen.dart';

/// 3-tab Matches hub: Matches / Sparks / History
///
/// Tab 1 — Matches: mutual matches (existing list)
/// Tab 2 — Sparks: received sparks with sender info
/// Tab 3 — History: profiles you've liked (outgoing swipes)
class EnhancedMatchesScreen extends StatefulWidget {
  const EnhancedMatchesScreen({super.key});

  @override
  State<EnhancedMatchesScreen> createState() => _EnhancedMatchesScreenState();
}

class _EnhancedMatchesScreenState extends State<EnhancedMatchesScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  // Matches tab
  List<MatchSummary> _matches = [];
  bool _isLoadingMatches = true;

  // Sparks tab
  List<SparkReceived> _sparks = [];
  bool _isLoadingSparks = true;

  // History tab
  List<_SwipeHistoryItem> _history = [];
  bool _isLoadingHistory = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final index = _tabController.index;
      if (index == 1 && _sparks.isEmpty) _loadSparks();
      if (index == 2 && _history.isEmpty) _loadHistory();
    }
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoadingMatches = true);
    try {
      final summaries = await MatchmakingApiService().getMatches();
      if (!mounted) return;
      setState(() {
        _matches = summaries
          ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        _isLoadingMatches = false;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading matches: $e');
        setState(() => _isLoadingMatches = false);
      }
    }
  }

  Future<void> _loadSparks() async {
    setState(() => _isLoadingSparks = true);
    try {
      final result = await BillingServiceSparks.getReceivedSparks();
      if (!mounted) return;
      setState(() {
        _sparks = result.sparks;
        _isLoadingSparks = false;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading sparks: $e');
        setState(() => _isLoadingSparks = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final profileId = await AppState().getOrResolveProfileId();
      if (profileId == null) {
        if (mounted) setState(() => _isLoadingHistory = false);
        return;
      }
      final swipes = await SwipeService.getLikesHistory(profileId);
      if (!mounted) return;
      setState(() {
        _history = swipes.map((s) => _SwipeHistoryItem(
          targetUserId: (s['targetUserId'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.tryParse(s['createdAt'] as String? ?? '') ?? DateTime.now(),
        )).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading swipe history: $e');
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Semantics(
      label: 'screen:matches',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).matchesTitle),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.favorite_border), text: 'Matches'),
              Tab(icon: Icon(Icons.bolt), text: 'Sparks'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesTab(),
            _buildSparksTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ── Matches Tab ──

  Widget _buildMatchesTab() {
    if (_isLoadingMatches) {
      return const SingleChildScrollView(child: MatchesScreenSkeleton());
    }
    if (_matches.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_border,
        AppLocalizations.of(context).noMatchesYet,
        AppLocalizations.of(context).keepSwiping,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).newMatches,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _matches.length,
                      itemBuilder: (context, i) {
                        final match = _matches[i];
                        final profile = _buildProfileFromMatch(match);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => _openChat(profile),
                            child: Column(
                              children: [
                                AuthenticatedAvatar(profile: profile, radius: 38),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    profile.firstName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500, fontSize: 13),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          final match = _matches[index - 1];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(MatchSummary match) {
    final profile = _buildProfileFromMatch(match);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: SizedBox(
          width: 48, height: 48,
          child: AuthenticatedAvatar(profile: profile),
        ),
        title: Text(profile.firstName,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          match.lastMessage ?? 'Say hello!',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textTertiary),
        onTap: () => _openChat(profile),
      ),
    );
  }

  UserProfile _buildProfileFromMatch(MatchSummary match) {
    return UserProfile(
      userId: match.keycloakUserId ?? match.matchedUserId,
      firstName: match.displayName.split(' ').first,
      lastName: '',
      dateOfBirth: DateTime(2000, 1, 1),
      photoUrls: match.photoUrl != null ? [match.photoUrl!] : [],
    );
  }

  void _openChat(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(
          match: Match(
            id: '',
            userId1: '',
            userId2: profile.userId,
            matchedAt: DateTime.now(),
            otherUserProfile: profile,
          ),
        ),
      ),
    ).then((_) => _loadMatches());
  }

  // ── Sparks Tab ──

  Widget _buildSparksTab() {
    if (_isLoadingSparks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sparks.isEmpty) {
      return _buildEmptyState(
        Icons.bolt,
        'No Sparks Yet',
        'When someone sends you a Spark, it will appear here. Sparks are like super-likes — use them to stand out!',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSparks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sparks.length,
        itemBuilder: (context, index) {
          final spark = _sparks[index];
          return _buildSparkCard(spark);
        },
      ),
    );
  }

  Widget _buildSparkCard(SparkReceived spark) {
    final hasMessage = spark.message != null && spark.message!.isNotEmpty;
    final timeAgo = _formatTimeAgo(spark.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Spark icon + glow
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Colors.amber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Someone sent you a Spark!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (!spark.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor, shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasMessage) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${spark.message}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary, fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(timeAgo,
                    style: const TextStyle(
                      color: AppTheme.textTertiary, fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  // ── History Tab ──

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return _buildEmptyState(
        Icons.history,
        'No Likes Sent',
        'Profiles you\'ve liked will appear here. Keep swiping to find your match!',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _buildHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildHistoryCard(_SwipeHistoryItem item) {
    final timeAgo = _formatTimeAgo(item.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primarySubtle,
          child: const Icon(Icons.person, color: AppTheme.primaryColor),
        ),
        title: Text('Profile #${item.targetUserId}',
          style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 14),
            const SizedBox(width: 4),
            Text('Liked $timeAgo',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
        onTap: () {
          // TODO: Open profile detail for this user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile detail coming soon')),
          );
        },
      ),
    );
  }

  // ── Shared ──

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

/// Lightweight history item for the swipe history tab.
class _SwipeHistoryItem {
  final int targetUserId;
  final DateTime createdAt;
  const _SwipeHistoryItem({required this.targetUserId, required this.createdAt});
}
