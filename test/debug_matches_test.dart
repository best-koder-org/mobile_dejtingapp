import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/enhanced_matches_screen.dart';
import 'helpers/core_screen_test_helper.dart';

void main() {
  testWidgets('debug matches screen state', (tester) async {
    await tester.pumpWidget(
      buildCoreScreenTestApp(home: const EnhancedMatchesScreen()),
    );
    
    // Try various pump strategies
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    
    // Check for CircularProgressIndicator (loading state)
    final loading = find.byType(CircularProgressIndicator);
    debugPrint('CircularProgressIndicator count: ${loading.evaluate().length}');
    
    // Check for empty state icon
    final emptyIcon = find.byIcon(Icons.favorite_border);
    debugPrint('favorite_border icon count: ${emptyIcon.evaluate().length}');
    
    // Print all text widgets
    final texts = find.byType(Text);
    for (final e in texts.evaluate()) {
      final t = e.widget as Text;
      debugPrint('TEXT: "${t.data}"');
    }
    
    // Now try runAsync
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    final loading2 = find.byType(CircularProgressIndicator);
    debugPrint('After runAsync - CircularProgressIndicator count: ${loading2.evaluate().length}');
    final emptyIcon2 = find.byIcon(Icons.favorite_border);
    debugPrint('After runAsync - favorite_border count: ${emptyIcon2.evaluate().length}');
    
    expect(true, isTrue); // Always pass
  });
}
