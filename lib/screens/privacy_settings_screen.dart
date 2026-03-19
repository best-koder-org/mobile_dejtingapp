import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).privacySettingsTitle),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context).privacySettingsComingSoon),
      ),
    );
  }
}
