import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _selectedLanguage = 'sv'; // 'sv' or 'en'
  
  // Brand colors
  static const Color coralColor = Color(0xFFFF7F50);
  static const Color purpleColor = Color(0xFF7f13ec);
  
  // Translations
  final Map<String, Map<String, String>> _translations = {
    'sv': {
      'title': 'Välj ett konto',
      'subtitle': 'Logga in med ${_getProviderName('google', 'sv')}',
      'anotherAccount': 'Använd ett annat konto',
      'legalText': 'Innan du använder appen kan du läsa igenom ',
      'privacyPolicy': 'integritetspolicyn',
      'and': ' och ',
      'termsOfUse': 'användarvillkoren',
      'forApp': ' för DejTing.',
      'continue': 'Fortsätt',
      'help': 'Hjälp',
      'privacy': 'Integritet',
      'terms': 'Villkor',
    },
    'en': {
      'title': 'Choose an account',
      'subtitle': 'Log in with ${_getProviderName('google', 'en')}',
      'anotherAccount': 'Use another account',
      'legalText': 'Before using the app, you can read through the ',
      'privacyPolicy': 'privacy policy',
      'and': ' and ',
      'termsOfUse': 'terms of use',
      'forApp': ' for DejTing.',
      'continue': 'Continue',
      'help': 'Help',
      'privacy': 'Privacy',
      'terms': 'Terms',
    },
  };
  
  static String _getProviderName(String provider, String lang) {
    if (provider == 'google') return 'Google';
    if (provider == 'phone') return lang == 'sv' ? 'Telefon' : 'Phone';
    if (provider == 'apple') return 'Apple';
    return provider;
  }
  
  String t(String key) => _translations[_selectedLanguage]![key]!;
  
  @override
  Widget build(BuildContext context) {
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
                      t('title'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      t('subtitle').replaceAll(_getProviderName('google', 'sv'), 
                                               _getProviderName(widget.authProvider, _selectedLanguage)),
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
                            backgroundColor: coralColor.withOpacity(0.1),
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
                      label: Text(t('anotherAccount')),
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
                          TextSpan(text: t('legalText')),
                          TextSpan(
                            text: t('privacyPolicy'),
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: purpleColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchURL('https://dejting.se/privacy'),
                          ),
                          TextSpan(text: t('and')),
                          TextSpan(
                            text: t('termsOfUse'),
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: purpleColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchURL('https://dejting.se/terms'),
                          ),
                          TextSpan(text: t('forApp')),
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
                    color: Colors.black.withOpacity(0.05),
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
                        t('continue'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Language selector and footer links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Language dropdown
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'sv', child: Text('🇸🇪 Svenska')),
                          DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLanguage = value);
                          }
                        },
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      
                      // Footer links
                      Row(
                        children: [
                          _buildFooterLink(t('help'), 'https://dejting.se/help'),
                          const SizedBox(width: 16),
                          _buildFooterLink(t('privacy'), 'https://dejting.se/privacy'),
                          const SizedBox(width: 16),
                          _buildFooterLink(t('terms'), 'https://dejting.se/terms'),
                        ],
                      ),
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
