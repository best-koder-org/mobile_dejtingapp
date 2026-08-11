import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_theme.dart';

/// A tile that renders either a photo or a video clip in a media gallery.
/// Videos show a ▶️ play overlay and auto-play when visible.
class MediaTile extends StatefulWidget {
  final String url;
  final Map<String, String>? imageHeaders;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showDeleteButton;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MediaTile({
    super.key,
    required this.url,
    this.imageHeaders,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showDeleteButton = false,
    this.onDelete,
    this.onTap,
  });

  /// Returns true if the URL looks like a video endpoint.
  static bool isVideoUrl(String url) => url.contains('/api/videos/');

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isVideo = MediaTile.isVideoUrl(widget.url);
    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: widget.imageHeaders ?? <String, String>{},
      );
      _videoController = controller;
      await controller.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {
      // Video init failed; fallback silently
    }
  }

  void _togglePlay() {
    if (_videoController == null || !_isInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _isVideo ? _buildVideoTile() : _buildPhotoTile();

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _isVideo ? _togglePlay : widget.onTap,
          child: child,
        ),
        if (widget.showDeleteButton && widget.onDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTile() {
    return CachedNetworkImage(
      imageUrl: widget.url,
      httpHeaders: widget.imageHeaders ?? <String, String>{},
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
      errorWidget: (_, __, ___) => Container(
        color: AppTheme.surfaceColor,
        child: Icon(Icons.broken_image, color: AppTheme.textTertiary),
      ),
    );
  }

  Widget _buildVideoTile() {
    if (_videoController != null && _isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          if (!_isPlaying)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
        ],
      );
    }

    // Loading state for video
    return Container(
      color: AppTheme.surfaceColor,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
