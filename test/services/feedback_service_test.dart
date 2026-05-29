import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:dejtingapp/services/feedback_service.dart';

class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;
  _FakeClient(this._handler);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _handler(request);
}

void main() {
  test('submit with note only sends multipart and returns decoded JSON', () async {
    final fake = _FakeClient((req) async {
      // Expect a multipart POST
      expect(req.method, equals('POST'));
      if (req is http.MultipartRequest) {
        expect(req.fields['noteText'], equals('hi note'));
        final body = utf8.encode(json.encode({'id': 99}));
        return http.StreamedResponse(Stream.value(body), 201);
      }
      return http.StreamedResponse(Stream.value(utf8.encode('')), 500);
    });

    final service = FeedbackService(httpClient: fake, tokenProvider: () async => null);
    final resp = await service.submit(noteText: 'hi note');
    expect(resp['id'], equals(99));
  });

  test('fetchById returns map for existing id', () async {
    final fake = _FakeClient((req) async {
      // Expect a GET request for /api/userfeedback/123
      expect(req.method, equals('GET'));
      if (req.url.path.endsWith('/api/userfeedback/123')) {
        final body = utf8.encode(json.encode({'id': 123, 'transcript': 'ok'}));
        return http.StreamedResponse(Stream.value(body), 200);
      }
      return http.StreamedResponse(Stream.value(utf8.encode('')), 404);
    });

    final service = FeedbackService(httpClient: fake, tokenProvider: () async => null);
    final item = await service.fetchById(123);
    expect(item, isNotNull);
    expect(item!['id'], equals(123));
    expect(item['transcript'], equals('ok'));
  });
}
