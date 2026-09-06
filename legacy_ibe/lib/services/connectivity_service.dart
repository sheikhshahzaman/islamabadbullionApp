// lib/services/connectivity_service.dart
import "dart:async";

import "package:flutter/foundation.dart";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart";

import "../config.dart";

/// Decides whether the app is really offline.
///
/// The previous implementation used the package defaults, which probe four
/// foreign hosts (one.one.one.one, icanhazip.com, jsonplaceholder, pokeapi)
/// with a 3 second timeout each and flip to "offline" the moment a single
/// round fails. On a slow connection those probes time out constantly, so the
/// app declared "No Internet" while our own API was perfectly reachable.
///
/// This service instead:
///   * probes our OWN backend, so the answer reflects what the app needs,
///   * allows a long timeout, because slow is not the same as offline,
///   * requires several consecutive failures before reporting offline,
///   * accepts evidence from real API traffic, so a successful price refresh
///     immediately proves we are online without any extra request.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  /// Consecutive failed probes required before we tell the user we are offline.
  static const int _failuresBeforeOffline = 3;

  /// How often to probe while the app is running.
  static const Duration _pollInterval = Duration(seconds: 30);

  /// Grace period after start-up. The radio is often not ready in the first
  /// moment after a cold start or resume, which is what made the error appear
  /// immediately on opening the app.
  static const Duration _startupGrace = Duration(seconds: 5);

  late final InternetConnection _connection = InternetConnection.createInstance(
    useDefaultOptions: false,
    customCheckOptions: [
      // Our own API first: this is the only reachability that actually matters.
      InternetCheckOption(
        uri: Uri.parse("${AppConfig.apiBase}/app-config"),
        timeout: const Duration(seconds: 12),
      ),
      // Fallback so a backend hiccup alone is not reported as "no internet".
      InternetCheckOption(
        uri: Uri.parse("https://one.one.one.one"),
        timeout: const Duration(seconds: 8),
      ),
    ],
  );

  /// True until proven otherwise, so the UI never flashes an error on launch.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  Timer? _timer;
  int _consecutiveFailures = 0;
  bool _started = false;

  bool get isOnline => online.value;

  void start() {
    if (_started) return;
    _started = true;

    Future<void>.delayed(_startupGrace, () {
      unawaited(_probe());
      _timer = Timer.periodic(_pollInterval, (_) => unawaited(_probe()));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  /// Real API traffic succeeded, so we are definitively online. Cheaper and
  /// more reliable than any probe.
  void reportSuccess() {
    _consecutiveFailures = 0;
    _set(true);
  }

  /// A request failed with a network-level error. Counts towards the failure
  /// threshold but never flips the state on its own from a single blip.
  void reportNetworkFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failuresBeforeOffline) {
      _set(false);
    }
  }

  /// Forces an immediate check. Used by "Try again" buttons.
  Future<bool> checkNow() async {
    final ok = await _hasAccess();
    if (ok) {
      reportSuccess();
    } else {
      _consecutiveFailures = _failuresBeforeOffline;
      _set(false);
    }
    return ok;
  }

  Future<void> _probe() async {
    // No point probing when real traffic already proved we are online.
    if (await _hasAccess()) {
      reportSuccess();
    } else {
      reportNetworkFailure();
    }
  }

  Future<bool> _hasAccess() async {
    try {
      return await _connection.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  void _set(bool value) {
    if (online.value != value) {
      online.value = value;
    }
  }
}
