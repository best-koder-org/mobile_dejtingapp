import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Runs a full upload → PATCH → GET verify cycle against a running gateway.
///
/// Returns `true` if the cycle completed successfully, `false` if the gateway
/// is unreachable (allows the caller to skip gracefully).
///
/// Callers MUST import this file directly (not via `flutter_test`) so it
/// can run with `dart test` on the VM without a Flutter engine.
Future<bool> runFeedbackE2E(String baseUrl) async {
  // Check reachability first — if gateway is down, skip gracefully.
  try {
    final check = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 3));
    if (check.statusCode < 200 || check.statusCode >= 400) return false;
  } catch (_) {
    return false;
  }

  final uploadUri = Uri.parse('$baseUrl/api/userfeedback');

  // 1. Create a tiny test audio file
  final tempFile = File(
      '${Directory.systemTemp.path}/test_memo_${DateTime.now().millisecondsSinceEpoch}.m4a');
  await tempFile.writeAsBytes(utf8.encode('fake-audio-bytes-for-e2e-test'));

  // 2. POST multipart upload
  final request = http.MultipartRequest('POST', uploadUri);
  request.fields['noteText'] = 'E2E test from dart runner';
  request.fields['durationSec'] = '1';
  request.fields['appVersion'] = 'e2e-test';
  request.files.add(await http.MultipartFile.fromPath(
    'audio',
    tempFile.path,
    filename: 'memo.m4a',
    contentType: MediaType('audio', 'aac'),
  ));
  final streamed = await request.send().timeout(const Duration(seconds: 10));
  final resp = await http.Response.fromStream(streamed);

  if (resp.statusCode != 200 && resp.statusCode != 201) {
    await tempFile.delete();
    throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
  }

  final body = resp.body.isNotEmpty
      ? json.decode(resp.body) as Map<String, dynamic>
      : <String, dynamic>{};
  final id = body['id'];
  if (id == null) {
    await tempFile.delete();
    throw Exception('Server did not return an id');
  }

  // 3. PATCH the transcript (simulating what the watcher does)
  final patchUri = Uri.parse('$baseUrl/api/userfeedback/$id');
  final patchResp = await http
      .patch(
        patchUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transcript': 'Hello from E2E test runner'}),
      )
      .timeout(const Duration(seconds: 10));

  if (patchResp.statusCode != 200) {
    await tempFile.delete();
    throw Exception('PATCH failed: ${patchResp.statusCode} ${patchResp.body}');
  }

  // 4. GET and verify transcript persisted
  final getResp = await http
      .get(Uri.parse('$baseUrl/api/userfeedback/$id'))
      .timeout(const Duration(seconds: 10));

  if (getResp.statusCode != 200) {
    await tempFile.delete();
    throw Exception('GET after PATCH failed: ${getResp.statusCode}');
  }

  final item = json.decode(getResp.body) as Map<String, dynamic>;
  if (item['transcript'] != 'Hello from E2E test runner') {
    await tempFile.delete();
    throw Exception(
        'Transcript mismatch: expected "Hello from E2E test runner", got "${item['transcript']}"');
  }

  // 5. Cleanup
  try {
    await tempFile.delete();
  } catch (_) {}

  return true;
}
