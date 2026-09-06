// lib/services/api_client.dart
import "dart:async";
import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;

/// Thrown when a request could not reach the server at all (DNS failure,
/// socket error, timeout). Callers use this to tell "the network is down"
/// apart from "the server answered with an error".
class NetworkUnavailableException implements Exception {
  final Object cause;
  NetworkUnavailableException(this.cause);

  @override
  String toString() => "Network unavailable";
}

/// The server accepted the request but is rate limiting us. Distinct from a
/// connection problem, so the UI can say "wait a moment" instead of blaming
/// the user's internet.
class RateLimitedException implements Exception {
  final int? retryAfterSeconds;
  RateLimitedException({this.retryAfterSeconds});

  @override
  String toString() => "Too many requests. Please wait a moment and try again.";
}

class ApiClient {
  final http.Client _client;

  /// Per-attempt timeout. Kept generous because Pakistani mobile networks are
  /// often slow rather than actually offline.
  final Duration timeout;

  /// Extra attempts after the first one. 2 => up to 3 tries total.
  final int maxRetries;

  ApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 2,
  }) : _client = client ?? http.Client();

  Map<String, String> _mergeHeaders(Map<String, String>? extra) {
    return <String, String>{
      "Accept": "application/json",
      if (extra != null) ...extra,
    };
  }

  String _safeBody(http.Response resp) {
    // ✅ Correct UTF-8 decoding (important for Urdu text)
    return utf8.decode(resp.bodyBytes);
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid JSON (expected object)");
    }
    return decoded;
  }

  Duration _backoff(int attempt) =>
      Duration(milliseconds: 500 * (1 << attempt)); // 500ms, 1s, 2s...

  /// Runs [send] with retries on transient failures.
  ///
  /// Only [idempotent] requests (GET/HEAD) are ever retried. A POST that times
  /// out may well have reached the server, so retrying it could place the same
  /// order twice. 429 is never retried either: the server is telling us to
  /// slow down, and retrying only burns more of the rate-limit allowance.
  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send, {
    required bool idempotent,
  }) async {
    final attempts = idempotent ? maxRetries : 0;
    Object? lastNetworkError;

    for (var attempt = 0; attempt <= attempts; attempt++) {
      try {
        final resp = await send().timeout(timeout);

        if (resp.statusCode >= 500 && attempt < attempts) {
          await Future<void>.delayed(_backoff(attempt));
          continue;
        }
        return resp;
      } on TimeoutException catch (e) {
        lastNetworkError = e;
      } on SocketException catch (e) {
        lastNetworkError = e;
      } on http.ClientException catch (e) {
        lastNetworkError = e;
      } on HandshakeException catch (e) {
        lastNetworkError = e;
      }

      if (attempt < attempts) {
        await Future<void>.delayed(_backoff(attempt));
      }
    }

    throw NetworkUnavailableException(lastNetworkError!);
  }

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final resp = await _sendWithRetry(
      () => _client.get(uri, headers: _mergeHeaders(headers)),
      idempotent: true,
    );

    if (resp.statusCode == 429) {
      throw RateLimitedException(
        retryAfterSeconds: int.tryParse(resp.headers["retry-after"] ?? ""),
      );
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("HTTP ${resp.statusCode}: ${_safeBody(resp)}");
    }
    return _decodeMap(_safeBody(resp));
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final resp = await _sendWithRetry(
      () => _client.post(
        uri,
        headers: _mergeHeaders({
          "Content-Type": "application/json; charset=utf-8",
          if (headers != null) ...headers,
        }),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
      idempotent: false,
    );

    if (resp.statusCode == 429) {
      throw RateLimitedException(
        retryAfterSeconds: int.tryParse(resp.headers["retry-after"] ?? ""),
      );
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("HTTP ${resp.statusCode}: ${_safeBody(resp)}");
    }
    return _decodeMap(_safeBody(resp));
  }

  Future<Map<String, dynamic>> putJson(
    Uri uri, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final resp = await _sendWithRetry(
      () => _client.put(
        uri,
        headers: _mergeHeaders({
          "Content-Type": "application/json; charset=utf-8",
          if (headers != null) ...headers,
        }),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
      idempotent: false,
    );

    if (resp.statusCode == 429) {
      throw RateLimitedException(
        retryAfterSeconds: int.tryParse(resp.headers["retry-after"] ?? ""),
      );
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("HTTP ${resp.statusCode}: ${_safeBody(resp)}");
    }
    return _decodeMap(_safeBody(resp));
  }

  void dispose() => _client.close();
}
