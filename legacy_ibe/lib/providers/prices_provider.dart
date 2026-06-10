import "dart:async";
import "package:flutter/foundation.dart";

import "../config.dart";
import "../models/metal_prices_response.dart";
import "../services/api_client.dart";
import "../services/prices_api.dart";
import "app_settings.dart";

class PricesProvider extends ChangeNotifier {
  AppSettings? _settings;

  final ApiClient _client = ApiClient();
  late final PricesApi _api = PricesApi(_client);

  Timer? _timer;
  bool _fetching = false;

  MetalPricesResponse? _latest;     // selected currency
  MetalPricesResponse? _latestUsd;  // cached USD snapshot for ounce table
  String? _error;

  DateTime? _lastUsdFetchAt;

  MetalPricesResponse? get latest => _latest;
  MetalPricesResponse? get latestUsd => _latestUsd;
  String? get error => _error;

  bool get isLoading => _latest == null && _fetching;

  static const Duration _usdRefreshInterval = Duration(minutes: 10);

  void bindSettings(AppSettings settings) {
    if (_settings == settings) return;
    _settings?.removeListener(_onSettingsChanged);
    _settings = settings;
    _settings?.addListener(_onSettingsChanged);

    _startTimerIfNeeded();
    unawaited(refresh());
  }

  void _onSettingsChanged() {
    unawaited(refresh());
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.refreshSeconds),
          (_) => unawaited(refresh(silent: true)),
    );
  }

  bool _shouldFetchUsd(String selectedCurrency) {
    if (selectedCurrency.toUpperCase() == "USD") return false;
    if (_latestUsd == null) return true;
    if (_lastUsdFetchAt == null) return true;
    return DateTime.now().difference(_lastUsdFetchAt!) >= _usdRefreshInterval;
  }

  Future<void> refresh({bool silent = false}) async {
    if (_fetching) return;

    final selectedCurrency = _settings?.currency ?? AppConfig.defaultCurrency;

    _fetching = true;
    if (!silent) {
      _error = null;
      notifyListeners();
    }

    try {
      // 1) Always fetch selected currency
      final resSelected = await _api.fetchLatest(currency: selectedCurrency);

      if (!resSelected.success) {
        _error = "API returned success=false (currency: $selectedCurrency)";
      } else {
        _latest = resSelected;
        _error = null;
      }

      // 2) Only refresh USD occasionally
      if (selectedCurrency.toUpperCase() == "USD") {
        if (resSelected.success) {
          _latestUsd = resSelected;
          _lastUsdFetchAt = DateTime.now();
        }
      } else if (_shouldFetchUsd(selectedCurrency)) {
        final resUsd = await _api.fetchLatest(currency: "USD");
        if (resUsd.success) {
          _latestUsd = resUsd;
          _lastUsdFetchAt = DateTime.now();
        } else {
          _error ??= "API returned success=false (currency: USD)";
        }
      }
    } catch (e) {
      _error = e.toString();
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