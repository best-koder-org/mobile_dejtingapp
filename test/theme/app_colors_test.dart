import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/theme/app_colors.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/theme/quiet_room_theme.dart';

/// REGRESSION PIN: `AppColors.coral` must stay byte-identical to the legacy
/// `AppTheme.*` static constants. If this test fails, a palette change would
/// visually alter the existing Coral app — treat as a hard blocker.
void main() {
  group('AppColors.coral regression pin', () {
    const c = AppColors.coral;

    test('brand tokens match AppTheme', () {
      expect(c.primary, AppTheme.primaryColor);
      expect(c.onPrimary, AppTheme.textOnPrimary);
      expect(c.primarySubtle, AppTheme.primarySubtle);
      expect(c.secondary, AppTheme.secondaryColor);
      expect(c.tertiary, AppTheme.tertiaryColor);
    });

    test('surface + divider tokens match AppTheme', () {
      expect(c.scaffold, AppTheme.scaffoldDark);
      expect(c.surface, AppTheme.surfaceColor);
      expect(c.surfaceElevated, AppTheme.surfaceElevated);
      expect(c.divider, AppTheme.dividerColor);
    });

    test('text tokens match AppTheme', () {
      expect(c.textPrimary, AppTheme.textPrimary);
      expect(c.textSecondary, AppTheme.textSecondary);
      expect(c.textTertiary, AppTheme.textTertiary);
    });

    test('semantic tokens match AppTheme', () {
      expect(c.success, AppTheme.successColor);
      expect(c.error, AppTheme.errorColor);
    });

    test('shape tokens match AppTheme', () {
      expect(c.radiusSm, AppTheme.radiusSm);
      expect(c.radiusMd, AppTheme.radiusMd);
      expect(c.radiusLg, AppTheme.radiusLg);
    });

    test('hero gradient == AppTheme.brandGradient colors', () {
      expect(c.heroGradientBegin, AppTheme.primaryColor);
      expect(c.heroGradientEnd, AppTheme.secondaryColor);
      // brandGradient is a diagonal coral→purple gradient.
      final gradient = AppTheme.brandGradient;
      expect(gradient.colors.first, AppTheme.primaryColor);
      expect(gradient.colors.last, AppTheme.secondaryColor);
    });

    test('hero panel color == legacy translucent black (alpha 216)', () {
      expect(c.heroPanelColor, Colors.black.withAlpha(216));
    });
  });

  group('AppColors theme resolution', () {
    testWidgets('coral theme exposes AppColors.coral', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const _Probe(),
        ),
      );
      expect(AppColors.of(tester.element(find.byType(_Probe))), AppColors.coral);
    });

    testWidgets('quiet room theme exposes AppColors.quietRoom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuietRoomTheme.darkTheme,
          home: const _Probe(),
        ),
      );
      expect(
        AppColors.of(tester.element(find.byType(_Probe))),
        AppColors.quietRoom,
      );
    });

    testWidgets('theme without extension falls back to coral (test parity)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const _Probe()),
      );
      expect(AppColors.of(tester.element(find.byType(_Probe))), AppColors.coral);
    });
  });
}

class _Probe extends StatelessWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}
