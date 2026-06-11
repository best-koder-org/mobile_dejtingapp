import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_config.dart';
import 'helpers/feedback_e2e.dart';

/// T061 — Feedback End-to-End.
///
/// UI-driven integration test. REQUIRES a connected device/emulator AND the
/// gateway + BotService running at [TestConfig.baseUrl].
///
/// For a headless-friendly E2E test (runs on desktop/CI without GL),
/// see `test/services/feedback_e2e_test.dart`.
void main() {
  group('T061 - Feedback E2E', () {
    test('Upload → PATCH → GET verify (device needs GL context)', () async {
      // Quick reachability check; skip if gateway is down.
      try {
        final ok = await runFeedbackE2E(TestConfig.baseUrl);
        if (!ok) return; // gateway unreachable — skip
      } catch (e) {
        // If runFeedbackE2E throws, the test failed.
        expect(true, isFalse, reason: 'E2E cycle failed: $e');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
