import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:smart_auth/smart_auth.dart';
import '../../config/dev_mode.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

/// Phone Number Entry Screen
/// On Android: auto-shows Phone Number Hint popup (one-tap, like Uber/Rider).
/// User picks their SIM number from system dialog — no manual typing.
/// Fallback: manual entry with country selector.
///
/// Supports two modes:
/// 1. Onboarding mode (wrapped in OnboardingProvider) — shows progress bar + abort button
/// 2. Sign-in mode (no OnboardingProvider) — shows "Welcome back" title, no progress bar
///
/// In DevMode: pre-fills test phone number so you just tap Continue.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  static const Color coralColor = AppTheme.primaryColor;

  final TextEditingController _phoneController = TextEditingController();
  final SmartAuth _smartAuth = SmartAuth.instance;
  String _selectedCountryCode = '+46';
  String _selectedCountryFlag = '🇸🇪';
  bool _isValidPhone = false;
  bool _isSending = false;
  String? _errorMessage;
  bool _hintShown = false;
  bool _navigatedToVerifyCode = false;

  /// Whether we're inside the onboarding wizard (has OnboardingProvider ancestor)

  /// Route prefix for navigation — '/onboarding' or '/signin'
  String get _routePrefix {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    if (route.startsWith('/signin')) return '/signin';
    return '/onboarding';
  }

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
  void _parseAndFillPhone(String fullPhone) {
    final countryCodes = {
      '+46': '🇸🇪',
      '+44': '🇬🇧',
      '+49': '🇩🇪',
      '+33': '🇫🇷',
      '+1': '🇺🇸',
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
      if (phone.startsWith('+')) {
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
            Text(AppLocalizations.of(context).selectCountry,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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

  String _buildFullPhoneNumber() {
    final raw = _phoneController.text.replaceAll(RegExp(r'[\s\-()]'), '');

    if (raw.startsWith('+')) {
      return raw;
    }

    final codeDigits = _selectedCountryCode.substring(1);
    if (raw.startsWith(codeDigits) && raw.length > codeDigits.length + 6) {
      return '+$raw';
    }

    return '$_selectedCountryCode$raw';
  }

  bool get _isFirebaseAvailable =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _handleContinue() async {
    if (!_isValidPhone || _isSending) return;

    final fullPhone = _buildFullPhoneNumber();
    debugPrint('📱 Sending verification to: $fullPhone');

    // Desktop DevMode: skip Firebase
    if (!_isFirebaseAvailable) {
      if (DevMode.enabled) {
        debugPrint('🔧 DevMode on desktop: skipping Firebase, navigating to verify-code');
        Navigator.pushNamed(
          context,
          '$_routePrefix/verify-code',
          arguments: {
            'verificationId': 'dev-mode-desktop-fake-id',
            'phoneNumber': fullPhone,
          },
        );
        return;
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context).phoneVerificationMobileOnly;
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
          if (!mounted || _navigatedToVerifyCode) return;
          _navigatedToVerifyCode = true;
          setState(() => _isSending = false);
          Navigator.pushNamed(
            context,
            '$_routePrefix/verify-code',
            arguments: {
              'verificationId': verificationId,
              'phoneNumber': fullPhone,
            },
          );
        },
        onVerificationCompleted: (credential) async {
          if (!mounted || _navigatedToVerifyCode) return;
          final idToken =
              await FirebasePhoneAuthService.signInWithAutoCredential(
                  credential);
          if (!mounted || _navigatedToVerifyCode) return;
          _navigatedToVerifyCode = true;
          setState(() => _isSending = false);
          if (idToken != null) {
            Navigator.pushNamed(
              context,
              '$_routePrefix/verify-code',
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
              AppLocalizations.of(context).failedToSendCode;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboarding = OnboardingProvider.maybeOf(context);
    final isSignIn = onboarding == null;

    return Semantics(
      label: 'screen:onboarding-phone-entry',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isSignIn)
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textPrimary),
              onPressed: () => onboarding.abort(context),
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
                  // Progress bar — only in onboarding mode
                  if (!isSignIn) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: onboarding.progress(context),
                        backgroundColor: AppTheme.dividerColor,
                        valueColor: const AlwaysStoppedAnimation(coralColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Title — different for sign-in vs onboarding
                  Text(
                    isSignIn ? l10n.welcomeBack : l10n.onboardingPhoneTitle,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  if (isSignIn) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.signInWithPhoneDescription,
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // DevMode banner
                  if (DevMode.enabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                              'Test mode: ${DevMode.fakePhone} pre-filled. Tap Continue!',
                              style: TextStyle(fontSize: 13, color: AppTheme.successColor, fontWeight: FontWeight.w500),
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
                              ? AppTheme.errorColor
                              : AppTheme.dividerColor),
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
                            width: 1, height: 40, color: AppTheme.dividerColor),
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
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: l10n.phoneNumberHint,
                              hintStyle: const TextStyle(
                                  color: AppTheme.textSecondary,
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
                      style: const TextStyle(color: AppTheme.errorColor, fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // SIM hint (Android only, non-dev)
                  if (defaultTargetPlatform == TargetPlatform.android && !DevMode.enabled)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          _hintShown = false;
                          _requestPhoneNumberHint();
                        },
                        icon: const Icon(Icons.sim_card,
                            size: 18, color: coralColor),
                        label: Text(
                          l10n.useDifferentSim,
                          style: const TextStyle(color: coralColor, fontSize: 14),
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.textPrimary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.continueInfoBox,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isValidPhone && !_isSending)
                          ? _handleContinue
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coralColor,
                        disabledBackgroundColor: AppTheme.surfaceElevated,
                        foregroundColor: AppTheme.surfaceColor,
                        disabledForegroundColor: AppTheme.textTertiary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                        elevation: _isValidPhone ? 2 : 0,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: AppTheme.textOnPrimary, strokeWidth: 2.5),
                            )
                          : Text(l10n.continueButton,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
