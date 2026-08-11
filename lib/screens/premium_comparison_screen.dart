import 'package:flutter/material.dart';
import 'package:dejtingapp/services/billing_service.dart';

/// Tinder/Hinge-style premium comparison table.
/// Shows what features are available at each tier.
class PremiumComparisonScreen extends StatefulWidget {
  const PremiumComparisonScreen({super.key});

  @override
  State<PremiumComparisonScreen> createState() => _PremiumComparisonScreenState();
}

class _PremiumComparisonScreenState extends State<PremiumComparisonScreen> {
  List<PremiumPlan> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await BillingService.getCatalog();
      if (mounted) setState(() { _plans = catalog.plans; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Premium', style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF8B8578)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Hero section ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade700, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.diamond, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text('Uppgradera till Premium',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Få tillgång till exklusiva funktioner',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Plan cards ──
                ..._plans.map((p) => _PlanCard(plan: p, onSelect: () => _purchase(p.sku, p.name))),

                const SizedBox(height: 24),

                // ── Feature comparison ──
                const Text('Se vad du får', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _FeatureRow('Läskvitton', false, true),
                _FeatureRow('Dold surfning', false, true),
                _FeatureRow('Obegränsade gillningar', false, true),
                _FeatureRow('Inga annonser', false, true),
                _FeatureRow('Se vem som gillar dig', false, true),
                _FeatureRow('5 gillningar/dag', true, false),
                _FeatureRow('Grundläggande filter', true, false),
                _FeatureRow('Premium-märke på profil', false, true),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _purchase(String sku, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Premium $name — sandbox-läge')),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final VoidCallback onSelect;
  const _PlanCard({required this.plan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isBestValue = plan.durationDays >= 365;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBestValue ? BorderSide(color: Colors.amber.shade700, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBestValue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('BÄSTA VÄRDET',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(plan.description, style: const TextStyle(color: Color(0xFF8B8578), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${plan.priceSparks} ⚡', style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(isBestValue ? 'Välj' : plan.durationDays >= 90 ? 'Välj' : 'Välj'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final bool free;
  final bool premium;

  const _FeatureRow(this.label, this.free, this.premium);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(free ? Icons.check_circle : Icons.cancel,
                    size: 20, color: free ? Colors.green : Colors.grey.shade300),
                const SizedBox(width: 16),
                Icon(premium ? Icons.check_circle : Icons.cancel,
                    size: 20, color: premium ? Colors.amber : Colors.grey.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
