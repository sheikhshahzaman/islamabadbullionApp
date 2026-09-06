import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../config.dart";
import "../models/metal_prices_response.dart";
import "../services/api_client.dart";
import "../services/connectivity_service.dart";
import "../services/prices_api.dart";
import "app_settings.dart";

class PricesProvider extends ChangeNotifier {
  AppSettings? _settings;

  final ApiClient _client = ApiClient();
  late final PricesApi _api = PricesApi(_client);

  Timer? _timer;
  bool _fetching = false;

  MetalPricesResponse? _latest;     // selected currency
  MetalPricesResponse? _latestUsd;  // USD snapshot for the ounce table
  String? _error;

  /// Raw payload of the last successful fetch, kept so a currency switch or a
  /// cold start can rebuild prices without touching the network.
  Map<String, dynamic>? _lastRaw;
  DateTime? _lastUpdatedAt;
  bool _cacheLoaded = false;

  static const String _cacheKey = "cached_prices_payload_v1";
  static const String _cacheAtKey = "cached_prices_fetched_at_v1";

  MetalPricesResponse? get latest => _latest;
  MetalPricesResponse? get latestUsd => _latestUsd;
  String? get error => _error;

  bool get isLoading => _latest == null && _fetching;

  /// When the displayed prices were actually fetched from the server.
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  /// True when we are showing cached prices that are no longer fresh, so the
  /// UI can label them instead of hiding everything behind an error.
  bool get isShowingCached {
    final at = _lastUpdatedAt;
    if (_latest == null || at == null) return false;
    return DateTime.now().difference(at) >
        const Duration(seconds: AppConfig.refreshSeconds * 3);
  }

  void bindSettings(AppSettings settings) {
    if (_settings == settings) return;
    _settings?.removeListener(_onSettingsChanged);
    _settings = settings;
    _settings?.addListener(_onSettingsChanged);

    _startTimerIfNeeded();
    unawaited(_loadCacheThenRefresh());
  }

  Future<void> _loadCacheThenRefresh() async {
    await _loadCache();
    await refresh();
  }

  void _onSettingsChanged() {
    // Currency changed. The cached payload already carries every exchange
    // rate, so re-derive locally first and only then go to the network.
    if (_lastRaw != null) {
      _applyRaw(_lastRaw!, notify: true);
    }
    unawaited(refresh(silent: _latest != null));
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.refreshSeconds),
          (_) => unawaited(refresh(silent: true)),
    );
  }

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final body = prefs.getString(_cacheKey);
      if (body == null || body.isEmpty) return;

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return;

      final at = prefs.getInt(_cacheAtKey);
      _lastUpdatedAt =
          at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);

      _applyRaw(decoded, notify: true);
    } catch (_) {
      // A corrupt cache must never block the app.
    }
  }

  Future<void> _saveCache(Map<String, dynamic> raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(raw));
      await prefs.setInt(
        _cacheAtKey,
        (_lastUpdatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      );
    } catch (_) {
      // Caching is best effort.
    }
  }

  /// Rebuilds both the selected-currency and USD views from one raw payload.
  /// Returns false when the payload carried no usable rates.
  bool _applyRaw(Map<String, dynamic> raw, {required bool notify}) {
    final currency = _settings?.currency ?? AppConfig.defaultCurrency;

    final selected = _api.adapt(raw, currency);
    if (!selected.success) return false;

    _lastRaw = raw;
    _latest = selected;
    _latestUsd = currency.toUpperCase() == "USD"
        ? selected
        : _api.adapt(raw, "USD");
    _error = null;

    if (notify) notifyListeners();
    return true;
  }

  Future<void> refresh({bool silent = false}) async {
    if (_fetching) return;

    _fetching = true;
    if (!silent && _latest == null) {
      _error = null;
      notifyListeners();
    }

    try {
      // One request serves every currency, including the USD ounce table.
      final raw = await _api.fetchRaw();

      final applied = _applyRaw(raw, notify: false);
      if (applied) {
        _lastUpdatedAt = DateTime.now();
        unawaited(_saveCache(raw));
      } else if (_latest == null) {
        _error = "Rates are not available right now. Please try again.";
      }

      // The request itself succeeded, so the network is definitely up.
      ConnectivityService.instance.reportSuccess();
    } on NetworkUnavailableException {
      ConnectivityService.instance.reportNetworkFailure();
      // Keep whatever we are already showing. Only a first-run failure, with
      // nothing cached, is worth surfacing as an error.
      if (_latest == null) {
        _error = "Could not reach the server. Please check your connection.";
      }
    } catch (e) {
      if (_latest == null) {
        _error = e.toString();
      }
    } finally {
      _fetching = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settings?.removeListener(_onSettingsChanged);
    _client.dispose();
    super.dispose();
  }
}
