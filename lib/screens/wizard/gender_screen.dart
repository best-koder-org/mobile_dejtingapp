import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';

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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).selectGenderSheet,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: _allOptions.map((g) => RadioListTile<String>(
                    title: Text(g, style: const TextStyle(fontSize: 16, color: Colors.black)),
                    value: g,
                    groupValue: _selected,
                    activeColor: const Color(0xFFFF6B6B),
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
                  Text(
                    AppLocalizations.of(context).whatsYourGender,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                            color: _selected == g ? const Color(0xFFFF6B6B) : Colors.grey,
                            width: 2,
                          ),
                          backgroundColor: _selected == g
                              ? const Color(0xFFFF6B6B).withAlpha(25)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 18,
                            color: _selected == g ? const Color(0xFFFF6B6B) : Colors.black,
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
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey,
                            width: 2,
                          ),
                          backgroundColor: (_selected != null && !_quickOptions.contains(_selected))
                              ? const Color(0xFFFF6B6B).withAlpha(25)
                              : Colors.white,
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
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnProfile,
                        activeColor: const Color(0xFFFF6B6B),
                        onChanged: (v) => setState(() => _showOnProfile = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).showGenderOnProfile,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                    ],
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
                        backgroundColor: _selected != null
                            ? const Color(0xFFFF6B6B)
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
