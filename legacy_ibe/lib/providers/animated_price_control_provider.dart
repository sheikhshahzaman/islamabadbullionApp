import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

import "../config.dart";

class AnimatedPriceControlProvider extends ChangeNotifier {
  AnimatedPriceControlProvider._();

  static final AnimatedPriceControlProvider instance =
  AnimatedPriceControlProvider._();

  static const Duration _refreshInterval = Duration(seconds: 30);
  static const Duration _timeout = Duration(seconds: 8);

  bool _enabled = true; // safe default
  bool _started = false;
  bool _fetching = false;
  Timer? _timer;

  bool get enabled => _enabled;

  void ensureStarted() {
    if (_started) return;
    _started = true;

    unawaited(refreshNow());

    _timer = Timer.periodic(_refreshInterval, (_) {
      unawaited(refreshNow());
    });
  }

  Future<void> refreshNow() async {
    if (_fetching) return;
    _fetching = true;

    try {
      // The Laravel backend exposes the admin's live-rates kill-switch on
      // /api/prices; the app honors it the same way the website does.
      final uri = Uri.parse("${AppConfig.apiBase}/prices");

      final response = await http.get(
        uri,
        headers: const {
          "Accept": "application/json",
        },
      ).timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return;

      final nextEnabled = decoded["live_rates_enabled"] != false;

      if (nextEnabled != _enabled) {
        _enabled = nextEnabled;
        notifyListeners();
      }
    } catch (_) {
      // keep last known state silently
    } finally {
      _fetching = false;
    }
  }
}