// lib/services/api_client.dart
import "dart:convert";
import "package:http/http.dart" as http;

class ApiClient {
  final http.Client _client;
  final Duration timeout;

  ApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
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

  Future<Map<String, dynamic>> getJson(
      Uri uri, {
        Map<String, String>? headers,
      }) async {
    final resp = await _client
        .get(uri, headers: _mergeHeaders(headers))
        .timeout(timeout);

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
    final resp = await _client
        .post(
      uri,
      headers: _mergeHeaders({
        "Content-Type": "application/json; charset=utf-8",
        if (headers != null) ...headers,
      }),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    )
        .timeout(timeout);

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
    final resp = await _client
        .put(
      uri,
      headers: _mergeHeaders({
        "Content-Type": "application/json; charset=utf-8",
        if (headers != null) ...headers,
      }),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    )
        .timeout(timeout);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("HTTP ${resp.statusCode}: ${_safeBody(resp)}");
    }
    return _decodeMap(_safeBody(resp));
  }

  void dispose() => _client.close();
}