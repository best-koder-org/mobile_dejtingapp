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
        _showMessageNotification(message);
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

  void _showMessageNotification(Message message) {
    // Find the sender's name
    final senderMatch = _matches.firstWhere(
      (match) => match.otherUserProfile?.userId == message.senderId,
      orElse: () => Match(
        id: '',
        userId1: '',
        userId2: '',
        matchedAt: DateTime.now(),
        otherUserProfile: UserProfile(
          userId: message.senderId,
          firstName: 'Someone',
          lastName: '',
          dateOfBirth: DateTime.now(),
        ),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  senderMatch.otherUserProfile?.photoUrls.isNotEmpty == true
                      ? senderMatch.otherUserProfile!.photoUrls.first
                      : 'https://picsum.photos/400/600?random=1',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderMatch.otherUserProfile?.firstName ?? 'Someone',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      message.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Reply',
            onPressed: () => _openChat(senderMatch),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
                  userId2: s.matchedUserId,
                  matchedAt: s.matchedAt,
                  otherUserProfile: UserProfile(
                    userId: s.matchedUserId,
                    firstName: s.displayName,
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Matches'),
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
              text: 'New Matches',
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
              text: 'Messages',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesTab(),
                _buildMessagesTab(),
              ],
            ),
    );
  }

  Widget _buildConnectionStatus() {
    IconData statusIcon;

    switch (_connectionStatus) {
      case 'Connected':
        statusIcon = Icons.wifi;
        break;
      case 'Connecting...':
      case 'Reconnecting...':
        statusIcon = Icons.wifi_off;
        break;
      default:
        statusIcon = Icons.wifi_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _connectionStatus,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No matches yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Keep swiping to find your perfect match!'),
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
              'New Matches',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
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
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                  profile?.photoUrls.isNotEmpty == true
                                      ? profile!.photoUrls.first
                                      : 'https://picsum.photos/400/600?random=${index + 1}',
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.chat,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile?.firstName ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatTime(match.matchedAt),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            profile?.photoUrls.isNotEmpty == true
                ? profile!.photoUrls.first
                : 'https://picsum.photos/400/600?random=1',
          ),
        ),
        title: Text(
          profile?.firstName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          profile?.bio ?? 'Say hello!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(match.matchedAt),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
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
        ),
        onTap: () => _openChat(match),
        onLongPress: () => _viewProfile(match),
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (_conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Start chatting with your matches!'),
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
            (m) => m.otherUserProfile?.userId == conversation.otherUserId,
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
            CircleAvatar(
              backgroundImage: NetworkImage(
                profile?.photoUrls.isNotEmpty == true
                    ? profile!.photoUrls.first
                    : 'https://picsum.photos/400/600?random=1',
              ),
            ),
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
          profile?.firstName ?? 'Unknown',
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
            color: hasUnread ? Colors.black87 : Colors.grey[600],
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

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
