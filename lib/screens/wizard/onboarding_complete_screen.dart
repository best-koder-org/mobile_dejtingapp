import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/onboarding_api_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Onboarding Complete Screen
/// Submits wizard data to UserService, then celebrates and navigates to /home.
class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  State<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isSubmitting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Submit wizard data as soon as screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _submitProfile());
  }

  Future<void> _submitProfile() async {
    final data = OnboardingProvider.of(context).data;
    debugPrint('📋 Submitting onboarding data: $data');

    final error = await OnboardingApiService.submitAll(data);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _error = error;
    });

    if (error == null) {
      // Mark onboarding as complete in persistent storage
      final appState = AppState();
      await appState.setOnboardingComplete();
      // Success — play celebration animation
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-complete',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: SafeArea(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0,
                backgroundColor: AppTheme.dividerColor,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                minHeight: 4,
              ),
            ),
            Expanded(
              child: _isSubmitting
                  ? _buildSubmitting()
                  : _error != null
                      ? _buildError()
                      : _buildSuccess(),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSubmitting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).settingUpProfile,
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.orange),
          SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).somethingWentWrong,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSubmitting = true;
                  _error = null;
                });
                _submitProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
              ),
              child: Text(AppLocalizations.of(context).tryAgainButton,
                  style: TextStyle(fontSize: 18, color: AppTheme.textOnPrimary)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Skip API and go home anyway
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            },
            child: Text(AppLocalizations.of(context).skipForNow,
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7F50), AppTheme.primaryColor],
                ),
              ),
              child: const Icon(Icons.check, size: 64, color: AppTheme.textOnPrimary),
            ),
          ),
          SizedBox(height: 40),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).youreAllSet,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).profileReadySubtitle,
                  style:
                      TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27)),
                ),
                child: Text(AppLocalizations.of(context).startExploring,
                    style: TextStyle(fontSize: 18, color: AppTheme.textOnPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
