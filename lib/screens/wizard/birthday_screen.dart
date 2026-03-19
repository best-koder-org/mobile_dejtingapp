import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});
  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  int? _month;
  int? _day;
  int? _year;

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<int> get _yearOptions {
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final minYear = now.year - 90;
    return List.generate(maxYear - minYear + 1, (i) => maxYear - i);
  }

  List<int> get _dayOptions {
    if (_month == null) return List.generate(31, (i) => i + 1);
    final year = _year ?? DateTime.now().year;
    final daysInMonth = DateUtils.getDaysInMonth(year, _month!);
    return List.generate(daysInMonth, (i) => i + 1);
  }

  bool get _isValid => _month != null && _day != null && _year != null;

  int _calcAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _next() {
    final dob = DateTime(_year!, _month!, _day!);
    if (_calcAge(dob) < 18) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.of(context).ageRequirement),
          content: Text(AppLocalizations.of(context).mustBe18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).goBackButton),
            ),
          ],
        ),
      );
      return;
    }
    OnboardingProvider.of(context).data.dateOfBirth = DateTime(_year!, _month!, _day!);
    OnboardingProvider.of(context).goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'screen:onboarding-birthday',
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
                    AppLocalizations.of(context).yourBirthday,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).birthdayExplainer,
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: _buildDropdown<int>(
                          hint: 'DD',
                          value: _day,
                          items: _dayOptions
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.toString().padLeft(2, '0')),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _day = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 1,
                        child: _buildDropdown<int>(
                          hint: 'MM',
                          value: _month,
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(_monthAbbr[i]),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _month = v;
                              if (_day != null && _month != null) {
                                final year = _year ?? DateTime.now().year;
                                final maxDays = DateUtils.getDaysInMonth(year, _month!);
                                if (_day! > maxDays) _day = null;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 2,
                        child: _buildDropdown<int>(
                          hint: 'YYYY',
                          value: _year,
                          items: _yearOptions
                              .map((y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('$y'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _year = v;
                              if (_day != null && _month != null && _year != null) {
                                final maxDays = DateUtils.getDaysInMonth(_year!, _month!);
                                if (_day! > maxDays) _day = null;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.surfaceElevated,
                        disabledForegroundColor: AppTheme.textTertiary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Text(AppLocalizations.of(context).nextButton,
                          style: const TextStyle(fontSize: 18, color: AppTheme.textOnPrimary)),
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

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: AppTheme.surfaceElevated,
      style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppTheme.textTertiary, letterSpacing: 2,
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      menuMaxHeight: 300,
      iconEnabledColor: AppTheme.textSecondary,
    );
  }
}
