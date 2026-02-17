import 'package:flutter/material.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Community Guidelines Screen
/// Shows house rules that users must accept before proceeding
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: OnboardingProvider.of(context).progress(context),
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B6B)),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Welcome to DejTing.',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please follow these House Rules.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildRule('Be yourself', 'Use authentic photos and accurate information about yourself.'),
                          const SizedBox(height: 28),
                          _buildRule('Stay safe', 'Protect your personal information and report any suspicious behavior.'),
                          const SizedBox(height: 28),
                          _buildRule('Play it cool', 'Treat everyone with respect and kindness.'),
                          const SizedBox(height: 28),
                          _buildRule('Be proactive', 'Take initiative and make meaningful connections.'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {  OnboardingProvider.of(context).goNext(context); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text('I agree', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          DevModeSkipButton(
            onSkip: () {  OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Rules',
          ),
        ],
      ),
    );
  }

  Widget _buildRule(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: Color(0xFF00C878), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black, height: 1.3)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.black54, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
