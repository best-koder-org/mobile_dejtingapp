import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/billing_service.dart';

/// Sparks Store + Premium plans screen. Shows real backend catalog and allows
/// sandbox purchase via BillingService.
class SparksStoreScreen extends StatefulWidget {
  const SparksStoreScreen({super.key});

  @override
  State<SparksStoreScreen> createState() => _SparksStoreScreenState();
}

class _SparksStoreScreenState extends State<SparksStoreScreen> {
  List<PremiumPlan> _plans = [];
  List<SparksBundle> _bundles = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() { _loading = true; _error = null; });
    try {
      final catalog = await BillingService.getCatalog();
      if (!mounted) return;
      setState(() {
        _plans = catalog.plans;
        _bundles = catalog.bundles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _purchase(String sku, String label) async {
    setState(() => _purchasing = true);
    try {
      final result = await BillingService.purchase(sku);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label purchased! ${result.message}')),
      );
      setState(() => _purchasing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
      setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sparks Store')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error'),
                      TextButton(onPressed: _loadCatalog, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Premium Plans ──
                    Text('Premium Plans',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ..._plans.map((p) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(p.description),
                            trailing: _purchasing
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : ElevatedButton(
                                    onPressed: () => _purchase(p.sku, p.name),
                                    child: Text(
                                      p.durationDays >= 365 ? 'Best value' : 'Subscribe',
                                    ),
                                  ),
                          ),
                        )),

                    const Divider(height: 32),

                    // ── Sparks Bundles ──
                    Text('Sparks Bundles',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ..._bundles.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.bolt, color: AppTheme.tealAccent),
                            title: Text('${b.sparks} Sparks',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(b.name),
                            trailing: _purchasing
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : ElevatedButton(
                                    onPressed: () => _purchase(b.sku, b.name),
                                    child: Text('\$${(b.priceUsdCents / 100).toStringAsFixed(2)}'),
                                  ),
                          ),
                        )),
                  ],
                ),
    );
  }
}

/// Paywall bottom sheet shown when a premium-only action is attempted.
class PaywallSheet extends StatelessWidget {
  final String featureName;
  const PaywallSheet({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.stars, size: 64, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Upgrade to Premium',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$featureName is a premium feature.\nUpgrade to unlock unlimited access.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SparksStoreScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('See plans'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Maybe later'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
