import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:smart_auth/smart_auth.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../widgets/dev_mode_banner.dart';

/// Phone Number Entry Screen
/// On Android: auto-shows Phone Number Hint popup (one-tap, like Uber/Rider).
/// User picks their SIM number from system dialog — no manual typing.
/// Fallback: manual entry with country selector.
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
    // Auto-show phone number hint on Android after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPhoneNumberHint();
    });
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
      '+46': '🇸🇪',  // Sweden
      '+44': '🇬🇧',  // UK
      '+49': '🇩🇪',  // Germany
      '+33': '🇫🇷',  // France
      '+1': '🇺🇸',   // US/Canada
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
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    setState(() {
      _isValidPhone = phone.length >= 9 && phone.length <= 15;
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
            const Text('Select Country', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
      trailing: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: coralColor)),
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

  Future<void> _handleContinue() async {
    if (!_isValidPhone || _isSending) return;

    final rawPhone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final fullPhone = '$_selectedCountryCode$rawPhone';

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
          final idToken = await FirebasePhoneAuthService.signInWithAutoCredential(credential);
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
          _errorMessage = 'Failed to send verification code. Please try again.';
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
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
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
                      value: 0.0,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(coralColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Can we get your number?',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We\'ll send you a text with a verification code. '
                    'Message and data rates may apply.',
                    style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // Country selector + Phone input
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _errorMessage != null ? Colors.red : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _showCountryPicker,
                          child: Row(
                            children: [
                              Text(_selectedCountryFlag, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Text(_selectedCountryCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            autofocus: defaultTargetPlatform != TargetPlatform.android, // Don't autofocus on Android (hint dialog takes focus)
                            enabled: !_isSending,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Phone number',
                              hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-()]')),
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

                  // Tap to re-show phone hint (Android only)
                  if (defaultTargetPlatform == TargetPlatform.android)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          _hintShown = false;
                          _requestPhoneNumberHint();
                        },
                        icon: const Icon(Icons.sim_card, size: 18, color: coralColor),
                        label: const Text(
                          'Use a different SIM number',
                          style: TextStyle(color: coralColor, fontSize: 14),
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'When you tap "Continue", we\'ll send you a text with a verification code.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
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
                      onPressed: (_isValidPhone && !_isSending) ? _handleContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coralColor,
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: _isValidPhone ? 2 : 0,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          DevModeSkipButton(
            onSkip: () => Navigator.pushNamed(context, '/onboarding/community-guidelines'),
            label: 'Skip Phone',
          ),
        ],
      ),
    );
  }
}
