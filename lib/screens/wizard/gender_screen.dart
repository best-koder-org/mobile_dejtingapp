import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});
  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _selected;
  bool _showOnProfile = false;

  static const _quickOptions = ['Man', 'Woman'];
  static const _allOptions = [
    'Man', 'Woman', 'Trans Man', 'Trans Woman', 'Non-binary',
    'Agender', 'Genderfluid', 'Genderqueer', 'Two-Spirit', 'Other',
  ];

  void _openMore() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).selectGenderSheet,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: _allOptions.map((g) => RadioListTile<String>(
                    title: Text(g, style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                    value: g,
                    groupValue: _selected,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) {
                      setState(() => _selected = v);
                      setSheetState(() {});
                      Navigator.pop(ctx);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-gender',
      child: Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: OnboardingProvider.of(context).progress(context),
              backgroundColor: AppTheme.dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    AppLocalizations.of(context).whatsYourGender,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ..._quickOptions.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selected = g),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _selected == g ? AppTheme.primaryColor : AppTheme.dividerColor,
                            width: 2,
                          ),
                          backgroundColor: _selected == g
                              ? AppTheme.primaryColor.withAlpha(25)
                              : AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 18,
                            color: _selected == g ? AppTheme.primaryColor : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _openMore,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: (_selected != null && !_quickOptions.contains(_selected))
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor,
                            width: 2,
                          ),
                          backgroundColor: (_selected != null && !_quickOptions.contains(_selected))
                              ? AppTheme.primaryColor.withAlpha(25)
                              : AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (_selected != null && !_quickOptions.contains(_selected))
                                  ? _selected!
                                  : AppLocalizations.of(context).moreOptions,
                              style: TextStyle(
                                fontSize: 18,
                                color: (_selected != null && !_quickOptions.contains(_selected))
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _showOnProfile = !_showOnProfile),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: Checkbox(
                            value: _showOnProfile,
                            activeColor: AppTheme.primaryColor,
                            checkColor: AppTheme.textOnPrimary,
                            side: const BorderSide(color: AppTheme.textSecondary, width: 2),
                            onChanged: (v) => setState(() => _showOnProfile = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).showGenderOnProfile,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _selected != null
                          ? () {
                              final d = OnboardingProvider.of(context).data;
                              d.gender = _selected;
                              d.genderVisible = _showOnProfile;
                              OnboardingProvider.of(context).goNext(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.surfaceElevated,
                        disabledForegroundColor: AppTheme.textTertiary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).nextButton,
                        style: const TextStyle(fontSize: 18, color: AppTheme.textOnPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    ),
    );
  }
}
