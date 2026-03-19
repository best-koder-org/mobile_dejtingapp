import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/dev_mode.dart';
import '../services/dev_auto_login.dart';
import '../theme/app_theme.dart';

/// Welcome Screen — Two clear paths:
/// 1. "I'm ready to match" → registration/onboarding flow
/// 2. "Sign in" → returning user phone entry → home
///
/// In dev mode, shows a dev panel at the bottom with:
/// - "Dev Sign In" → auto-login as demo-user → /home
/// - "Fresh Onboarding" → clear session + go to onboarding
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _devLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: 'screen:onboarding-welcome',
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
          child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(216),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Flame icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          l10n.createAccount,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Terms text
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                            children: [
                              const TextSpan(text: 'By tapping Log In or Continue, you agree to our '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _openUrl('https://dejtingapp.com/terms'),
                                  child: Text(l10n.termsLink, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, decoration: TextDecoration.underline)),
                                ),
                              ),
                              const TextSpan(text: '. Learn how we process your data in our '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _openUrl('https://dejtingapp.com/privacy'),
                                  child: Text(l10n.privacyPolicyLink, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, decoration: TextDecoration.underline)),
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // PRIMARY CTA — "I'm ready to match" → registration/onboarding
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                              elevation: 2,
                            ),
                            child: Text(
                              l10n.readyToMatch,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SECONDARY — "Sign in" → returning user phone entry
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signin/phone-entry'),
                          child: Text(
                            l10n.signInButton,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dev panel — only in debug mode
              if (DevMode.enabled) _buildDevPanel(context),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDevPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bug_report, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'DEV MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Dev Sign In — auto-login as demo-user → /home
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _devLoggingIn ? null : _handleDevSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _devLoggingIn
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login, size: 18),
                    label: Text(
                      _devLoggingIn ? 'Signing in...' : 'Dev Sign In',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Fresh Onboarding — clear session + go to onboarding
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text(
                      'Fresh Onboard',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDevSignIn() async {
    setState(() => _devLoggingIn = true);
    try {
      await DevAutoLogin.ensureDemoSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dev sign-in failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _devLoggingIn = false);
    }
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
