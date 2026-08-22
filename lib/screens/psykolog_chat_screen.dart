import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dejtingapp/services/psykolog_service.dart';

/// AI Psykolog chat — therapy-inspired "Reflektionsrummet" session.
///
/// Features:
///   - Session timer with gentle nudges at 5 min remaining
///   - Structured welcome message opening the session
///   - Pre-end reflection prompt before closing
///   - Warm cream-and-purple palette
class PsykologChatScreen extends StatefulWidget {
  final PsykologSessionInfo session;
  const PsykologChatScreen({super.key, required this.session});

  @override
  State<PsykologChatScreen> createState() => _PsykologChatScreenState();
}

class _PsykologChatScreenState extends State<PsykologChatScreen> {
  static const _accent = Color(0xFF6B4EFF);
  static const _bg = Color(0xFFF5F0EB);
  static const _textPrimary = Color(0xFF2D2D2D);
  static const _textSecondary = Color(0xFF8B8578);

  final _svc = PsykologService.instance;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMsg> _messages = [];
  bool _sending = false;
  bool _ending = false;

  // Session timer
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _nudgeShown = false;
  static const _nudgeAt = Duration(minutes: 25); // warn at 25 min

  @override
  void initState() {
    super.initState();
    _startTimer();
    _messages.add(const _ChatMsg(
      role: _Role.assistant,
      text: '👋 Välkommen till Reflektionsrummet.\n\n'
          'Det här är en trygg plats där vi kan utforska dina tankar om relationer, '
          'känslor och mönster. Jag lyssnar förutsättningslöst — inget är för stort '
          'eller för litet.\n\n'
          'Vi har cirka 30 minuter. Hur känns det för dig idag?',
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.session.startedAt);
      });
      if (_elapsed >= _nudgeAt && !_nudgeShown) {
        _nudgeShown = true;
        _messages.add(const _ChatMsg(
          role: _Role.assistant,
          text: '⏰ Vi har ungefär 5 minuter kvar. Finns det något du vill hinna '
              'reflektera över innan vi rundar av?',
        ));
        _scrollToBottom();
      }
    });
  }

  String _timerText() {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_ChatMsg(role: _Role.user, text: text));
      _sending = true;
    });
    _scrollToBottom();

    final reply = await _svc.sendMessage(widget.session.id, text);
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (reply != null) {
        _messages.add(_ChatMsg(role: _Role.assistant, text: reply));
      } else {
        _messages.add(const _ChatMsg(
          role: _Role.assistant,
          text: 'Förlåt, jag har problem just nu. Försök igen.',
          isError: true,
        ));
      }
    });
    _scrollToBottom();
  }

  Future<void> _endSession() async {
    // Pre-end reflection prompt
    final reflection = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.psychology_outlined, color: _accent, size: 24),
            SizedBox(width: 8),
            Text('Avsluta session', style: TextStyle(color: _textPrimary, fontSize: 18)),
          ],
        ),
        content: const Text(
          '🌱 Vad tar du med dig från dagens reflektion?\n\n'
          'Dina meddelanden sparas så du kan gå tillbaka och läsa dina reflektioner. '
          'Teman analyseras anonymt för att uppdatera ditt kompatibilitetsmönster.',
          style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Fortsätt reflektera',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Avsluta session'),
          ),
        ],
      ),
    );

    if (reflection != true || !mounted) return;

    setState(() => _ending = true);
    final ended = await _svc.endSession(widget.session.id);
    if (!mounted) return;
    setState(() => _ending = false);

    if (ended != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunde inte avsluta sessionen.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reflektionsrummet',
                style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Session ${widget.session.sessionNumber} · ${_timerText()}',
                style: const TextStyle(color: _textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _ending ? null : _endSession,
            icon: _ending
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                : const Icon(Icons.logout, size: 16, color: _accent),
            label: const Text('Avsluta',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageBubble(
                msg: _messages[i],
                isLast: i == _messages.length - 1 && _messages[i].role == _Role.assistant,
              ),
            ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [_TypingDots()]),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Dela dina tankar...',
                  hintStyle: const TextStyle(color: _textSecondary),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message types ─────────────────────────────────────────────────────────

enum _Role { user, assistant }

class _ChatMsg {
  final _Role role;
  final String text;
  final bool isError;
  const _ChatMsg({required this.role, required this.text, this.isError = false});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  final bool isLast;
  const _MessageBubble({required this.msg, this.isLast = false});

  static const _accent = Color(0xFF6B4EFF);

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == _Role.user;
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? _accent : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: isUser ? Colors.white : const Color(0xFF2D2D2D),
              fontSize: 14,
              height: 1.5,
              fontStyle: msg.isError ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Typing indicator ───────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final _ = (1.0 - _ctrl.value).abs();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final alpha = ((_ctrl.value + delay) % 1.0) * 0.5 + 0.3;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF).withValues(alpha: alpha),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
