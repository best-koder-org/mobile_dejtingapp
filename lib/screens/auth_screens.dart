import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';

import '../config/environment.dart';
import '../services/auth_session_manager.dart';

/// Login Screen — Phone-first, passwordless (Tinder-style).
/// Primary: "Continue with Phone Number" → phone entry → SMS OTP → Firebase → Keycloak JWT
/// Fallback: "Sign in with Browser" → PKCE flow (dev/testing)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _loginWithPKCE() async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthSessionManager.loginWithPKCE();

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Browser login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Browser login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.brandGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & branding
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DatingApp',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your perfect match',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Dark card for the actions
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(216),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha(25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Phone icon + info
                        const Icon(Icons.phone_android, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No passwords needed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in with your phone number.\nWe\'ll text you a verification code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(160),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // PRIMARY — Continue with Phone Number
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                            icon: const Icon(Icons.sms, size: 20),
                            label: const Text(
                              'Continue with Phone Number',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withAlpha(60))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.white.withAlpha(60))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // PKCE login — secure browser-based auth (dev/fallback)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginWithPKCE,
                            icon: const Icon(Icons.lock_outline, size: 20),
                            label: _isLoading
                                ? const SizedBox(
                                    height: 22, width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign in with Browser',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withAlpha(100)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Skip to onboarding (dev)
                  if (EnvironmentConfig.isDevelopment)
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/welcome'),
                      icon: Icon(Icons.explore, color: Colors.white.withAlpha(180), size: 18),
                      label: Text(
                        'Skip to onboarding',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Registration is now implicit — phone verification creates accounts automatically.
/// This class is kept for backward compatibility with route definitions but redirects
/// to the phone entry screen.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Registration = phone verification (automatic account creation in Keycloak via Firebase IDP)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/onboarding/phone-entry');
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
