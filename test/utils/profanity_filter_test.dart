import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/utils/profanity_filter.dart';

void main() {
  group('ProfanityFilter', () {
    // ── Should BLOCK ─────────────────────────────────────
    group('blocks offensive names', () {
      final blocked = [
        // Exact words
        'Fuck', 'SHIT', 'bitch', 'cunt', 'Dick', 'Nazi',
        // Double/extra letters (the Fukkboy bug!)
        'Fukkboy', 'fuuuck', 'shiiit', 'biiiitch', 'assshole',
        // Leet-speak
        'sh1t', 'b1tch', 'f4ck',
        // Separators
        'f.u.c.k', 'f-u-c-k', 'f_u_c_k', 'f u c k',
        // Accented
        'shït', 'bîtch',
        // Mixed case + leet
        'SH1T', 'F4CK',
        // Swedish
        'fitta', 'knull', 'helvete',
        // Compound with blocked substring >= 4
        'Fuckboy', 'shithead', 'motherfucker',
      ];
      for (final name in blocked) {
        test('blocks "$name"', () {
          expect(ProfanityFilter.isOffensive(name), isTrue,
              reason: '"$name" should be blocked');
        });
      }
    });

    // ── Should ALLOW ─────────────────────────────────────
    group('allows clean names', () {
      final allowed = [
        'Alice', 'Bob', 'Charlie', 'Diana', 'Erik',
        'Kassandra',  // contains "ass" but only 3 chars
        'Ashley',     // contains "ash" - not blocked
        'Patrick',    // contains "trick" - not blocked
        'Sasha',      // contains "ash", "sha" - fine
        'Mats',       // Swedish name
        'Francois',   // French name
        'Anna',       // double letters (OK - "ana" after collapse)
      ];
      for (final name in allowed) {
        test('allows "$name"', () {
          expect(ProfanityFilter.isOffensive(name), isFalse,
              reason: '"$name" should be allowed');
        });
      }
    });
  });
}
