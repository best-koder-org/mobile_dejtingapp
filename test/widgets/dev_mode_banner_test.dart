import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/config/dev_mode.dart';
import 'package:dejtingapp/widgets/dev_mode_banner.dart';

import '../helpers/core_screen_test_helper.dart';

void main() {
  group('DevModeBanner', () {
    setUp(() => DevMode.enabled = true);
    tearDown(() => DevMode.enabled = true);

    testWidgets('renders without errors when dev mode is enabled',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: DevModeBanner()),
        ),
      );
      expect(find.byType(DevModeBanner), findsOneWidget);
    });

    testWidgets('shows banner text in dev mode', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: DevModeBanner()),
        ),
      );
      expect(
        find.text('🐛 DEV MODE — Skip buttons enabled'),
        findsOneWidget,
      );
    });

    testWidgets('banner has orange background color', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: DevModeBanner()),
        ),
      );
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.color == Colors.orange,
        ),
      );
      expect(container, isNotNull);
    });

    testWidgets('renders as empty SizedBox when dev mode is disabled',
        (tester) async {
      DevMode.enabled = false;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const Scaffold(body: DevModeBanner()),
        ),
      );
      expect(find.text('🐛 DEV MODE — Skip buttons enabled'), findsNothing);
    });
  });

  group('DevModeSkipButton', () {
    setUp(() => DevMode.enabled = true);
    tearDown(() => DevMode.enabled = true);

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Stack(
              children: [DevModeSkipButton(onSkip: () {})],
            ),
          ),
        ),
      );
      expect(find.byType(DevModeSkipButton), findsOneWidget);
    });

    testWidgets('shows default skip label in dev mode', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Stack(
              children: [DevModeSkipButton(onSkip: () {})],
            ),
          ),
        ),
      );
      expect(find.text('Skip →'), findsOneWidget);
    });

    testWidgets('shows custom label when provided', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Stack(
              children: [
                DevModeSkipButton(onSkip: () {}, label: 'Custom Skip'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Custom Skip'), findsOneWidget);
    });

    testWidgets('fires onSkip callback when tapped', (tester) async {
      var skipped = false;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Stack(
              children: [DevModeSkipButton(onSkip: () => skipped = true)],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Skip →'));
      expect(skipped, isTrue);
    });

    testWidgets('renders as empty SizedBox when dev mode is disabled',
        (tester) async {
      DevMode.enabled = false;
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: Scaffold(
            body: Stack(
              children: [DevModeSkipButton(onSkip: () {})],
            ),
          ),
        ),
      );
      expect(find.text('Skip →'), findsNothing);
    });
  });
}
