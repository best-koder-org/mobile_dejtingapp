import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dejtingapp/backend_url.dart';
import 'package:dejtingapp/services/api_service.dart';
import 'package:dejtingapp/services/billing_service.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// Schedule a Spotlight boost — pay sparks to get 30min of boosted visibility.
class SpotlightScheduleScreen extends StatefulWidget {
  const SpotlightScheduleScreen({super.key});

  @override
  State<SpotlightScheduleScreen> createState() => _SpotlightScheduleScreenState();
}

class _SpotlightScheduleScreenState extends State<SpotlightScheduleScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 1;
  int _sparksBalance = 0;
  bool _scheduling = false;
  bool _success = false;

  final _durations = [
    (1, '1 timme', 50),
    (3, '3 timmar', 120),
    (6, '6 timmar', 200),
    (12, '12 timmar', 350),
    (24, '24 timmar', 500),
  ];

  int get _cost => _durations.firstWhere((d) => d.$1 == _durationHours).$3;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final status = await BillingService.getStatus();
      if (mounted) setState(() => _sparksBalance = status.sparksBalance);
    } catch (_) {}
  }

  Future<void> _schedule() async {
    setState(() => _scheduling = true);
    try {
      final token = await AppState().getOrRefreshAuthToken();
      final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
          _selectedTime.hour, _selectedTime.minute);
      final resp = await http.post(
        Uri.parse('${ApiUrls.userService}/api/billing/sparks/spend'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': 'spotlight',
          'amount': _cost,
          'scheduledAt': dt.toIso8601String(),
          'durationHours': _durationHours,
        }),
      );
      if (mounted) {
        setState(() {
          _scheduling = false;
          _success = resp.statusCode == 200;
        });
        if (_success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔦 Spotlight aktiverad! 30 minuters boostad synlighet.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Misslyckades: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _scheduling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Spotlight', style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Boostad synlighet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Din profil visas för fler användare under vald period.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date picker
          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              title: const Text('Startdatum', style: TextStyle(fontSize: 14)),
              subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Time picker
          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
              title: const Text('Starttid', style: TextStyle(fontSize: 14)),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _selectedTime);
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Duration selector
          const Text('Varaktighet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._durations.map((d) => RadioListTile<int>(
                value: d.$1,
                groupValue: _durationHours,
                title: Text(d.$2, style: const TextStyle(fontSize: 14)),
                subtitle: Text('${d.$3} ⚡', style: TextStyle(color: Colors.amber.shade700, fontSize: 12)),
                activeColor: AppTheme.primaryColor,
                onChanged: (v) { if (v != null) setState(() => _durationHours = v); },
              )),

          const SizedBox(height: 20),

          // Balance & schedule
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo: $_sparksBalance ⚡', style: const TextStyle(fontSize: 14)),
                        Text('Kostnad: $_cost ⚡', style: TextStyle(color: _sparksBalance >= _cost ? Colors.green : Colors.red, fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _sparksBalance >= _cost && !_scheduling && !_success ? _schedule : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _scheduling
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Aktivera'),
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
