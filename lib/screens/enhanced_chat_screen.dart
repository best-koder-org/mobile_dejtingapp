import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/widgets/skeleton_loaders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:dejtingapp/widgets/authenticated_avatar.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'dart:async';
import '../models.dart';
import '../services/messaging_service.dart';
import '../utils/profanity_filter.dart';
import 'profile_detail_screen.dart';
import '../widgets/voice/voice_message_bubble.dart';
import '../widgets/voice/voice_chat_recorder.dart';
import '../models/match_insight.dart';
import '../widgets/connection_insight_card.dart';
import '../services/api_service.dart';
import '../services/match_insight_service.dart';

import 'package:dejtingapp/widgets/reputation/chat_feedback_prompt.dart';
import 'post_date_feedback_screen.dart';

class EnhancedChatScreen extends StatefulWidget {
  final Match match;

  /// Pre-seeded messages used in widget tests. When non-null, the screen
  /// skips the network load and renders these messages directly.
  @visibleForTesting
  final List<Message>? initialMessages;

  const EnhancedChatScreen({super.key, required this.match, this.initialMessages});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _connectionStatus = '';
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
  bool _hasText = false;
  MatchInsight? _matchInsight;
  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectionStatus = _messagingService.isConnected ? 'Connected' : 'Connecting...';
    _initializeMessaging();
    if (widget.initialMessages != null) {
      _messages = List.of(widget.initialMessages!);
      _isLoading = false;
    } else {
      _loadMessages();
    }
    _loadMatchInsight();
    _loadCurrentUserProfile();
    _startAutoRefresh();
    _loadLikedMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
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
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
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

  void _loadMatchInsight() async {
    try {
      final service = MatchInsightService();
      final matchId = int.tryParse(widget.match.id);
      if (matchId == null) return;
      final insight = await service.fetchInsight(matchId);
      if (insight != null && mounted) {
        setState(() => _matchInsight = insight);
      }
    } catch (e) {
      // Non-fatal — card just won't show
      debugPrint('Failed to load MatchInsight: $e');
    }
  }

  void _loadCurrentUserProfile() {
    final stored = AppState().userProfile;
    if (stored != null) {
      setState(() {
        _currentUserProfile = UserProfile.fromJson(stored);
      });
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
          _likedMessageIds
            ..clear()
            ..addAll(_messages.where((m) => m.likedByMe).map((m) => m.id));
          _isLoading = false;
        });
        _scrollToBottom();

        // Mark unread messages from the other user as read
        for (final msg in _messages) {
          if (msg.senderId == otherUserId && !msg.isRead) {
            _messagingService.markAsRead(msg.id);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorLoadingMessages(e.toString()))),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    final otherUserId = widget.match.otherUserProfile?.userId;
    if (otherUserId != null) {
      await _messagingService.refreshConversation(otherUserId);
    }
    // Feedback prompt is intentionally DISABLED for now (user request).
    // Re-enable by uncommenting: await _checkFeedbackPrompt();
    // await _checkFeedbackPrompt();
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

    // Client-side profanity check — Hinge-style "Are you sure?" nudge
    if (ProfanityFilter.isOffensive(content)) {
      _showMessageWarning(content);
      return;
    }

