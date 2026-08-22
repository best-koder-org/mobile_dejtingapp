import 'package:flutter/material.dart';
import 'package:dejtingapp/services/psykolog_service.dart';
import 'package:dejtingapp/services/feedback_trends_service.dart';
import 'package:dejtingapp/widgets/theme_visualization_widget.dart';
import 'psykolog_chat_screen.dart';
import 'psykolog_transcript_screen.dart';

/// Entry point for AI Psykolog — "Reflektionsrummet".
///
/// Three tabs:
///   Dina teman — extracted themes with confidence indicator
///   Din resa   — session timeline with key insights
///   Sessioner  — past session history
class PsykologHomeScreen extends StatefulWidget {
  const PsykologHomeScreen({super.key});

  @override
  State<PsykologHomeScreen> createState() => _PsykologHomeScreenState();
}

class _PsykologHomeScreenState extends State<PsykologHomeScreen>
    with SingleTickerProviderStateMixin {
  final _svc = PsykologService.instance;
  final _feedbackSvc = FeedbackTrendsService.instance;
  List<PsykologSessionInfo> _sessions = [];
  List<PsykologTheme> _themes = [];
  FeedbackTrends? _feedbackTrends;
  bool _loading = true;
  bool _starting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _svc.getSessions(),
      _svc.getThemes(),
      _feedbackSvc.getTrends(),
    ]);
    if (!mounted) return;
    setState(() {
      _sessions = results[0] as List<PsykologSessionInfo>;
      _themes = results[1] as List<PsykologTheme>;
      _feedbackTrends = results[2] as FeedbackTrends?;
      _loading = false;
    });
  }

  Future<void> _startSession() async {
    setState(() => _starting = true);
    final session = await _svc.startSession();
    if (!mounted) return;
    setState(() => _starting = false);

    if (session == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du har nått din månadskvot.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PsykologChatScreen(session: session!)),
    );
    _load();
  }

  String _journeySummary() {
    if (_sessions.isEmpty) return '';
    final completed = _sessions.where((s) => s.status == PsykologSessionStatus.completed).length;
    final themesCount = _themes.length;
    final h = StringBuffer();

    if (completed == 0) {
      h.writeln('Din reflektionsresa har precis börjat. Varje session hjälper dig att förstå dina relationsmönster bättre.');
    } else if (completed <= 2) {
      h.writeln('Du har genomfört $completed session(er). Dina första insikter om ❤️ anknytning och 💡 värderingar börjar ta form.');
    } else if (completed <= 5) {
      h.writeln('$completed sessioner — ett stadigt utforskande. Du har identifierat $themesCount teman i dina relationsmönster.');
    } else {
      h.writeln('$completed sessioner genomförda. Din självinsikt växer stadigt.');
    }

    // Add a gentle nudge if there are gaps
    final lastSession = _sessions
        .where((s) => s.status != PsykologSessionStatus.active)
        .map((s) => s.endedAt ?? s.startedAt)
        .fold<DateTime?>(null, (prev, d) => prev == null || d.isAfter(prev) ? d : prev);

    if (lastSession != null) {
      final daysSince = DateTime.now().difference(lastSession).inDays;
      if (daysSince > 14) {
        h.writeln();
        h.writeln('Det var $daysSince dagar sedan din senaste session. En bra tid att checka in med dig själv? 🌱');
      } else if (daysSince > 7) {
        h.writeln();
        h.writeln('$daysSince dagar sedan senaste sessionen. Är du redo för en ny reflektion?');
      }
    }

    return h.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Warm therapy palette
    const bg = Color(0xFFF5F0EB); // warm cream
    const surface = Color(0xFFFFFFFF);
    const accent = Color(0xFF6B4EFF);  // soft purple
    const textPrimary = Color(0xFF2D2D2D);
    const textSecondary = Color(0xFF8B8578);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(color: accent)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, color: accent, size: 22),
            SizedBox(width: 8),
            Text('Reflektionsrummet',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accent,
          unselectedLabelColor: textSecondary,
          indicatorColor: accent,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Dina teman'),
            Tab(text: 'Din resa'),
            Tab(text: 'Sessioner'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Session starter card (always visible)
          _buildSessionStarter(accent, surface, textPrimary, textSecondary),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemanTab(surface, accent, textPrimary, textSecondary),
                _buildResaTab(surface, accent, textPrimary, textSecondary),
                _buildSessionerTab(accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStarter(Color accent, Color surface, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF9B7EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reflektionsassistent',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  _sessions.isEmpty
                      ? 'En trygg plats att utforska dina relationsmönster.'
                      : _sessions.any((s) => s.status == PsykologSessionStatus.active)
                          ? 'Du har en pågående session.'
                          : 'Redo för en ny reflektion? 🌱',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _starting ? null : _startSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _starting
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                : const Text('Starta session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Dina teman ──────────────────────────────────────────────

  Widget _buildTemanTab(Color surface, Color accent, Color textPrimary, Color textSecondary) {
    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Match quality card
          if (_feedbackTrends != null && _feedbackTrends!.totalFeedbacks > 0)
            _buildMatchQualityCard(surface, textPrimary, textSecondary),
          const SizedBox(height: 16),
          // Theme tag cloud
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ThemeVisualizationWidget(
              themes: _themes,
              sessionCount: _sessions.where((s) => s.status == PsykologSessionStatus.completed).length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchQualityCard(Color surface, Color textPrimary, Color textSecondary) {
    final t = _feedbackTrends!;
    final isImproving = t.improvementPercent > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6B8F71).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B8F71).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isImproving ? Icons.trending_up : Icons.trending_flat,
                color: const Color(0xFF6B8F71), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Matchkvalitet: ${t.improvementPercent >= 0 ? "+" : ""}${t.improvementPercent.toStringAsFixed(0)}%',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Baserat på ${t.totalFeedbacks} omdömen',
                    style: TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Din resa ────────────────────────────────────────────────

  Widget _buildResaTab(Color surface, Color accent, Color textPrimary, Color textSecondary) {
    final summary = _journeySummary();
    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Journey summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.map_outlined, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Din resa', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                const SizedBox(height: 12),
                if (summary.isNotEmpty)
                  Text(summary,
                      style: TextStyle(color: textSecondary, height: 1.6, fontSize: 14)),
                if (summary.isEmpty)
                  Text('Starta din första session för att påbörja din reflektionsresa.',
                      style: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 14)),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(icon: Icons.chat_bubble_outline, value: '${_sessions.length}', label: 'Sessioner'),
                    _StatItem(icon: Icons.lightbulb_outline, value: '${_themes.length}', label: 'Insikter'),
                    _StatItem(icon: Icons.auto_awesome, value: '${_sessions.where((s) => s.status == PsykologSessionStatus.completed).length}', label: 'Genomförda'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Sessioner ───────────────────────────────────────────────

  Widget _buildSessionerTab(Color accent) {
    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _sessions.length,
        itemBuilder: (context, i) {
          final s = _sessions[i];
          final isActive = s.status == PsykologSessionStatus.active;
          return Card(
            color: isActive ? accent.withValues(alpha: 0.06) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Text('#${s.sessionNumber}',
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              title: Text('Session ${s.sessionNumber}',
                  style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 14)),
              subtitle: Text(
                '${_formatDate(s.startedAt)} · ${s.themeCount} teman',
                style: const TextStyle(color: Color(0xFF8B8578), fontSize: 12),
              ),
              trailing: isActive
                  ? const Chip(label: Text('Pågår', style: TextStyle(fontSize: 10)),
                      backgroundColor: Color(0xFFEDE4FF))
                  : null,
              onTap: isActive
                  ? () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PsykologChatScreen(session: s)));
                    }
                  : () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PsykologTranscriptScreen(
                                  sessionId: s.id, title: 'Session ${s.sessionNumber}')));
                    },
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6B4EFF), size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Color(0xFF8B8578), fontSize: 11)),
      ],
    );
  }
}
