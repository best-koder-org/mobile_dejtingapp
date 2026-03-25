
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models.dart';
import '../services/api_service.dart' show AppState;
import '../theme/app_theme.dart';

/// A [CircleAvatar] that loads profile photos with an Authorization header.
/// On web, fetches bytes manually since CachedNetworkImage can't set headers.
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
    if (url == null || url.isEmpty) return _initialsAvatar();

    if (kIsWeb) {
      return _WebAuthImage(url: url, radius: radius, fallback: _initialsAvatar());
    }

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
          errorWidget: (context, url, error) => _initialsAvatar(),
        );
      },
    );
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

/// Web-only: fetches image bytes via http.get with auth header.
class _WebAuthImage extends StatefulWidget {
  final String url;
  final double radius;
  final Widget fallback;

  const _WebAuthImage({required this.url, required this.radius, required this.fallback});

  @override
  State<_WebAuthImage> createState() => _WebAuthImageState();
}

class _WebAuthImageState extends State<_WebAuthImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final response = await http.get(
        Uri.parse(widget.url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _bytes = response.bodyBytes);
      } else if (mounted) {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || (_bytes != null && _bytes!.isEmpty)) return widget.fallback;
    if (_bytes == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppTheme.surfaceElevated,
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: MemoryImage(_bytes!),
    );
  }
}
