import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/dev_mode.dart';
import '../../config/environment.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../services/auth_session_manager.dart';
import '../../services/api_service.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// SMS Verification Code Entry Screen
/// 6-digit code input with auto-advance, resend timer, and retry limits.
/// Verifies via Firebase → exchanges for Keycloak JWT → starts session.
///
/// Supports two modes:
/// 1. Onboarding mode (wrapped in OnboardingProvider) — advances to next wizard step
/// 2. Sign-in mode (no OnboardingProvider) — checks for existing profile → /home or error
///
/// In DevMode: auto-fills the test code (123456) and skips Keycloak if unavailable.
class SmsCodeScreen extends StatefulWidget {
  const SmsCodeScreen({super.key});

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 60;
  static const int _maxResends = 5;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  Timer? _resendTimer;
  int _secondsRemaining = _resendSeconds;
  bool _canResend = false;
  int _resendCount = 0;
  bool _isVerifying = false;
  String? _errorMessage;

  // Data from phone_entry_screen
  String? _verificationId;
  String? _phoneNumber;
  bool _autoVerified = false;
  String? _firebaseIdToken;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractRouteArgs();
      // DevMode: auto-fill test SMS code after a brief delay
      if (DevMode.enabled) {
        _autoFillTestCode();
      } else {
        _focusNodes[0].requestFocus();
      }
    });
  }

  /// Auto-fill the test SMS code in DevMode.
  /// - Desktop: fill + auto-submit (no Firebase available)
  /// - Emulator: fill + auto-submit (Firebase test mode, no real SMS)
  /// - Real phone: do NOT fill fake code — Firebase sends a real SMS
  ///   with a different code. Show a "Skip" button instead.
  void _autoFillTestCode() {
    if (_autoVerified || _hasNavigated) return;

    final isDesktop =
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
    final isRealMobileDevice = !isDesktop && !EnvironmentConfig.isEmulator;

    if (isRealMobileDevice) {
      // Real phone: don't fill fake code, let user type real SMS code
      // or use the DevMode skip button
      debugPrint('🔧 DevMode on real device: NOT filling fake code — waiting for real SMS or skip');
      _focusNodes[0].requestFocus();
      return;
    }

    // Desktop or Emulator: fill fake code
    final testCode = DevMode.fakeSmsCode; // "123456"
    for (int i = 0; i < _codeLength && i < testCode.length; i++) {
      _controllers[i].text = testCode[i];
    }
    setState(() {});

    // Auto-submit after brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_autoVerified && !_hasNavigated) {
        final code = _controllers.map((c) => c.text).join();
        if (code.length == _codeLength) {
          _verifyCode(code);
        }
      }
    });
  }

  void _extractRouteArgs() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    _verificationId = args['verificationId'] as String?;
    _phoneNumber = args['phoneNumber'] as String?;
    _autoVerified = args['autoVerified'] == true;
    _firebaseIdToken = args['firebaseIdToken'] as String?;

    // If auto-verified (Android), skip OTP entry — exchange token immediately
    if (_autoVerified && _firebaseIdToken != null) {
      debugPrint('🔐 Auto-verified — skipping OTP entry');
      _completeLogin(_firebaseIdToken!);
      return; // Don't let DevMode auto-fill interfere
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _secondsRemaining = _resendSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    final code = _controllers.map((c) => c.text).join();
    if (code.length == _codeLength) {
      _verifyCode(code);
    }
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  /// Whether we're in sign-in mode (no OnboardingProvider ancestor)
  bool get _isSignInMode => OnboardingProvider.maybeOf(context) == null;

  Future<void> _verifyCode(String code) async {
    if (_verificationId == null) {
      setState(() => _errorMessage = AppLocalizations.of(context).verificationSessionExpired);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Desktop DevMode: Firebase not available — skip verification
    if (DevMode.enabled &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      debugPrint('🔧 DevMode on desktop: skipping Firebase SMS verify');
      if (mounted) {
        _handlePostAuth();
      }
      return;
    }

    try {
      final firebaseIdToken = await FirebasePhoneAuthService.verifySmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );

      if (firebaseIdToken == null) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _errorMessage = AppLocalizations.of(context).invalidCode;
          });
          _clearCode();
        }
        return;
      }

      await _completeLogin(firebaseIdToken);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = AppLocalizations.of(context).verificationFailed;
        });
        _clearCode();
      }
    }
  }

  /// Exchange Firebase token → Keycloak JWT → start app session.
  Future<void> _completeLogin(String firebaseIdToken) async {
    setState(() => _isVerifying = true);

    try {
      final result = await AuthSessionManager.loginWithPhone(firebaseIdToken);

      if (!mounted) return;

      if (result.success) {
        _handlePostAuth();
      } else if (DevMode.enabled) {
        debugPrint('🔧 DevMode: Keycloak exchange failed, skipping forward. Error: ${result.message}');
        if (mounted) {
          _handlePostAuth();
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = result.message ?? AppLocalizations.of(context).loginFailed;
        });
        _clearCode();
      }
    } catch (e) {
      if (!mounted) return;
      if (DevMode.enabled) {
        debugPrint('🔧 DevMode: Login exception, skipping forward. Error: $e');
        _handlePostAuth();
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = AppLocalizations.of(context).couldNotCompleteLogin;
        });
        _clearCode();
      }
    }
  }

  /// Route after successful auth — depends on mode:
  /// - Onboarding mode → advance to next wizard step
  /// - Sign-in mode → check for existing profile → /home or show error
  Future<void> _handlePostAuth() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final onboarding = OnboardingProvider.maybeOf(context);

    if (onboarding != null) {
      // Onboarding mode — continue wizard
      onboarding.goNext(context);
      return;
    }

    // Sign-in mode — check if user has an existing profile
    final appState = AppState();
    final token = appState.authToken;
    final userId = appState.userId;

    if (token != null && userId != null) {
      try {
        final resp = await http.get(
          Uri.parse('${EnvironmentConfig.settings.gatewayUrl}/api/users/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (!mounted) return;

        if (resp.statusCode == 200) {
          // Existing user with profile → go to home
          await appState.setOnboardingComplete();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Profile check failed: $e');
      }
    }

    if (!mounted) return;

    // No profile found — this number isn't registered yet
    setState(() {
      _isVerifying = false;
      _errorMessage = AppLocalizations.of(context).accountNotFound;
    });
    _clearCode();
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _resendCode() {
    if (!_canResend || _resendCount >= _maxResends || _phoneNumber == null) return;

    setState(() {
      _resendCount++;
      _errorMessage = null;
    });

    _clearCode();

    FirebasePhoneAuthService.verifyPhoneNumber(
      phoneNumber: _phoneNumber!,
      onCodeSent: (newVerificationId) {
        _verificationId = newVerificationId;
      },
      onVerificationCompleted: (credential) async {
        final idToken = await FirebasePhoneAuthService.signInWithAutoCredential(credential);
        if (idToken != null) {
          _completeLogin(idToken);
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _errorMessage = message);
        }
      },
      onAutoRetrievalTimeout: () {
        debugPrint('Auto-retrieval timeout on resend');
      },
    );

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).codeResent(_maxResends - _resendCount)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboarding = OnboardingProvider.maybeOf(context);

    return Semantics(
      label: 'screen:onboarding-sms-code',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Progress bar — only in onboarding mode
                  if (onboarding != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: onboarding.progress(context),
                        backgroundColor: AppTheme.dividerColor,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Text(
                    l10n.enterVerificationCode,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _phoneNumber != null
                        ? l10n.codeSentToPhone(_phoneNumber!)
                        : l10n.codeSentToPhoneFallback,
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // DevMode banner
                  if (DevMode.enabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.successColor.withAlpha(120)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bug_report, color: AppTheme.successColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              EnvironmentConfig.isEmulator
                                  ? 'Test mode: code \${DevMode.fakeSmsCode} auto-filled'
                                  : 'Test mode: enter real SMS code or tap Skip below',
                              style: TextStyle(fontSize: 13, color: AppTheme.successColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 6 digit input boxes
                  Row(
                    children: List.generate(_codeLength, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == _codeLength - 1 ? 0 : 4,
                          ),
                          child: AspectRatio(
                            aspectRatio: 0.85,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (e) => _onKeyPress(i, e),
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                enabled: !_isVerifying,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _errorMessage != null ? AppTheme.errorColor : AppTheme.dividerColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _errorMessage != null ? AppTheme.errorColor : AppTheme.dividerColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: _focusNodes[i].hasFocus ? AppTheme.surfaceElevated : AppTheme.surfaceColor,
                                ),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (v) => _onDigitChanged(i, v),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 14)),
                  ],

                  const SizedBox(height: 32),

                  // Verifying spinner
                  if (_isVerifying)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primaryColor),
                          const SizedBox(height: 12),
                          Text(l10n.verifying, style: const TextStyle(color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),

                  // Resend section
                  if (!_isVerifying) ...[
                    Center(
                      child: _canResend && _resendCount < _maxResends
                          ? TextButton(
                              onPressed: _resendCode,
                              child: Text(
                                l10n.resendCode,
                                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            )
                          : Text(
                              _resendCount >= _maxResends
                                  ? l10n.maxResendReached
                                  : l10n.resendCodeIn(_secondsRemaining),
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                            ),
                    ),
                  ],

                  // DevMode: skip verification on real device
                  if (DevMode.enabled && !_isVerifying && !EnvironmentConfig.isEmulator) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          debugPrint('🔧 DevMode: skipping SMS verification');
                          _handlePostAuth();
                        },
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text(
                          'Skip verification (DevMode)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // "Go back" button for sign-in mode when account not found
                  if (_isSignInMode && _errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(l10n.goBackButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.smsRatesInfo,
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    ),
    );
  }
}
