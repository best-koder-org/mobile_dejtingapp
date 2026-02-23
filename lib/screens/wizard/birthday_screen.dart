import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});
  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  int? _month;
  int? _day;
  int? _year;

  // Month names for better UX
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Years from 18 years ago back to 90 years ago (descending)
  List<int> get _yearOptions {
    final now = DateTime.now();
    final maxYear = now.year - 18;  // Must be at least 18
    final minYear = now.year - 90;  // No one over ~90 on a dating app
    return List.generate(maxYear - minYear + 1, (i) => maxYear - i);
  }

  /// Days available for the selected month/year (handles leap years)
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
            onPressed: () =>
                OnboardingProvider.of(context).abort(context),
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
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFFF6B6B)),
                  minHeight: 4,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).yourBirthday,
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).birthdayExplainer,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 32),

                      // Month dropdown
                      _buildDropdown<int>(
                        label: AppLocalizations.of(context).monthLabel,
                        value: _month,
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_monthNames[i]),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _month = v;
                            // Reset day if it's now invalid
                            if (_day != null && _month != null) {
                              final year = _year ?? DateTime.now().year;
                              final maxDays =
                                  DateUtils.getDaysInMonth(year, _month!);
                              if (_day! > maxDays) _day = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Day and Year in a row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<int>(
                              label: AppLocalizations.of(context).dayLabel,
                              value: _day,
                              items: _dayOptions
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text('$d'),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _day = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown<int>(
                              label: AppLocalizations.of(context).yearLabel,
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
                                  // Reset day if leap year changes validity
                                  if (_day != null && _month != null && _year != null) {
                                    final maxDays = DateUtils.getDaysInMonth(
                                        _year!, _month!);
                                    if (_day! > maxDays) _day = null;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      if (_isValid) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context).youAreNYearsOld(_calcAge(DateTime(_year!, _month!, _day!))),
                                style: const TextStyle(fontSize: 14, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isValid ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isValid
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27)),
                          ),
                          child: Text(AppLocalizations.of(context).nextButton,
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      menuMaxHeight: 300,
    );
  }
}
