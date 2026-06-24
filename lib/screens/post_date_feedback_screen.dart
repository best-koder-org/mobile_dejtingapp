import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../backend_url.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PostDateFeedbackScreen extends StatefulWidget {
  final String matchId;
  final String? matchedPersonName;

  /// Injected HTTP client — used in tests to avoid real network calls.
  @visibleForTesting
  final http.Client? httpClient;

  /// Injected token provider — used in tests to skip FlutterSecureStorage.
  @visibleForTesting
  final Future<String?> Function()? tokenProvider;

  const PostDateFeedbackScreen({
    super.key,
    required this.matchId,
    this.matchedPersonName,
    this.httpClient,
    this.tokenProvider,
  });

  @override
  State<PostDateFeedbackScreen> createState() => _PostDateFeedbackScreenState();
}

// ignore_for_file: use_build_context_synchronously
class _PostDateFeedbackScreenState extends State<PostDateFeedbackScreen> {
  int _overallRating = 0;
  int _chemistryRating = 0;
  int _conversationRating = 0;
  bool _wouldMeetAgain = false;
  final TextEditingController _freeformController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  http.Client get _client => widget.httpClient ?? http.Client();

  @override
  void dispose() {
    _freeformController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _overallRating > 0 && _chemistryRating > 0 && _conversationRating > 0;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = widget.tokenProvider != null
          ? await widget.tokenProvider!()
          : await AppState().getOrRefreshAuthToken();
      final url = Uri.parse(
          '${ApiUrls.matchmakingService}/api/matchmaking/matches/${widget.matchId}/feedback');

      final body = jsonEncode({
        'overallRating': _overallRating,
        'chemistryRating': _chemistryRating,
        'conversationRating': _conversationRating,
        'wouldMeetAgain': _wouldMeetAgain,
        if (_freeformController.text.trim().isNotEmpty)
          'freeformReflection': _freeformController.text.trim(),
      });

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true); // true = submitted
      } else if (response.statusCode == 409) {
        setState(() => _errorMessage = 'Du har redan lämnat feedback för den här träffen.');
      } else {
        setState(() => _errorMessage = 'Något gick fel. Försök igen.');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Nätverksfel. Kontrollera din anslutning.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final personName = widget.matchedPersonName ?? 'er match';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hur gick det?'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      backgroundColor: AppTheme.scaffoldDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Din träff med $personName',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Din feedback hjälper oss att förbättra dina matchningar.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // ── Overall rating ──────────────────────────────────────────
              _RatingRow(
                label: 'Helhetsbetyg',
                value: _overallRating,
                onChanged: (v) => setState(() => _overallRating = v),
              ),
              const SizedBox(height: 20),

              // ── Chemistry ───────────────────────────────────────────────
              _RatingRow(
                label: 'Kemi',
                value: _chemistryRating,
                onChanged: (v) => setState(() => _chemistryRating = v),
              ),
              const SizedBox(height: 20),

              // ── Conversation ─────────────────────────────────────────────
              _RatingRow(
                label: 'Samtal',
                value: _conversationRating,
                onChanged: (v) => setState(() => _conversationRating = v),
              ),
              const SizedBox(height: 28),

              // ── Would meet again ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Träffas igen?',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.textPrimary),
                  ),
                  Switch(
                    value: _wouldMeetAgain,
                    onChanged: (v) => setState(() => _wouldMeetAgain = v),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Freeform reflection ──────────────────────────────────────
              Text(
                'Tankar (valfritt)',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _freeformController,
                maxLength: 500,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Vad tänker du på?',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('submit_feedback_btn'),
                  onPressed: (_canSubmit && !_loading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Skicka feedback',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Star-rating row widget ────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppTheme.textPrimary),
        ),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => onChanged(star),
              child: Icon(
                star <= value ? Icons.star : Icons.star_border,
                color: star <= value ? AppTheme.primaryColor : Colors.grey,
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }
}
