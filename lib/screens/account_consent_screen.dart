import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
// Onboarding now uses named routes via main.dart

/// Account Consent & Language Selection Screen
/// Appears after OAuth (Google/Phone) but before profile wizard
/// Based on Tinder's consent flow pattern
class AccountConsentScreen extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? userPhotoUrl;
  final String authProvider; // 'google', 'phone', 'apple'
  
  const AccountConsentScreen({
    super.key,
    this.userEmail,
    this.userName,
    this.userPhotoUrl,
    required this.authProvider,
  });

  @override
  State<AccountConsentScreen> createState() => _AccountConsentScreenState();
}

class _AccountConsentScreenState extends State<AccountConsentScreen> {
  // Brand colors
  static const Color coralColor = Color(0xFFFF7F50);
  static const Color purpleColor = Color(0xFF7f13ec);
  
  static String _getProviderName(String provider, BuildContext context) {
    if (provider == 'google') return 'Google';
    if (provider == 'apple') return 'Apple';
    if (provider == 'phone') {
      return AppLocalizations.of(context)!.consentProviderPhone;
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providerName = _getProviderName(widget.authProvider, context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App branding
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [coralColor, purpleColor],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DejTing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      l10n.consentTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      l10n.consentSubtitle(providerName),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Account card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          // Profile photo
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: coralColor.withValues(alpha: 0.1),
                            backgroundImage: widget.userPhotoUrl != null
                                ? NetworkImage(widget.userPhotoUrl!)
                                : null,
                            child: widget.userPhotoUrl == null
                                ? const Icon(Icons.person, color: coralColor)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          
                          // Name and email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (widget.userEmail != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.userEmail!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Use another account button
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Trigger OAuth account picker again
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.person_outline, size: 20),
                      label: Text(l10n.consentAnotherAccount),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Legal consent text with links
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: l10n.consentLegalText),
                          TextSpan(
                            text: l10n.consentPrivacyPolicy,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: purpleColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchURL('https://dejting.se/privacy'),
                          ),
                          TextSpan(text: l10n.consentAnd),
                          TextSpan(
                            text: l10n.consentTermsOfUse,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: purpleColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchURL('https://dejting.se/terms'),
                          ),
                          TextSpan(text: l10n.consentForApp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Continue button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [coralColor, purpleColor],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/onboarding/phone-entry');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        l10n.continueButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Footer links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFooterLink(l10n.consentHelp, 'https://dejting.se/help'),
                      const SizedBox(width: 16),
                      _buildFooterLink(l10n.consentPrivacy, 'https://dejting.se/privacy'),
                      const SizedBox(width: 16),
                      _buildFooterLink(l10n.consentTerms, 'https://dejting.se/terms'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooterLink(String text, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
  
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
