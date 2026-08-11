import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../services/video_service.dart';

/// Screen for recording and uploading short video profile clips (max 30s).
class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({super.key});

  @override
  State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  VideoPlayerController? _playerController;
  bool _uploading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked == null) return;

      _playerController?.dispose();
      _playerController = VideoPlayerController.file(File(picked.path));

      setState(() {
        _videoFile = File(picked.path);
        _statusMessage = null;
      });

      await _playerController!.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (picked == null) return;

      _playerController?.dispose();
      _playerController = VideoPlayerController.file(File(picked.path));

      setState(() {
        _videoFile = File(picked.path);
        _statusMessage = null;
      });

      await _playerController!.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _statusMessage = 'Gallery error: $e';
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _uploading = true;
      _statusMessage = 'Uploading...';
    });

    final result = await VideoService.uploadVideo(_videoFile!.path);

    if (result != null && mounted) {
      setState(() {
        _statusMessage = 'Video uploaded! 🎬';
        _uploading = false;
        _videoFile = null;
        _playerController?.dispose();
        _playerController = null;
      });
    } else if (mounted) {
      setState(() {
        _statusMessage = 'Upload failed. Please try again.';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Video'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Add a short video to your profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Videos help potential matches see the real you. Keep it under 30 seconds!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
            const SizedBox(height: 24),

            // Preview area
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: _buildPreview(),
            ),
            const SizedBox(height: 20),

            // Action buttons
            if (_videoFile == null) ...[
              _ActionButton(
                icon: Icons.camera_alt,
                label: 'Record Video',
                onTap: _recordVideo,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: _pickFromGallery,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.cloud_upload,
                      label: _uploading ? 'Uploading...' : 'Upload',
                      onTap: _uploading ? null : _uploadVideo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _playerController?.dispose();
                        _playerController = null;
                        setState(() {
                          _videoFile = null;
                          _statusMessage = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                    ),
                  ),
                ],
              ),
            ],

            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('fail')
                      ? Colors.red
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_playerController != null && _playerController!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _playerController!.value.isPlaying
                ? _playerController!.pause()
                : _playerController!.play();
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_playerController!),
              if (!_playerController!.value.isPlaying)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.play_arrow, size: 40, color: AppTheme.primaryColor),
                ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No video selected',
            style: TextStyle(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
