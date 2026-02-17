import 'package:dejtingapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'screens/home_screen.dart';
import 'screens/enhanced_matches_screen.dart';
import 'screens/profile_hub_screen.dart';
import 'services/app_initialization_service.dart';
import 'services/api_service.dart' hide PhotoService;
import 'services/photo_service.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  String? _profilePhotoUrl;
  Map<String, String>? _imageHeaders;

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
            // Refresh profile photo when switching to profile hub
            if (index == 2 && _currentIndex != 2) {
              _loadProfilePhoto();
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
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
  /// Shows the user's actual profile photo in a small circle,
  /// with a highlight ring when selected (like Hinge bottom-right).
  Widget _buildProfileNavIcon({required bool isSelected}) {
    final double size = 28;
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
