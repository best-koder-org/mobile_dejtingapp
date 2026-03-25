import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart' show AppState;
import '../theme/app_theme.dart';
import '../models.dart';

/// A [CircleAvatar] that loads profile photos with an Authorization header.
class AuthenticatedAvatar extends StatelessWidget {
  final UserProfile? profile;
  final double radius;

  const AuthenticatedAvatar({
    super.key,
    required this.profile,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final url = profile?.photoUrls.isNotEmpty == true
        ? profile!.photoUrls.first
        : null;
    debugPrint('AuthenticatedAvatar: url=$url profile=${profile?.firstName}');
    if (url != null && url.isNotEmpty) {
      return FutureBuilder<String?>(
        future: AppState().getOrRefreshAuthToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: AppTheme.surfaceElevated,
            );
          }
          final token = snapshot.data;
          debugPrint('AuthenticatedAvatar: loading $url token=${token != null ? "YES" : "NO"}');
          return CachedNetworkImage(
            imageUrl: url,
            httpHeaders: token != null
                ? {'Authorization': 'Bearer $token'}
                : const {},
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => CircleAvatar(
              radius: radius,
              backgroundColor: AppTheme.surfaceElevated,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) {
              debugPrint('AuthenticatedAvatar ERROR: $error for $url');
              return _initialsAvatar();
            },
          );
        },
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    final name = profile?.firstName ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    const colors = [
      Color(0xFF6C5CE7),
      Color(0xFF00B894),
      Color(0xFFE17055),
      Color(0xFF0984E3),
      Color(0xFFFDAA5E),
      Color(0xFFE84393),
      Color(0xFF00CEC9),
      Color(0xFFA29BFE),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
