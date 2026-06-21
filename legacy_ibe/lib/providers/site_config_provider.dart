import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../models/site_config.dart";
import "../services/api_client.dart";
import "../services/site_config_api.dart";

/// Holds the admin-managed [SiteConfig]. Hydrates instantly from a local cache,
/// then refreshes from the API so admin edits on the website propagate to the
/// app on the next launch/refresh.
class SiteConfigProvider extends ChangeNotifier {
  static const String _cacheKey = "site_config_cache_v1";

  final SiteConfigApi _api;
  SiteConfigProvider({SiteConfigApi? api})
      : _api = api ?? SiteConfigApi(ApiClient());

  SiteConfig _config = SiteConfig.defaults;
  SiteConfig get config => _config;

  Future<void> load() async {
    // 1) Instant hydrate from the last cached config (offline-friendly).
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is Map) {
          _config = SiteConfig.fromJson(Map<String, dynamic>.from(decoded));
          notifyListeners();
        }
      }
    } catch (_) {
      // ignore cache errors — defaults remain
    }

    // 2) Refresh from the network in the background.
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final fresh = await _api.fetch();
      _config = fresh;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(fresh.toCacheJson()));
    } catch (_) {
      // Keep the cached/default config if the network is unavailable.
    }
  }
}
