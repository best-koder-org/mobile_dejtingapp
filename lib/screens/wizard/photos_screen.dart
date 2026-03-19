import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/photo_service.dart';
import '../../services/api_service.dart' show AppState;
import '../../theme/app_theme.dart';

/// Photos Screen - Final onboarding step
/// Grid of photo upload slots (Tinder-style 2x3 grid)
/// Uploads photos to photo-service and stores returned URLs in OnboardingData.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _photoService = PhotoService();
  final _picker = ImagePicker();

  // Each slot holds either null (empty) or a _PhotoSlot with file + upload state
  final List<_PhotoSlot?> _slots = List.filled(6, null);

  int get _photoCount => _slots.where((s) => s != null && s.uploaded).length;
  int get _uploadingCount => _slots.where((s) => s != null && s.uploading).length;
  bool get _isValid => _photoCount >= 2;
  bool get _isBusy => _uploadingCount > 0;

  Future<void> _addPhoto(int index) async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _slots[index] = _PhotoSlot(file: file);
    });

    await _uploadPhoto(index);
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: Text(AppLocalizations.of(context).takeAPhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: Text(AppLocalizations.of(context).chooseFromGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(int index) async {
    final slot = _slots[index];
    if (slot == null) return;

    setState(() {
      slot.uploading = true;
      slot.error = null;
    });

    final token = AppState().authToken;
    if (token == null) {
      setState(() {
        slot.uploading = false;
        slot.error = 'Not authenticated';
      });
      return;
    }

    final result = await _photoService.uploadPhoto(
      imageFile: slot.file,
      authToken: token,
      isPrimary: index == 0, // first slot = primary photo
      displayOrder: index + 1,
    );

    if (!mounted) return;

    setState(() {
      slot.uploading = false;
      if (result.success && result.photo != null) {
        slot.uploaded = true;
        slot.photoResponse = result.photo;
        _syncPhotoUrls();
      } else {
        slot.error = result.errorMessage ?? 'Upload failed';
      }
    });
  }

  void _removePhoto(int index) async {
    final slot = _slots[index];
    if (slot == null) return;

    // If already uploaded, delete from server
    if (slot.uploaded && slot.photoResponse != null) {
      final token = AppState().authToken;
      if (token != null) {
        await _photoService.deletePhoto(
          photoId: slot.photoResponse!.id,
          authToken: token,
        );
      }
    }

    setState(() {
      _slots[index] = null;
      _syncPhotoUrls();
    });
  }

  /// Keep OnboardingData.photoUrls in sync with uploaded photos
  void _syncPhotoUrls() {
    final data = OnboardingProvider.of(context).data;
    data.photoUrls = _slots
        .where((s) => s != null && s.uploaded && s.photoResponse != null)
        .map((s) => s!.photoResponse!.urls.medium)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  void _finish() {
    _syncPhotoUrls();
    OnboardingProvider.of(context).goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: OnboardingProvider.of(context).progress(context),
                  backgroundColor: AppTheme.dividerColor,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                  minHeight: 4,
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).addPhotos,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).photosSubtitle,
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // 2x3 photo grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 6,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => _buildSlot(index),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildStatusText(),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_isValid && !_isBusy) ? _finish : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: AppTheme.surfaceElevated,
                            disabledForegroundColor: AppTheme.textTertiary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                          ),
                          child: _isBusy
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(color: AppTheme.textOnPrimary, strokeWidth: 2),
                                )
                              : Text(AppLocalizations.of(context).continueButton, style: TextStyle(fontSize: 18, color: AppTheme.textOnPrimary)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
          DevModeSkipButton(
            onSkip: () { OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Photos',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    String text;
    Color color;
    if (_isBusy) {
      text = 'Uploading...';
      color = Colors.orange;
    } else if (_isValid) {
      text = '$_photoCount/6 photos · Ready!';
      color = const Color(0xFF00C878);
    } else {
      final needed = 2 - _photoCount;
      text = '$_photoCount/6 photos · Add $needed more';
      color = AppTheme.textSecondary;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: color,
        fontWeight: _isValid ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSlot(int index) {
    final slot = _slots[index];

    if (slot == null) {
      return _buildEmptySlot(index);
    }
    if (slot.uploading) {
      return _buildUploadingSlot(index, slot);
    }
    if (slot.error != null) {
      return _buildErrorSlot(index, slot);
    }
    return _buildFilledSlot(index, slot);
  }

  Widget _buildEmptySlot(int index) {
    return GestureDetector(
      onTap: () => _addPhoto(index),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor, width: 1),
        ),
        child: Center(
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.add, color: AppTheme.textOnPrimary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingSlot(int index, _PhotoSlot slot) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(slot.file, fit: BoxFit.cover),
            Container(color: Colors.black.withAlpha(100)),
            const Center(
              child: CircularProgressIndicator(color: AppTheme.textOnPrimary, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSlot(int index, _PhotoSlot slot) {
    return GestureDetector(
      onTap: () => _uploadPhoto(index), // retry
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(slot.file, fit: BoxFit.cover),
              Container(color: Colors.black.withAlpha(100)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 28),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context).tapToRetry, style: TextStyle(color: AppTheme.textOnPrimary, fontSize: 11)),
                  ],
                ),
              ),
              // Remove button
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.textOnPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilledSlot(int index, _PhotoSlot slot) {
    return GestureDetector(
      onTap: () => _removePhoto(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(slot.file, fit: BoxFit.cover),
              // Remove button
              Positioned(
                top: 4, right: 4,
                child: Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: AppTheme.textOnPrimary),
                ),
              ),
              // "Main" badge on first photo
              if (index == 0)
                Positioned(
                  bottom: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).mainPhotoBadge,
                      style: TextStyle(fontSize: 10, color: AppTheme.textOnPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              // Upload success check
              Positioned(
                bottom: 4, right: 4,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C878),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: AppTheme.textOnPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal state for each photo slot
class _PhotoSlot {
  final File file;
  bool uploading = false;
  bool uploaded = false;
  String? error;
  PhotoResponse? photoResponse;

  _PhotoSlot({required this.file});
}
