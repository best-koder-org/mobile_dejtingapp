import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cronet_http/cronet_http.dart';

/// A delegating client that ignores [close] so a shared underlying client can
/// be reused across multiple top-level `http.get/post` calls.
///
/// `http.runWithClient` causes those top-level helpers to call `_withClient`,
/// which closes the client in a `finally` block. If we returned the raw
/// shared client directly, the first top-level call would dispose it. This
/// wrapper makes `close()` a no-op so the shared client lives for the app's
/// lifetime.
class _NonClosingClient extends http.BaseClient {
  _NonClosingClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {/* intentionally ignored — see class doc */}
}

/// The real underlying client we want to share. Built once.
http.Client? _underlying;

/// Returns a non-closing wrapper around a shared [http.Client] that trusts the
/// platform's system certificate store.
///
/// On Android, `dart:io`'s built-in HTTP client uses a static CA bundle baked
/// into the Dart SDK, which can lag behind newer Let's Encrypt intermediates
/// (e.g. `E8` → ISRG Root X2). That causes `HandshakeException` against
/// otherwise-valid servers like our Tailscale Funnel host. Cronet uses
/// Android's system trust store, which is kept up to date, so it succeeds.
///
/// On all other platforms (web, iOS, desktop) we fall back to the default
/// `http.Client()`.
http.Client createPlatformHttpClient() {
  _underlying ??= _buildUnderlying();
  return _NonClosingClient(_underlying!);
}

http.Client _buildUnderlying() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      // Disable QUIC/HTTP3: Tailscale Funnel speaks HTTP/2 only and Cronet's
      // aggressive HTTP/3 negotiation has been observed to cause
      // `net::ERR_CONNECTION_CLOSED` mid-multipart-upload.
      final engine = CronetEngine.build(
        cacheMode: CacheMode.memory,
        cacheMaxSize: 2 * 1024 * 1024,
        userAgent: 'dejtingapp-cronet/1.0',
        enableHttp2: true,
        enableQuic: false,
      );
      final client = CronetClient.fromCronetEngine(engine, closeEngine: true);
      debugPrint('[HttpClientFactory] using Cronet (system trust store)');
      return client;
    } catch (e) {
      debugPrint('[HttpClientFactory] Cronet init failed: $e — '
          'falling back to http.Client()');
    }
  }
  return http.Client();
}
