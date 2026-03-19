import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/profanity_filter.dart';

class FirstNameScreen extends StatefulWidget {
  const FirstNameScreen({super.key});
  @override
  State<FirstNameScreen> createState() => _FirstNameScreenState();
}

class _FirstNameScreenState extends State<FirstNameScreen> {
  final _ctrl = TextEditingController();

  String get _trimmed => _ctrl.text.trim();

  bool get _formatValid =>
      RegExp(r"^[a-zA-ZÀ-ÿ '-]{2,50}$").hasMatch(_trimmed);

  bool get _isOffensive => ProfanityFilter.isOffensive(_trimmed);

  bool get _isValid => _formatValid && !_isOffensive;

  /// Error text shown below the input (null = no error).
  String? _errorText(AppLocalizations l10n) {
    if (_trimmed.isEmpty) return null;
    if (!_formatValid) return null; // let the regex hint be implicit
    if (_isOffensive) return l10n.nameNotAllowed;
    return null;
  }

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

  void _showVisibilityInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.visibility, color: AppTheme.textPrimary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.alwaysVisibleOnProfile,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.visibilityExplanation,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textPrimary,
                    foregroundColor: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(l10n.gotItButton,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
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
                    l10n.whatsYourFirstName,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.nameAppearOnProfile,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 24, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.firstNameHint,
                      hintStyle: TextStyle(color: AppTheme.textTertiary),
                      errorText: _errorText(l10n),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      border: const UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isOffensive
                              ? Colors.redAccent
                              : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent, width: 2),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Visibility hint row
                  GestureDetector(
                    onTap: _showVisibilityInfo,
                    child: Row(
                      children: [
                        Icon(Icons.visibility,
                            color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.alwaysVisibleOnProfile,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full-width Next button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () {
                              OnboardingProvider.of(context).data.firstName =
                                  _trimmed;
                              OnboardingProvider.of(context).goNext(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.surfaceColor,
                        disabledBackgroundColor: AppTheme.surfaceElevated,
                        disabledForegroundColor: AppTheme.textTertiary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.nextButton,
                            style: const TextStyle(
                                fontSize: 18, color: AppTheme.textOnPrimary),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              color: AppTheme.textOnPrimary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
