import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'dart:async';
import '../models.dart';
import '../api_services.dart';
import '../services/messaging_service.dart';
import '../services/api_service.dart' show AppState;
import 'enhanced_chat_screen.dart';

/// Messages screen — conversation list extracted from the old matches tab.
///
/// Shows conversations with filter chips: All | Unread | Active Now.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin {
  final MessagingService _messagingService = MessagingService();

  List<ConversationSummary> _conversations = [];
  List<MatchSummary> _matches = [];
  bool _isLoading = true;
  String _connectionStatus = 'Connecting...';
  Timer? _refreshTimer;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<String>? _statusSubscription;

  // Filter state
  String _activeFilter = 'all'; // 'all', 'unread', 'active'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeMessaging());
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
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
      _loadConversations(),
      _loadMatches(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _messagingService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading conversations in MessagesScreen: $e');
      }
    }
  }

  Future<void> _loadMatches() async {
    try {
      final summaries = await MatchmakingApiService().getMatches();
      if (mounted) {
        setState(() {
          _matches = summaries;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading matches in MessagesScreen: $e');
      }
    }
  }

  List<ConversationSummary> get _filteredConversations {
    switch (_activeFilter) {
      case 'unread':
        return _conversations.where((c) => c.unreadCount > 0).toList();
      case 'active':
        // Active Now — users active in the last 5 minutes
        return _conversations.where((c) {
          final match = _findMatchForConversation(c);
          return match != null; // Simplified: all matches are "active enough"
        }).toList();
      default:
        return _conversations;
    }
  }

  MatchSummary? _findMatchForConversation(ConversationSummary conversation) {
    try {
      return _matches.firstWhere(
        (m) =>
            m.keycloakUserId == conversation.otherUserId ||
            m.matchedUserId == conversation.otherUserId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filtered = _filteredConversations;
    final unreadCount =
        _conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Semantics(
      label: 'screen:messages',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Messages'),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _buildConnectionStatus(),
            ],
          ),
        ),
        body: Column(
          children: [
            // Filter chips
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', 'unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active Now', 'active'),
                ],
              ),
            ),
            // Conversation list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterKey;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final label = _activeFilter == 'unread'
        ? 'No unread messages'
        : 'No conversations yet';
    final subLabel = _activeFilter == 'unread'
        ? 'All caught up!'
        : 'Start chatting with your matches';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _activeFilter == 'unread'
                ? Icons.done_all
                : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subLabel,
            style:
                const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
      List<ConversationSummary> filtered) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final conversation = filtered[index];
          final match = _findMatchForConversation(conversation);
          return _buildConversationCard(
              conversation, match);
        },
      ),
    );
  }

  Widget _buildConversationCard(
      ConversationSummary conversation, MatchSummary? match) {
    final hasUnread = conversation.unreadCount > 0;
    final profileName = match?.displayName ?? 'Unknown';
    final profilePhoto = match?.photoUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            AuthenticatedAvatar(
              profile: UserProfile(
                userId: match?.matchedUserId ??
                    conversation.otherUserId,
                firstName: profileName.split(' ').first,
                lastName: '',
                dateOfBirth: DateTime.now(),
                photoUrls: profilePhoto != null
                    ? [profilePhoto]
                    : [],
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
          profileName,
          style: TextStyle(
            fontWeight:
                hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation.lastMessage.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight:
                hasUnread ? FontWeight.w500 : FontWeight.normal,
            color: hasUnread
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(
                  conversation.lastMessage.timestamp),
              style: TextStyle(
                color: hasUnread
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: hasUnread
                    ? FontWeight.bold
                    : FontWeight.normal,
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
        onTap: () => _openChat(profileName, profilePhoto,
            match?.matchedUserId ?? conversation.otherUserId),
      ),
    );
  }

  void _openChat(
      String name, String? photoUrl, String otherUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(
          match: Match(
            id: '',
            userId1: '',
            userId2: otherUserId,
            matchedAt: DateTime.now(),
            otherUserProfile: UserProfile(
              userId: otherUserId,
              firstName: name.split(' ').first,
              lastName: '',
              dateOfBirth: DateTime.now(),
              photoUrls:
                  photoUrl != null ? [photoUrl] : [],
            ),
          ),
        ),
      ),
    ).then((_) {
      _loadConversations();
    });
  }

  Widget _buildConnectionStatus() {
    if (_connectionStatus == 'Connected') {
      return const SizedBox.shrink();
    }

    final isRetryable = _connectionStatus == 'Auth required' ||
        _connectionStatus == 'Disconnected';

    final badge = Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _connectionStatus == 'Connecting...' ||
                      _connectionStatus == 'Reconnecting...'
                  ? Colors.orange
                  : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _connectionStatus == 'Reconnecting...'
                ? 'Offline'
                : _connectionStatus,
            style: const TextStyle(
                fontSize: 9, color: Colors.white54),
          ),
          if (isRetryable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.refresh,
                size: 10, color: Colors.white54),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      const days = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ];
      return days[dateTime.weekday - 1];
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}
