import 'package:flutter/material.dart';
import '../../config/dev_mode.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Email collection screen — placed after phone verification.
/// Email is used for account recovery, receipts, and communication.
/// Optional but encouraged (can skip in DevMode).
class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});
  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  static const Color _coral = Color(0xFFFF6B6B);

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _showError = false;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool get _isValid => _emailRegex.hasMatch(_ctrl.text.trim());

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() {
        if (_showError && _isValid) _showError = false;
      });
    });

    // DevMode: pre-fill test email
    if (DevMode.enabled) {
      _ctrl.text = 'test@dejting.app';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_isValid) {
      setState(() => _showError = true);
      return;
    }
    OnboardingProvider.of(context).data.email = _ctrl.text.trim();
    OnboardingProvider.of(context).goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: OnboardingProvider.of(context).progress(context),
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(_coral),
                  minHeight: 4,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        "What's your email?",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "We'll use this for account recovery and important updates. "
                        "It won't be shown on your profile.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // DevMode banner
                      if (DevMode.enabled)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bug_report,
                                  color: Colors.green[700], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Test mode: test@dejting.app pre-filled',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Email input
                      TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleNext(),
                        style: const TextStyle(fontSize: 22),
                        decoration: InputDecoration(
                          hintText: 'name@example.com',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: _isValid ? _coral : Colors.grey[400],
                          ),
                          border: const UnderlineInputBorder(),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: _coral, width: 2),
                          ),
                          errorBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.red, width: 2),
                          ),
                          errorText: _showError && !_isValid
                              ? 'Please enter a valid email address'
                              : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Privacy note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline,
                                color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your email is private. Other users can\'t see it.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isValid ? _handleNext : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isValid ? _coral : Colors.grey[300],
                            disabledBackgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey[500],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            elevation: _isValid ? 2 : 0,
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          DevModeSkipButton(
            onSkip: () {
              OnboardingProvider.of(context).data.email = _ctrl.text.trim();
              OnboardingProvider.of(context).goNext(context);
            },
            label: 'Skip Email',
          ),
        ],
      ),
    );
  }
}
