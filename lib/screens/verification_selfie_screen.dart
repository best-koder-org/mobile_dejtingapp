import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../services/verification_service.dart';
import '../widgets/verification_badge.dart';

/// T157/T158: Identity verification selfie screen.
///
/// Flow:
/// 1. Show instructions with example selfie framing guide
/// 2. User takes a selfie via front camera
/// 3. Preview + confirm
/// 4. Submit to POST /api/verification/submit
/// 5. Show result (verified badge / pending / rejected / retry)
class VerificationSelfieScreen extends StatefulWidget {
  const VerificationSelfieScreen({super.key});

  @override
  State<VerificationSelfieScreen> createState() =>
      _VerificationSelfieScreenState();
}

class _VerificationSelfieScreenState extends State<VerificationSelfieScreen> {
  final _verificationService = VerificationService();
  final _picker = ImagePicker();

  _ScreenState _state = _ScreenState.instructions;
  File? _selfieFile;
  VerificationResult? _result;
  VerificationStatus? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _verificationService.getStatus();
    if (mounted) {
      setState(() {
        _status = status;
        if (status?.isVerified == true) {
          _state = _ScreenState.alreadyVerified;
        }
      });
    }
  }

  Future<void> _takeSelfie() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        _selfieFile = File(image.path);
        _state = _ScreenState.preview;
      });
    }
  }

  Future<void> _submitSelfie() async {
    if (_selfieFile == null) return;

    setState(() => _isLoading = true);

    final result = await _verificationService.submitSelfie(_selfieFile!);

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
        _state = _ScreenState.result;
      });
    }
  }

  void _retake() {
    setState(() {
      _selfieFile = null;
      _state = _ScreenState.instructions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.verifyIdentityTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_state) {
            _ScreenState.instructions => _buildInstructions(),
            _ScreenState.preview => _buildPreview(),
            _ScreenState.result => _buildResult(),
            _ScreenState.alreadyVerified => _buildAlreadyVerified(),
          },
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final attemptsLeft = 3 - (_status?.attemptsToday ?? 0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Face guide illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade300, width: 3),
              color: Colors.blue.shade50,
            ),
            child: Icon(
              Icons.face,
              size: 120,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.takeSelfieToVerify,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.selfieVerifyDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),
          // Tips
          _buildTip(Icons.light_mode, AppLocalizations.of(context)!.selfieTip1),
          _buildTip(Icons.face_retouching_natural, AppLocalizations.of(context)!.selfieTip2),
          _buildTip(Icons.no_accounts,
              AppLocalizations.of(context)!.selfieTip3),
          const SizedBox(height: 16),
          if (attemptsLeft < 3)
            Text(
              '$attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} remaining today',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: attemptsLeft > 0 ? _takeSelfie : null,
              icon: const Icon(Icons.camera_alt),
              label: Text(AppLocalizations.of(context)!.takeSelfie),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Selfie preview in circular frame
          ClipOval(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.file(
                _selfieFile!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.lookingGood,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selfiePreviewDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Spacer(),
          if (_isLoading)
            Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.verifyingIdentity),
              ],
            )
          else ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _submitSelfie,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.submitForVerification),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _retake,
              child: Text(AppLocalizations.of(context)!.retakePhoto),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    final isSuccess = result.decision == VerificationDecision.verified;
    final isPending = result.decision == VerificationDecision.pendingReview;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Result icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSuccess
                  ? Colors.green.shade50
                  : isPending
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
            ),
            child: Icon(
              isSuccess
                  ? Icons.verified
                  : isPending
                      ? Icons.hourglass_top
                      : Icons.error_outline,
              size: 64,
              color: isSuccess
                  ? Colors.green
                  : isPending
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSuccess
                ? AppLocalizations.of(context)!.verified
                : isPending
                    ? AppLocalizations.of(context)!.underReview
                    : AppLocalizations.of(context)!.verificationFailedResult,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSuccess
                      ? Colors.green
                      : isPending
                          ? Colors.orange
                          : Colors.red,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          if (isSuccess) ...[
            const SizedBox(height: 24),
            const VerificationBadge(isVerified: true, size: 48, showLabel: true),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                if (isSuccess) {
                  Navigator.of(context).pop(true); // Return success
                } else if (result.decision == VerificationDecision.rejected) {
                  _retake(); // Let them try again
                } else {
                  Navigator.of(context).pop(false);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isSuccess
                    ? 'Done'
                    : result.decision == VerificationDecision.rejected
                        ? 'Try Again'
                        : 'Close',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyVerified() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const VerificationBadge(isVerified: true, size: 64, showLabel: true),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.alreadyVerified,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.alreadyVerifiedDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.goBackButton),
          ),
        ],
      ),
    );
  }
}

enum _ScreenState {
  instructions,
  preview,
  result,
  alreadyVerified,
}
