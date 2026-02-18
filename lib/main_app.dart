import 'dart:async';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'screens/home_screen.dart';
import 'screens/enhanced_matches_screen.dart';
import 'screens/profile_hub_screen.dart';
import 'services/app_initialization_service.dart';
import 'services/api_service.dart' hide PhotoService;
import 'services/photo_service.dart';
import 'services/messaging_service.dart';
import 'services/matchmaking_realtime_service.dart';
import 'models.dart' show Message;

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  String? _profilePhotoUrl;
  Map<String, String>? _imageHeaders;

  // Unread message badge
  int _totalUnreadCount = 0;
  Timer? _unreadPollTimer;
  StreamSubscription<Message>? _newMessageSubscription;

  // Match notifications
  StreamSubscription<MatchNotification>? _matchSubscription;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EnhancedMatchesScreen(),
    const ProfileHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await AppInitializationService().initializeApp();
      await _loadProfilePhoto();
      await _pollUnreadCount();
      _startUnreadPolling();
      _startMatchListener();
    } catch (e) {
      debugPrint('App initialization error: $e');
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final appState = AppState();
      final token = await appState.getOrRefreshAuthToken();
      final userId = int.tryParse(appState.userId ?? '');

      if (token != null && userId != null) {
        _imageHeaders = {'Authorization': 'Bearer $token'};
        final photoService = PhotoService();
        final summary = await photoService.getUserPhotos(
          authToken: token,
          userId: userId,
        );
        if (summary != null && summary.photos.isNotEmpty) {
          final primaryPhoto = summary.photos.firstWhere(
            (p) => p.isPrimary,
            orElse: () => summary.photos.first,
          );
          if (mounted) {
            setState(() {
              _profilePhotoUrl = primaryPhoto.urls.thumbnail.isNotEmpty
                  ? primaryPhoto.urls.thumbnail
                  : primaryPhoto.urls.medium;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load profile photo for nav: $e');
    }
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    _newMessageSubscription?.cancel();
    _matchSubscription?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Unread message badge polling
  // ═══════════════════════════════════════════════════════════════════════

  void _startUnreadPolling() {
    _unreadPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollUnreadCount();
    });
    _newMessageSubscription = MessagingService().messageStream.listen((_) {
      _pollUnreadCount();
    });
  }

  Future<void> _pollUnreadCount() async {
    try {
      final conversations = await MessagingService().getConversations();
      final total = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
      if (mounted && total != _totalUnreadCount) {
        setState(() {
          _totalUnreadCount = total;
        });
      }
    } catch (e) {
      debugPrint('Failed to poll unread count: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Match notification listener → "It's a match!" dialog
  // ═══════════════════════════════════════════════════════════════════════

  void _startMatchListener() {
    _matchSubscription =
        MatchmakingRealtimeService().matchStream.listen((notification) {
      if (mounted) {
        _showMatchDialog(notification);
      }
    });
  }

  void _showMatchDialog(MatchNotification notification) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Match dialog',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.elasticOut,
        );
        return Transform.scale(
          scale: curvedAnim.value,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFEE5A24),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hearts animation area
                      const Text(
                        '❤️',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "It's a Match!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notification.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Send message button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Switch to matches tab
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFEE5A24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Send a Message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Keep swiping button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Keep Swiping',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2 && _currentIndex != 2) {
              _loadProfilePhoto();
            }
            if (index == 1) {
              _pollUnreadCount();
            }
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: _totalUnreadCount > 0
                  ? Badge(
                      backgroundColor: Colors.red,
                      smallSize: 10,
                      child: const Icon(Icons.favorite),
                    )
                  : const Icon(Icons.favorite),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: _buildProfileNavIcon(isSelected: _currentIndex == 2),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  /// Hinge-style profile photo avatar in bottom nav bar.
  Widget _buildProfileNavIcon({required bool isSelected}) {
    const double size = 28;
    final borderColor = isSelected
        ? AppTheme.primaryColor
        : AppTheme.dividerColor;

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: ClipOval(
        child: _profilePhotoUrl != null
            ? CachedNetworkImage(
                imageUrl: _profilePhotoUrl!,
                httpHeaders: _imageHeaders,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Icon(
                  Icons.person,
                  size: size * 0.7,
                  color: AppTheme.textTertiary,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.person,
                  size: size * 0.7,
                  color: AppTheme.textTertiary,
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.7,
                color: AppTheme.textTertiary,
              ),
      ),
    );
  }
}
