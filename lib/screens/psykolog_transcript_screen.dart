import 'package:flutter/material.dart';
import 'package:dejtingapp/services/psykolog_service.dart';

/// Read-only re-read of a past psykolog session transcript ("Din resa").
/// Fetches the owner-only messages from the backend and renders them as a
/// simple chat view (user bubbles right / assistant left, purple accent).
class PsykologTranscriptScreen extends StatefulWidget {
  final int sessionId;
  final String title;

  const PsykologTranscriptScreen({super.key, required this.sessionId, this.title = ''});

  @override
  State<PsykologTranscriptScreen> createState() => _PsykologTranscriptScreenState();
}

class _PsykologTranscriptScreenState extends State<PsykologTranscriptScreen> {
  static const _bg = Color(0xFFF5F0EB);
  static const _surface = Color(0xFFFFFFFF);
  static const _accent = Color(0xFF6B4EFF);
  static const _textPrimary = Color(0xFF2D2D2D);
  static const _textSecondary = Color(0xFF8B8578);

  final _svc = PsykologService.instance;
  List<PsykologMessageInfo>? _messages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final msgs = await _svc.getMessages(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _messages = msgs ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title.isEmpty ? 'Samtal' : widget.title,
          style: const TextStyle(
              color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _messages!.isEmpty
              ? const Center(
                  child: Text(
                    'Inga meddelanden i den här sessionen.',
                    style: TextStyle(color: _textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages!.length,
                  itemBuilder: (context, i) {
                    final m = _messages![i];
                    final isUser = m.role.toLowerCase() == 'user';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isUser ? _accent : _surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : _textPrimary,
                            height: 1.4,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
