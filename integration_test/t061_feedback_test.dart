import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'helpers/test_config.dart';

void main() {
  group('T061 - Feedback E2E', () {
    test('Upload audio and patch transcript', () async {
      final base = TestConfig.baseUrl;
      final uploadUri = Uri.parse('$base/api/userfeedback');

      // Create a tiny test audio file (fake bytes — server accepts by extension)
      final tempFile = File('${Directory.systemTemp.path}/test_memo_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await tempFile.writeAsBytes(utf8.encode('fake-audio-bytes'));

      // POST multipart upload
      final request = http.MultipartRequest('POST', uploadUri);
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        tempFile.path,
        filename: 'memo.m4a',
        contentType: MediaType('audio', 'aac'),
      ));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      expect(resp.statusCode, anyOf([200, 201]));

      final Map<String, dynamic> body = resp.body.isNotEmpty ? json.decode(resp.body) as Map<String, dynamic> : {};
      final id = body['id'];
      expect(id, isNotNull, reason: 'Server should return created id');

      // Simulate transcription step by PATCHing the transcript (tester-friendly)
      final patchUri = Uri.parse('$base/api/userfeedback/$id');
      final patchResp = await http.patch(
        patchUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transcript': 'Hello from integration test'}),
      );
      expect(patchResp.statusCode, 200);

      // Fetch the item and verify transcript is present
      final getResp = await http.get(Uri.parse('$base/api/userfeedback/$id'));
      expect(getResp.statusCode, 200);
      final item = json.decode(getResp.body) as Map<String, dynamic>;
      expect(item['transcript'], equals('Hello from integration test'));

      // Cleanup
      try {
        await tempFile.delete();
      } catch (_) {}
    }, timeout: Timeout(Duration(minutes: 2)));
  });
}
