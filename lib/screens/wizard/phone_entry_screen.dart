import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:smart_auth/smart_auth.dart';
import '../../config/dev_mode.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Phone Number Entry Screen
/// On Android: auto-shows Phone Number Hint popup (one-tap, like Uber/Rider).
/// User picks their SIM number from system dialog — no manual typing.
/// Fallback: manual entry with country selector.
///
/// In DevMode: pre-fills test phone number so you just tap Continue.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  static const Color coralColor = Color(0xFFFF6B6B);

  final TextEditingController _phoneController = TextEditingController();
  final SmartAuth _smartAuth = SmartAuth.instance;
  String _selectedCountryCode = '+46';
  String _selectedCountryFlag = '🇸🇪';
  bool _isValidPhone = false;
  bool _isSending = false;
  String? _errorMessage;
  bool _hintShown = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);

    // DevMode: pre-fill test phone number so user just taps Continue
    if (DevMode.enabled) {
      _phoneController.text = DevMode.fakePhoneLocal;
      _selectedCountryCode = DevMode.fakeCountryCode;
      // Trigger validation immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validatePhone();
      });
    } else {
      // Auto-show phone number hint on Android after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestPhoneNumberHint();
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Show Android system Phone Number Hint dialog.
  /// User picks their SIM number — auto-fills the field.
  Future<void> _requestPhoneNumberHint() async {
    if (_hintShown) return;
    _hintShown = true;

    // Only works on Android
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('📱 Phone hint skipped (not Android)');
      return;
    }

    try {
      final res = await _smartAuth.requestPhoneNumberHint();
      if (res.hasData && res.data != null) {
        final phone = res.data!;
        debugPrint('📱 Phone hint selected: $phone');
        _parseAndFillPhone(phone);
      } else {
        debugPrint('📱 Phone hint dismissed by user');
      }
    } catch (e) {
      debugPrint('📱 Phone hint error: $e');
      // Silently fall through to manual entry
    }
  }

  /// Parse a full international phone number and fill the UI fields.
  /// e.g. "+46701234567" → country code "+46", number "701234567"
  void _parseAndFillPhone(String fullPhone) {
    // Common country codes sorted by length (longest first to avoid partial matches)
    final countryCodes = {
      '+46': '🇸🇪', // Sweden
      '+44': '🇬🇧', // UK
      '+49': '🇩🇪', // Germany
      '+33': '🇫🇷', // France
      '+1': '🇺🇸', // US/Canada
    };

    String detectedCode = '+46';
    String detectedFlag = '🇸🇪';
    String localNumber = fullPhone;

    for (final entry in countryCodes.entries) {
      if (fullPhone.startsWith(entry.key)) {
        detectedCode = entry.key;
        detectedFlag = entry.value;
        localNumber = fullPhone.substring(entry.key.length);
        break;
      }
    }

    setState(() {
      _selectedCountryCode = detectedCode;
      _selectedCountryFlag = detectedFlag;
      _phoneController.text = localNumber;
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d+]'), '');
    setState(() {
      // Allow either local number (9-15 digits) or full international (+XX...)
      if (phone.startsWith('+')) {
        // User typed full international number — must be 10+ chars (e.g. +46700000001)
        final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
        _isValidPhone = digitsOnly.length >= 10 && digitsOnly.length <= 15;
      } else {
        final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
        _isValidPhone = digitsOnly.length >= 9 && digitsOnly.length <= 15;
      }
      _errorMessage = null;
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Country',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildCountryOption('🇸🇪', 'Sweden', '+46'),
            _buildCountryOption('🇺🇸', 'United States', '+1'),
            _buildCountryOption('🇬🇧', 'United Kingdom', '+44'),
            _buildCountryOption('🇩🇪', 'Germany', '+49'),
            _buildCountryOption('🇫🇷', 'France', '+33'),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryOption(String flag, String name, String code) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 32)),
      title: Text(name),
      trailing: Text(code,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: coralColor)),
      onTap: () {
        setState(() {
          _selectedCountryFlag = flag;
          _selectedCountryCode = code;
        });
        Navigator.pop(context);
        _validatePhone();
      },
    );
  }

  /// Build the full E.164 phone number, avoiding double country codes.
  /// Handles: "700000001" → "+46700000001"
  ///          "+46700000001" → "+46700000001" (no double prefix)
  ///          "46700000001" → "+46700000001" (detects raw country code without +)
  String _buildFullPhoneNumber() {
    final raw = _phoneController.text.replaceAll(RegExp(r'[\s\-()]'), '');

    // Case 1: User typed full international number with +
    if (raw.startsWith('+')) {
      return raw;
    }

    // Case 2: User typed country code without + (e.g. "46700000001")
    final codeDigits = _selectedCountryCode.substring(1); // "46"
    if (raw.startsWith(codeDigits) && raw.length > codeDigits.length + 6) {
      return '+$raw';
    }

    // Case 3: Local number only (e.g. "700000001")
    return '$_selectedCountryCode$raw';
  }

  /// Whether Firebase is available (only on Android/iOS).
  bool get _isFirebaseAvailable =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _handleContinue() async {
    if (!_isValidPhone || _isSending) return;

    final fullPhone = _buildFullPhoneNumber();
    debugPrint('📱 Sending verification to: $fullPhone');

    // Desktop (Linux/Windows/macOS): Firebase not available.
    // In DevMode, skip straight to SMS code screen with fake verificationId.
    if (!_isFirebaseAvailable) {
      if (DevMode.enabled) {
        debugPrint('🔧 DevMode on desktop: skipping Firebase, navigating to verify-code');
        Navigator.pushNamed(
          context,
          '/onboarding/verify-code',
          arguments: {
            'verificationId': 'dev-mode-desktop-fake-id',
            'phoneNumber': fullPhone,
          },
        );
        return;
      } else {
        setState(() {
          _errorMessage = 'Phone verification requires a mobile device (Android/iOS).';
        });
        return;
      }
    }


    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await FirebasePhoneAuthService.verifyPhoneNumber(
        phoneNumber: fullPhone,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _isSending = false);
          Navigator.pushNamed(
            context,
            '/onboarding/verify-code',
            arguments: {
              'verificationId': verificationId,
              'phoneNumber': fullPhone,
            },
          );
        },
        onVerificationCompleted: (credential) async {
          if (!mounted) return;
          final idToken =
              await FirebasePhoneAuthService.signInWithAutoCredential(
                  credential);
          if (!mounted) return;
          setState(() => _isSending = false);
          if (idToken != null) {
            Navigator.pushNamed(
              context,
              '/onboarding/verify-code',
              arguments: {
                'autoVerified': true,
                'firebaseIdToken': idToken,
                'phoneNumber': fullPhone,
              },
            );
          }
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _isSending = false;
            _errorMessage = message;
          });
        },
        onAutoRetrievalTimeout: () {
          debugPrint('Auto-retrieval timeout');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage =
              'Failed to send verification code. Please try again.';
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () =>
                OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(coralColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Can we get your number?',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We\'ll send you a text with a verification code. '
                    'Message and data rates may apply.',
                    style: TextStyle(
                        fontSize: 16, color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // DevMode banner showing pre-filled test number
                  if (DevMode.enabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                              'Test mode: ${DevMode.fakePhone} pre-filled. Tap Continue!',
                              style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Country selector + Phone input
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _errorMessage != null
                              ? Colors.red
                              : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _showCountryPicker,
                          child: Row(
                            children: [
                              Text(_selectedCountryFlag,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Text(_selectedCountryCode,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                            width: 1, height: 40, color: Colors.grey[300]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            autofocus:
                                defaultTargetPlatform != TargetPlatform.android,
                            enabled: !_isSending,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Phone number',
                              hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\s\-()+ ]')),
                              LengthLimitingTextInputFormatter(20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Tap to re-show phone hint (Android only, non-dev)
                  if (defaultTargetPlatform == TargetPlatform.android && !DevMode.enabled)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          _hintShown = false;
                          _requestPhoneNumberHint();
                        },
                        icon: const Icon(Icons.sim_card,
                            size: 18, color: coralColor),
                        label: const Text(
                          'Use a different SIM number',
                          style: TextStyle(color: coralColor, fontSize: 14),
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'When you tap "Continue", we\'ll send you a text with a verification code.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isValidPhone && !_isSending)
                          ? _handleContinue
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coralColor,
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                        elevation: _isValidPhone ? 2 : 0,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Continue',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          DevModeSkipButton(
            onSkip: () => OnboardingProvider.of(context).goNext(context),
            label: 'Skip Phone',
          ),
        ],
      ),
    );
  }
}
