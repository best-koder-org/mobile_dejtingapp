import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../config/dev_mode.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../services/auth_session_manager.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// SMS Verification Code Entry Screen
/// 6-digit code input with auto-advance, resend timer, and retry limits.
/// Verifies via Firebase → exchanges for Keycloak JWT → starts session.
///
/// In DevMode: auto-fills the test code (123456) and skips Keycloak if unavailable.
class SmsCodeScreen extends StatefulWidget {
  const SmsCodeScreen({super.key});

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  static const Color _coral = Color(0xFFFF6B6B);
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

  /// Auto-fill the test SMS code in DevMode so user doesn't have to type it
  void _autoFillTestCode() {
    final testCode = DevMode.fakeSmsCode; // "123456"
    for (int i = 0; i < _codeLength && i < testCode.length; i++) {
      _controllers[i].text = testCode[i];
    }
    setState(() {}); // refresh UI to show filled digits
    // Small delay then verify (gives user a moment to see what's happening)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
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
      _completeLogin(_firebaseIdToken!);
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

  Future<void> _verifyCode(String code) async {
    if (_verificationId == null) {
      setState(() => _errorMessage = 'Verification session expired. Go back and try again.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Desktop DevMode: Firebase not available — skip verification, go forward
    if (DevMode.enabled &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      debugPrint('🔧 DevMode on desktop: skipping Firebase SMS verify');
      if (mounted) {
        OnboardingProvider.of(context).goNext(context);
      }
      return;
    }

    try {
      // Verify OTP with Firebase
      final firebaseIdToken = await FirebasePhoneAuthService.verifySmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );

      if (firebaseIdToken == null) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _errorMessage = 'Invalid code. Please try again.';
          });
          _clearCode();
        }
        return;
      }

      // Firebase verified — now exchange for Keycloak JWT
      await _completeLogin(firebaseIdToken);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Verification failed. Please try again.';
        });
        _clearCode();
      }
    }
  }

  /// Exchange Firebase token → Keycloak JWT → start app session.
  /// In DevMode: if Keycloak is unavailable, skip forward anyway.
  Future<void> _completeLogin(String firebaseIdToken) async {
    setState(() => _isVerifying = true);

    try {
      final result = await AuthSessionManager.loginWithPhone(firebaseIdToken);

      if (!mounted) return;

      if (result.success) {
        // Phone verified + Keycloak session active → continue onboarding
        OnboardingProvider.of(context).goNext(context);
      } else if (DevMode.enabled) {
        // DevMode: Keycloak exchange failed (probably not running) — skip forward
        debugPrint('🔧 DevMode: Keycloak exchange failed, skipping forward. Error: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔧 DevMode: Skipped Keycloak (not running). Phone verified via Firebase.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          OnboardingProvider.of(context).goNext(context);
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = result.message ?? 'Login failed. Please try again.';
        });
        _clearCode();
      }
    } catch (e) {
      if (!mounted) return;
      if (DevMode.enabled) {
        // DevMode: any exception during login → skip forward
        debugPrint('🔧 DevMode: Login exception, skipping forward. Error: $e');
        OnboardingProvider.of(context).goNext(context);
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Could not complete phone login. Please try again.';
        });
        _clearCode();
      }
    }
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

    // Re-send SMS via Firebase
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
        content: Text('Code resent (${_maxResends - _resendCount} left)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(_coral),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Enter verification\ncode',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _phoneNumber != null
                        ? 'We sent a 6-digit code to $_phoneNumber'
                        : 'We sent a 6-digit code to your phone number.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // DevMode banner
                  if (DevMode.enabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.green[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Test mode: code ${DevMode.fakeSmsCode} auto-filled',
                              style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 6 digit input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (i) {
                      return SizedBox(
                        width: 48,
                        height: 56,
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
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _coral, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: _focusNodes[i].hasFocus ? Colors.white : Colors.grey[50],
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                  ],

                  const SizedBox(height: 32),

                  // Verifying spinner
                  if (_isVerifying)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: _coral),
                          SizedBox(height: 12),
                          Text('Verifying...'),
                        ],
                      ),
                    ),

                  // Resend section
                  if (!_isVerifying) ...[
                    Center(
                      child: _canResend && _resendCount < _maxResends
                          ? TextButton(
                              onPressed: _resendCode,
                              child: const Text(
                                "Didn't receive it? Resend code",
                                style: TextStyle(color: _coral, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            )
                          : Text(
                              _resendCount >= _maxResends
                                  ? 'Maximum resend attempts reached'
                                  : 'Resend code in ${_secondsRemaining}s',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                    ),
                  ],

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Standard SMS rates may apply. The code will expire in 10 minutes.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DevModeSkipButton(
            onSkip: () => OnboardingProvider.of(context).goNext(context),
            label: 'Skip SMS',
          ),
        ],
      ),
    );
  }
}
