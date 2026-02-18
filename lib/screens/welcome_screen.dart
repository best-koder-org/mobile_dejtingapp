import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/dev_mode_banner.dart';

/// Welcome/Login Screen - Based on Stitch variant-02-multiauth design
/// Tinder-style dark modal with Apple/Google/Phone auth options
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color coralColor = Color(0xFFFF7F50);
  static const Color purpleColor = Color(0xFF7f13ec);
  static const Color googleBlue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [coralColor, purpleColor],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
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
                          color: coralColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                      ),
                      SizedBox(height: 16),

                      Text(
                        AppLocalizations.of(context).createAccount,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
                                child: Text(AppLocalizations.of(context).termsLink, style: const TextStyle(fontSize: 12, color: coralColor, decoration: TextDecoration.underline)),
                              ),
                            ),
                            const TextSpan(text: '. Learn how we process your data in our '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _openUrl('https://dejtingapp.com/privacy'),
                                child: Text(AppLocalizations.of(context).privacyPolicyLink, style: const TextStyle(fontSize: 12, color: coralColor, decoration: TextDecoration.underline)),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Apple Sign-In
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showComingSoon(context, 'Apple Sign-In'),
                          icon: const Icon(Icons.apple, size: 24),
                          label: Text(AppLocalizations.of(context).continueWithApple),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: const BorderSide(color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google Sign-In
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showComingSoon(context, 'Google Sign-In'),
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: Text(AppLocalizations.of(context).continueWithGoogle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: googleBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone Sign-In → starts onboarding
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                          icon: const Icon(Icons.phone, size: 20),
                          label: Text(AppLocalizations.of(context).signInWithPhone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: const BorderSide(color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => _showComingSoon(context, 'Password Recovery'),
                        child: Text(
                          AppLocalizations.of(context).troubleLoggingIn,
                          style: TextStyle(color: coralColor, fontSize: 14, decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // DevMode skip — jump straight into onboarding flow
              DevModeSkipButton(
                onSkip: () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                label: 'Skip to Onboarding',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).featureComingSoon(feature)), backgroundColor: coralColor),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
