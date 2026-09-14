import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'flavors/dejting_config.dart';
import 'flavors/flavor_config.dart';
import 'theme/app_theme.dart';
import 'theme/quiet_room_theme.dart';
import 'screens/welcome_screen.dart';
import 'config/dev_mode.dart';

/// DEV-ONLY preview runner.
///
/// Shows the Welcome screen rendered in the CURRENT Coral theme next to the
/// NEW Quiet Room theme so the direction can be reviewed side-by-side with
/// real fonts, before any wider migration.
///
/// Run with:
///   flutter run -d chrome -t lib/skin_preview_main.dart
///   flutter run -d web-server --web-port=8099 -t lib/skin_preview_main.dart
Future<void> main() async {
  FlavorConfig.current = DejtingFlavorConfig();
  // Hide the orange dev panel + dev auto-login for a clean visual comparison.
  DevMode.enabled = false;
  runApp(const _SkinPreviewApp());
}

class _SkinPreviewApp extends StatelessWidget {
  const _SkinPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Skin preview — Welcome screen'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Coral (current)'), Tab(text: 'Quiet Room')],
          ),
        ),
        body: TabBarView(
          children: [
            Theme(
              data: AppTheme.darkTheme,
              child: const WelcomeScreen(previewMode: true),
            ),
            Theme(
              data: QuietRoomTheme.darkTheme,
              child: const WelcomeScreen(previewMode: true),
            ),
          ],
        ),
      ),
    );
  }
}
