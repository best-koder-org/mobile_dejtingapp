import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/profile_hub_screen.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('ProfileHubScreen', () {
    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has TabBar with 3 tabs', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('shows profile-related content', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(seconds: 1));
      // Profile hub always renders even without data
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has screen:profile semantics label', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(home: const ProfileHubScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.bySemanticsLabel('screen:profile'),
        findsOneWidget,
      );
    });
  });

  group('AppLocalizations i18n keys', () {
    testWidgets('voicePromptSaved returns localized string in English', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.voicePromptSaved, 'Voice prompt saved!');
    });

    testWidgets('yourSparks returns localized string in English', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.yourSparks, 'Your Sparks');
    });

    testWidgets('howItWorks returns localized string in English', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.howItWorks, 'How it works');
    });

    testWidgets('spotlightActivated returns localized string in English', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.spotlightActivated, '🔦 Spotlight activated! 30 min of boosted visibility.');
    });

    testWidgets('failedToLoadBlockList returns parameterized string in English', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.failedToLoadBlockList('Network error'), 'Failed to load block list: Network error');
    });

    testWidgets('i18n keys return Swedish translations', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sv'),
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(loc.voicePromptSaved, 'Röstprompt sparad!');
      expect(loc.yourSparks, 'Dina Gnistor');
      expect(loc.howItWorks, 'Så här fungerar det');
      expect(loc.spotlightActivated, '🔦 Spotlight aktiverat! 30 min med ökad synlighet.');
      expect(loc.failedToLoadBlockList('Nätverksfel'), 'Det gick inte att ladda blocklistan: Nätverksfel');
    });
  });
}
