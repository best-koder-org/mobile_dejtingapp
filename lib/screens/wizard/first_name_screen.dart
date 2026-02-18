import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

class FirstNameScreen extends StatefulWidget {
  const FirstNameScreen({super.key});
  @override
  State<FirstNameScreen> createState() => _FirstNameScreenState();
}

class _FirstNameScreenState extends State<FirstNameScreen> {
  final _ctrl = TextEditingController();
  bool get _isValid => RegExp(r"^[a-zA-ZÀ-ÿ '-]{2,50}$").hasMatch(_ctrl.text.trim());

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => OnboardingProvider.of(context).abort(context))],
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
                      Text(AppLocalizations.of(context).whatsYourFirstName, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context).nameAppearOnProfile, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).firstNameHint,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: const UnderlineInputBorder(),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 2)),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isValid ? () { OnboardingProvider.of(context).data.firstName = _ctrl.text.trim(); OnboardingProvider.of(context).goNext(context); } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isValid ? const Color(0xFFFF6B6B) : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                          ),
                          child: Text(AppLocalizations.of(context).nextButton, style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          DevModeSkipButton(
            onSkip: () { OnboardingProvider.of(context).data.firstName = _ctrl.text.trim(); OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Name',
          ),
        ],
      ),
    );
  }
}
