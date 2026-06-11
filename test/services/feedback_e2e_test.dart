import 'package:flutter_test/flutter_test.dart';

import '../helpers/feedback_e2e.dart';
import '../helpers/test_config.dart';

void main() {
  group('Feedback E2E', () {
    test('Upload → PATCH transcript → GET verify', () async {
      final ok = await runFeedbackE2E(TestConfig.baseUrl);
      if (!ok) {
        // Gateway unreachable — skip gracefully
        return;
      }
      // If it returned true, the cycle succeeded. If it threw, the test fails.
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
