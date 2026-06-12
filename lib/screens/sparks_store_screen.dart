import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:dejtingapp/services/billing_service.dart';

/// Sparks Store + Premium plans screen. Shows hardcoded fallback data immediately,
/// then refreshes from backend in background. Uses OutlinedButton throughout.
class SparksStoreScreen extends StatefulWidget {
  const SparksStoreScreen({super.key});

  @override
  State<SparksStoreScreen> createState() => _SparksStoreScreenState();
}

class _SparksStoreScreenState extends State<SparksStoreScreen> {
  List<PremiumPlan> _plans = [
    PremiumPlan('premium_month', 'Premium Month', 'Full access for 30 days', 30),
    PremiumPlan('premium_3months', 'Premium Quarter', 'Full access for 90 days', 90),
    PremiumPlan('premium_year', 'Premium Year', 'Full access for 365 days — best value', 365),
  ];
  List<SparksBundle> _bundles = [
    SparksBundle('sparks_100', 'Starter Pack', 100, 99),
    SparksBundle('sparks_500', 'Boost Pack', 500, 399),
    SparksBundle('sparks_1500', 'Super Pack', 1500, 999),
  ];
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await BillingService.getCatalog();
      if (!mounted) return;
      setState(() {
        _plans = catalog.plans;
        _bundles = catalog.bundles;
      });
    } catch (_) {}
  }

  Future<void> _purchase(String sku, String label) async {
    setState(() => _purchasing = true);
    try {
      final result = await BillingService.purchase(sku);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label purchased! ${result.message}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      // Navigate back after short delay so user sees the success
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = _plans;
    final bundles = _bundles;

    return Scaffold(
      appBar: AppBar(title: const Text('Sparks Store')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Premium Plans', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final p in plans)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p.description),
                trailing: SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: _purchasing ? null : () => _purchase(p.sku, p.name),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: _purchasing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(p.durationDays >= 365 ? 'Best value' : 'Subscribe', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ),
          const Divider(height: 32),
          Text('Sparks Bundles', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final b in bundles)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.bolt, color: AppTheme.tealAccent),
                title: Text('${b.sparks} Sparks', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(b.name),
                trailing: SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: _purchasing ? null : () => _purchase(b.sku, b.name),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: _purchasing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('\$${(b.priceUsdCents / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ),
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
                      final rootNavigator = Navigator.of(context, rootNavigator: true);
                      Navigator.pop(context);
                      rootNavigator.push(
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
