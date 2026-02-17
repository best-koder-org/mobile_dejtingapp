import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'dart:async';
import '../models.dart';
import '../services/messaging_service.dart';
import 'profile_detail_screen.dart';

class EnhancedChatScreen extends StatefulWidget {
  final Match match;

  const EnhancedChatScreen({super.key, required this.match});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _connectionStatus = 'Connecting...';
  Timer? _refreshTimer;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _statusSubscription;

  // Typing indicator state
  late StreamSubscription _typingSubscription;
  late StreamSubscription<String> _readReceiptSubscription;
  bool _otherUserTyping = false;
  Timer? _typingDebounce;
  Timer? _typingTimeout;
  bool _iAmTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMessaging();
    _loadMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _typingDebounce?.cancel();
    _typingTimeout?.cancel();
    // Send stop typing on leave
    if (_iAmTyping) _sendTypingState(false);
    _messageSubscription.cancel();
    _statusSubscription.cancel();
    _typingSubscription.cancel();
    _readReceiptSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshMessages();
    }
  }

  void _initializeMessaging() {
    // Listen to real-time messages
    _messageSubscription = _messagingService.messageStream.listen((message) {
      if (message.senderId == widget.match.otherUserProfile?.userId ||
          message.receiverId == widget.match.otherUserProfile?.userId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();

        // Mark as read if it's from the other user
        if (message.senderId == widget.match.otherUserProfile?.userId) {
          _messagingService.markAsRead(message.id);
        }
      }
    });

    // Listen to connection status
    _statusSubscription =
        _messagingService.connectionStatusStream.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });

    // Listen to typing indicators
    _typingSubscription = _messagingService.typingStream.listen((data) {
      final userId = data['userId']?.toString();
      final isTyping = data['isTyping'] == true;
      if (userId == widget.match.otherUserProfile?.userId) {
        setState(() => _otherUserTyping = isTyping);
        // Auto-clear typing after 5s (safety net if stop event lost)
        _typingTimeout?.cancel();
        if (isTyping) {
          _typingTimeout = Timer(const Duration(seconds: 5), () {
            if (mounted) setState(() => _otherUserTyping = false);
          });
        }
      }
    });

    // Listen to read receipts for live checkmark updates
    _readReceiptSubscription = _messagingService.readReceiptStream.listen((messageId) {
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1 && mounted) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(isRead: true, readAt: DateTime.now());
        });
      }
    });

    // Listen to text field changes for typing indicator
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText && !_iAmTyping) {
      _iAmTyping = true;
      _sendTypingState(true);
    }
    // Debounce: stop typing after 2s of no input
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_iAmTyping) {
        _iAmTyping = false;
        _sendTypingState(false);
      }
    });
  }

  void _sendTypingState(bool isTyping) {
    final matchId = widget.match.id;
    if (matchId.isNotEmpty) {
      _messagingService.sendTyping(matchId, isTyping);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshMessages();
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final otherUserId = widget.match.otherUserProfile?.userId;
      if (otherUserId != null) {
        final messages = await _messagingService.getConversation(otherUserId);
        setState(() {
          _messages = messages.reversed.toList(); // Most recent at bottom
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    final otherUserId = widget.match.otherUserProfile?.userId;
    if (otherUserId != null) {
      await _messagingService.refreshConversation(otherUserId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    final otherUserId = widget.match.otherUserProfile?.userId;

    if (otherUserId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final result = await _messagingService.sendMessage(
        otherUserId,
        content,
        type: MessageType.text,
      );

      if (result != null) {
        _messageController.clear();
        // Stop typing indicator
        _iAmTyping = false;
        _typingDebounce?.cancel();
        _sendTypingState(false);
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Widget _buildMessage(Message message) {
    final isMe = message.senderId != widget.match.otherUserProfile?.userId;
    final profile = widget.match.otherUserProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                profile?.photoUrls.isNotEmpty == true
                    ? profile!.photoUrls.first
                    : 'https://picsum.photos/400/600?random=1',
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryColor : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? AppTheme.primaryColor
                            : AppTheme.textTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    IconData statusIcon;

    switch (_connectionStatus) {
      case 'Connected':
        statusColor = Colors.green;
        statusIcon = Icons.wifi;
        break;
      case 'Connecting...':
      case 'Reconnecting...':
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_off;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.wifi_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            _connectionStatus,
            style: TextStyle(
              fontSize: 10,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.match.otherUserProfile;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetailScreen(
                  profile: profile,
                  isMatched: true,
                  onMessage: () {}, // Already in chat
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  profile?.photoUrls.isNotEmpty == true
                      ? profile!.photoUrls.first
                      : 'https://picsum.photos/400/600?random=1',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.firstName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildConnectionStatus(),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMessages,
            tooltip: 'Refresh messages',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Safety Notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.surfaceElevated,
            child: Row(
              children: [
                Icon(Icons.security, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your safety matters. This conversation is monitored for inappropriate content.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start your conversation!',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Say hello to ${profile?.firstName ?? 'your match'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessage(_messages[index]);
                          },
                        ),
                      ),
          ),

          // Typing indicator
          if (_otherUserTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(
                      profile?.photoUrls.isNotEmpty == true
                          ? profile!.photoUrls.first
                          : 'https://picsum.photos/400/600?random=1',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDots(),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    onPressed: _isSending ? null : _sendMessage,
                    backgroundColor: _isSending ? AppTheme.surfaceElevated : AppTheme.primaryColor,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Safety Tips'),
              onTap: () {
                Navigator.pop(context);
                _showSafetyTips();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text(
          'Report this user for inappropriate behavior. Our team will review your report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'User reported. Thank you for keeping our community safe.'),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'This will prevent them from messaging you and hide their profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to matches
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked successfully.')),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showSafetyTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stay Safe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '• Never share personal information like your phone number, address, or financial details'),
              SizedBox(height: 8),
              Text('• Meet in public places for first dates'),
              SizedBox(height: 8),
              Text(
                  '• Trust your instincts - if something feels wrong, report it'),
              SizedBox(height: 8),
              Text('• Our AI monitors conversations for inappropriate content'),
              SizedBox(height: 8),
              Text('• Report any suspicious or offensive behavior immediately'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}


/// Animated typing dots indicator (three bouncing dots).
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value + delay) % 1.0;
            // Bounce: quick up-down in first 0.5, then idle
            final bounce = t < 0.5 ? (1 - (2 * t - 0.5).abs()) * 4.0 : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -bounce),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
