import 'package:flutter/material.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Match Preferences Screen (ONB-100)
/// Who do you want to match with? Select gender preferences.
class MatchPreferencesScreen extends StatefulWidget {
  const MatchPreferencesScreen({super.key});

  @override
  State<MatchPreferencesScreen> createState() => _MatchPreferencesScreenState();
}

class _MatchPreferencesScreenState extends State<MatchPreferencesScreen> {
  String? _selected;

  static const _options = ['Men', 'Women', 'Everyone'];

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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: OnboardingProvider.of(context).progress(context),
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B6B)),
                  minHeight: 4,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Show me',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),
                      ..._options.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selected = option),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _selected == option
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.grey,
                                width: 2,
                              ),
                              backgroundColor: _selected == option
                                  ? const Color(0xFFFF6B6B).withAlpha(25)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 18,
                                color: _selected == option
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      )),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _selected != null
                              ? () { OnboardingProvider.of(context).data.preferredGender = _selected; OnboardingProvider.of(context).goNext(context); }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selected != null
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          DevModeSkipButton(
            onSkip: () { OnboardingProvider.of(context).data.preferredGender = _selected; OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Prefs',
          ),
        ],
      ),
    );
  }
}