    await _doSendMessage(content);
  }

  /// Shows a bottom sheet warning when a message is flagged as potentially
  /// hurtful. User can edit or send anyway.
  void _showMessageWarning(String content) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Warning icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.messageWarningTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.messageWarningBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Edit button (primary action)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    l10n.messageWarningEdit,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Send anyway (secondary / de-emphasized)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _doSendMessage(content, userOverrodeWarning: true);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textTertiary,
                  ),
                  child: Text(
                    l10n.messageWarningSendAnyway,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Actually sends the message to the backend.
  Future<void> _doSendMessage(String content, {bool userOverrodeWarning = false}) async {
    final otherUserId = widget.match.otherUserProfile?.userId;
    if (otherUserId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // TODO: pass userOverrodeWarning metadata to server for trust scoring
      // when SafetyService is wired up (Phase 002)
      final result = await _messagingService.sendMessage(
        otherUserId,
        content,
        type: MessageType.text,
        matchId: widget.match.id,
      );

      if (result != null) {
        _messageController.clear();
        // Keep keyboard open for rapid messaging
        _messageFocusNode.requestFocus();
        // Stop typing indicator
        _iAmTyping = false;
        _typingDebounce?.cancel();
        _sendTypingState(false);
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).failedToSendMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorSendingMessage(e.toString()))),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  static const _likedMessagesKey = 'liked_message_ids';
  final Set<String> _likedMessageIds = <String>{};

  /// Hinge-style: double-tap a bubble to like it (shows a small heart on it).
  /// Persisted locally so the heart stays part of the conversation after
  /// leaving and returning to the chat (and across app restarts).
  void _toggleLike(String messageId) {
    final liked = !_likedMessageIds.contains(messageId);
    setState(() {
      if (liked) {
        _likedMessageIds.add(messageId);
      } else {
        _likedMessageIds.remove(messageId);
      }
    });
    _persistLikedMessages();
    // Persist to the backend too (survives app reinstall / other devices).
    _messagingService.likeMessage(messageId, liked);
  }

  Future<void> _loadLikedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_likedMessagesKey) ?? [];
      if (mounted) {
        setState(() {
          _likedMessageIds
            ..clear()
            ..addAll(list);
        });
      }
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  Future<void> _persistLikedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_likedMessagesKey, _likedMessageIds.toList());
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  /// Whether this message was sent by the logged-in user. A 1:1 chat has only
  /// two participants, so any message whose senderId isn't the current user's
  /// Keycloak id belongs to the other person.
  ///
  /// NOTE: do NOT fall back to comparing against otherUserProfile.userId — that
  /// field is empty/null after match enrichment fallback, which misclassified
  /// the other person's messages as "mine" (all bubbles one color).
  bool _isFromMe(Message message) {
    final currentUserId = AppState().userId;
    // In production the session userId is always set — compare directly. Do NOT
    // fall back to otherUserProfile.userId when we HAVE a session: that field
    // is empty after match enrichment, which misclassified the other person's
    // messages as "mine" (all bubbles one color).
    if (currentUserId != null) {
      return message.senderId == currentUserId;
    }
    // No session (e.g. widget tests): compare against the other user's id.
    final otherId = widget.match.otherUserProfile?.userId;
    if (otherId != null && otherId.isNotEmpty) {
      return message.senderId != otherId;
    }
    return false;
  }

  Widget _buildMessage(Message message) {
    final isMe = _isFromMe(message);
    final profile = widget.match.otherUserProfile;
    final liked = _likedMessageIds.contains(message.id);
    debugPrint('🔵 BUBBLE msg=${message.id} sender=${message.senderId} '
        'me=${AppState().userId} isMe=$isMe');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AuthenticatedAvatar(profile: profile, radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  // Only the other person's messages can be liked (Hinge-style).
                  onDoubleTap: isMe ? null : () => _toggleLike(message.id),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.chatBubbleMe
                              : AppTheme.chatBubbleOther,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: message.type == MessageType.audio
                            ? VoiceMessageBubble(
                                audioUrl: message.content,
                                durationSeconds: message.audioDurationSeconds ?? 0,
                                timestamp: message.timestamp,
                                isSender: isMe,
                              )
                            : Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      if (liked)
                        Positioned(
                          bottom: -9,
                          right: isMe ? 10 : null,
                          left: isMe ? null : 10,
                          child: Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppTheme.primaryColor,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (message.moderationFlag != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'This message may violate community guidelines',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.amber, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  /// Clock time, e.g. "14:32" (shown under each bubble).
  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// A message starts a new "turn" when it's the first message, the sender
  /// changes, or there was a silence of 10+ minutes since the previous one.
  bool _isNewTurn(int index) {
    if (index <= 0) return true;
    final prev = _messages[index - 1];
    final cur = _messages[index];
    if (prev.senderId != cur.senderId) return true;
    final gap = cur.timestamp.difference(prev.timestamp);
    return gap.inMinutes >= 10;
  }

  /// Hinge-style day divider above each turn: "Today · 14:32",
  /// "Yesterday · 21:05", or "18 August · 09:12" for older messages.
  Widget _buildTurnHeader(Message message) {
    final t = message.timestamp.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(day).inDays;

    final String dayLabel;
    if (diffDays == 0) {
      dayLabel = 'Today';
    } else if (diffDays == 1) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = '${t.day} ${_monthName(t.month)}'
          '${t.year != now.year ? ' ${t.year}' : ''}';
    }

    final time = _formatTime(message.timestamp);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$dayLabel · $time',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  String _monthName(int month) => _monthNames[month - 1];



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
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _connectionStatus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.match.otherUserProfile;

    return Semantics(
      label: 'screen:chat',
      child: Scaffold(
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
              AuthenticatedAvatar(profile: profile, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.firstName ?? AppLocalizations.of(context).unknownUser,
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
            tooltip: AppLocalizations.of(context).refreshMessages,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).videoCallComingSoon)),
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
                    AppLocalizations.of(context).safetyNotice,
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

          // Connection Insight Card (T540+)
          if (_matchInsight?.connectionHook != null &&
              _matchInsight!.connectionHook!.headline.isNotEmpty)
            ConnectionInsightCard(
              hook: _matchInsight!.connectionHook!,
              matchProfile: widget.match.otherUserProfile!,
              currentUserProfile: _currentUserProfile,
              messageController: _messageController,
              messageFocusNode: _messageFocusNode,
            ),

          // Messages
          Expanded(
            child: _isLoading
                ? const ChatScreenSkeleton()
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
                              AppLocalizations.of(context).startConversation,
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
                            final message = _messages[index];
                            return Column(
                              children: [
                                if (_isNewTurn(index))
                                  _buildTurnHeader(message),
                                _buildMessage(message),
                              ],
                            );
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
                  AuthenticatedAvatar(profile: profile, radius: 12),
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
                  color: Colors.black.withValues(alpha: 0.3),
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
                      focusNode: _messageFocusNode,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).typeMessage,
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
                  if (_hasText || _isSending)
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
                    )
                  else
                    VoiceChatRecorder(
                      onSend: _handleVoiceSend,
                      onCancel: () {},
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _handleVoiceSend(String filePath, double durationSeconds) async {
    final otherUserId = widget.match.otherUserProfile?.userId;
    if (otherUserId == null) return;
    await _messagingService.sendVoiceMessage(
      otherUserId,
      filePath,
      durationSeconds: durationSeconds,
      matchId: widget.match.id,
    );
  }

  /// Check if user has exchanged enough messages to trigger feedback prompt.
  /// Shows the prompt at most ONCE per conversation (persisted per matchId) so
  /// it stops nagging every time the chat is reopened with 10+ messages.
  Future<void> _checkFeedbackPrompt() async {
    final exchanged = _messages.length >= 10;
    if (!exchanged) return;
    final otherUser = widget.match.otherUserProfile;
    if (otherUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownKey = 'chat_feedback_shown_${widget.match.id}';
      if (prefs.getBool(shownKey) ?? false) return;
      await prefs.setBool(shownKey, true); // mark offered before showing
    } catch (_) {
      // Persistence failure should not block the prompt.
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ChatFeedbackPrompt(
          targetKeycloakId: otherUser.userId,
          targetName: otherUser.firstName ?? "din match",
          matchId: widget.match.id,
          onSubmitted: () => Navigator.of(ctx).pop(),
        ),
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
              title: Text(AppLocalizations.of(context).reportUser),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: Text(AppLocalizations.of(context).blockUser),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Betygsätt er dejt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDateFeedbackScreen(
                      matchId: widget.match.id,
                      matchedPersonName: widget.match.otherUserProfile?.firstName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppLocalizations.of(context).safetyTips),
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
        title: Text(AppLocalizations.of(context).reportUser),
        content: Text(
          'Report this user for inappropriate behavior. Our team will review your report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancelButton),
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
            child: Text(AppLocalizations.of(context).reportButton),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).blockUser),
        content: Text(
          'This will prevent them from messaging you and hide their profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to matches
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).userBlocked)),
              );
            },
            child: Text(AppLocalizations.of(context).blockButton),
          ),
        ],
      ),
    );
  }

  void _showSafetyTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).staySafe),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).safetyTip1),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).safetyTip2),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).safetyTip3),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).safetyTip4),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).safetyTip5),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).gotItButton),
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
