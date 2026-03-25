import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:dejtingapp/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'dart:async';
import '../models.dart';
import '../services/messaging_service.dart';
import '../api_services.dart';
import '../services/api_service.dart' show AppState;
import 'enhanced_chat_screen.dart';
import 'profile_detail_screen.dart';

class EnhancedMatchesScreen extends StatefulWidget {
  const EnhancedMatchesScreen({super.key});

  @override
  State<EnhancedMatchesScreen> createState() => _EnhancedMatchesScreenState();
}

class _EnhancedMatchesScreenState extends State<EnhancedMatchesScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final MessagingService _messagingService = MessagingService();

  List<Match> _matches = [];
  List<ConversationSummary> _conversations = [];
  bool _isLoading = true;
  String _connectionStatus = 'Connecting...';
  Timer? _refreshTimer;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<String>? _statusSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_initializeMessaging());
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeMessaging() async {
    try {
      final appState = AppState();
      await appState.initialize();

      final userId = appState.userId;
      final authToken = await appState.getOrRefreshAuthToken(
          gracePeriod: const Duration(minutes: 1));

      if (!mounted) return;

      if (userId == null || authToken == null || authToken.isEmpty) {
        setState(() {
          _connectionStatus = 'Auth required';
        });
        return;
      }

      await _messagingService.initialize(userId, authToken);

      _messageSubscription = _messagingService.messageStream.listen((message) {
        _loadConversations();
      });

      _statusSubscription =
          _messagingService.connectionStatusStream.listen((status) {
        if (mounted) {
          setState(() {
            _connectionStatus = status;
          });
        }
      });

      setState(() {
        _connectionStatus = 'Connected';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = 'Disconnected';
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadConversations();
    });
  }



  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadMatches(),
      _loadConversations(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMatches() async {
    try {
      final summaries = await matchmakingApi.getMatches();
      final appState = AppState();
      await appState.initialize();
      final currentUserId = appState.userId ?? '';

      setState(() {
        _matches = summaries
            .map((s) => Match(
                  id: s.matchId,
                  userId1: currentUserId,
                  userId2: s.keycloakUserId ?? s.matchedUserId,
                  matchedAt: s.matchedAt,
                  otherUserProfile: UserProfile(
                    userId: s.keycloakUserId ?? s.matchedUserId,
                    firstName: s.displayName.split(' ').first,
                    lastName: '',
                    dateOfBirth: DateTime(2000, 1, 1),
                    photoUrls:
                        s.photoUrl != null ? [s.photoUrl!] : const [],
                  ),
                ))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading matches: \$e');
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _messagingService.getConversations();
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading conversations: $e');
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
              Text(AppLocalizations.of(context).matchesTitle),
              const Spacer(),
              _buildConnectionStatus(),
            ],
          ),
        // Uses theme default AppBar (dark surface)
        // Uses theme default foreground
        bottom: TabBar(
          controller: _tabController,
          // Uses theme TabBar indicator
          // Uses theme TabBar labelColor
          // Uses theme TabBar unselected
          tabs: [
            Tab(
              text: AppLocalizations.of(context).newMatches,
              icon: _matches.isNotEmpty
                  ? Badge(
                      backgroundColor: AppTheme.surfaceElevated,
                      textColor: AppTheme.textPrimary,
                      label: Text(_matches.length.toString()),
                      child: const Icon(Icons.favorite),
                    )
                  : const Icon(Icons.favorite),
            ),
            Tab(
              text: AppLocalizations.of(context).messagesTab,
              icon: _conversations.where((c) => c.unreadCount > 0).isNotEmpty
                  ? Badge(
                      backgroundColor: AppTheme.surfaceElevated,
                      textColor: AppTheme.textPrimary,
                      label: Text(_conversations
                          .map((c) => c.unreadCount)
                          .fold(0, (a, b) => a + b)
                          .toString()),
                      child: const Icon(Icons.chat),
                    )
                  : const Icon(Icons.chat),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const SingleChildScrollView(child: MatchesScreenSkeleton())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMatchesTab(),
                  _buildMessagesTab(),
                ],
              ),
      ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    // In dev mode, don't show noisy reconnecting status — just show a dot
    if (_connectionStatus == 'Connected') {
      return const SizedBox.shrink();
    }

    // Auth required or Disconnected: show tappable retry badge
    final isRetryable = _connectionStatus == 'Auth required' ||
        _connectionStatus == 'Disconnected';

    // Disconnected / Reconnecting: small subtle indicator
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: _connectionStatus == 'Connecting...' || _connectionStatus == 'Reconnecting...'
                  ? Colors.orange
                  : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _connectionStatus == 'Reconnecting...' ? 'Offline' : _connectionStatus,
            style: const TextStyle(fontSize: 9, color: Colors.white54),
          ),
          if (isRetryable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.refresh, size: 10, color: Colors.white54),
          ],
        ],
      ),
    );

    if (isRetryable) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _connectionStatus = 'Connecting...';
          });
          unawaited(_initializeMessaging());
        },
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noMatchesYet,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(AppLocalizations.of(context).keepSwiping),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).newMatches,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final match = _matches[index];
                  final profile = match.otherUserProfile;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _openChat(match),
                      onLongPress: () => _viewProfile(match),
                      child: Column(
                        children: [
                          AuthenticatedAvatar(profile: profile, radius: 40),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 80,
                            child: Text(
                              profile?.firstName ?? AppLocalizations.of(context).unknownUser,
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 24),
            Text(
              'Ready to Chat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) =>
                    _buildMatchCard(_matches[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final profile = match.otherUserProfile;
    // Show last message if conversation exists, otherwise "Say hello!"
    final conversation = _conversations.cast<ConversationSummary?>().firstWhere(
      (c) => c!.otherUserId == match.userId2,
      orElse: () => null,
    );
    final subtitle = conversation?.lastMessage.content ?? 'Say hello!';
    final hasUnread = (conversation?.unreadCount ?? 0) > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: AuthenticatedAvatar(profile: profile),
        title: Text(
          profile?.firstName ?? AppLocalizations.of(context).unknownUser,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(conversation?.lastMessage.timestamp ?? match.matchedAt),
              style: TextStyle(
                color: hasUnread ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () => _openChat(match),
        onLongPress: () => _viewProfile(match),
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noConversationsYet,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(AppLocalizations.of(context).startChattingMatches),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final match = _matches.firstWhere(
            (m) => m.userId2 == conversation.otherUserId,
            orElse: () => Match(
              id: '',
              userId1: '',
              userId2: '',
              matchedAt: DateTime.now(),
              otherUserProfile: UserProfile(
                userId: conversation.otherUserId,
                firstName: 'Unknown',
                lastName: '',
                dateOfBirth: DateTime.now(),
              ),
            ),
          );

          return _buildConversationCard(conversation, match);
        },
      ),
    );
  }

  Widget _buildConversationCard(ConversationSummary conversation, Match match) {
    final profile = match.otherUserProfile;
    final hasUnread = conversation.unreadCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            AuthenticatedAvatar(profile: profile),
            if (hasUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          profile?.firstName ?? AppLocalizations.of(context).unknownUser,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation.lastMessage.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            color: hasUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(conversation.lastMessage.timestamp),
              style: TextStyle(
                color: hasUnread ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _openChat(match),
      ),
    );
  }

  void _openChat(Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(match: match),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _loadConversations();
    });
  }

  void _viewProfile(Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: match.otherUserProfile,
          isMatched: true,
          onMessage: () => _openChat(match),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    }
    // Today: show time of day
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    // Yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Yesterday';
    }
    // This week: day name
    if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    }
    // Older: short date
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

}