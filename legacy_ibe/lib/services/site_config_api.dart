import "../config.dart";
import "../models/site_config.dart";
import "api_client.dart";

/// Fetches the admin-managed site configuration (GET /api/app-config).
class SiteConfigApi {
  final ApiClient _client;
  SiteConfigApi(this._client);

  Future<SiteConfig> fetch() async {
    final json = await _client.getJson(
      Uri.parse("${AppConfig.apiBase}/app-config"),
    );
    return SiteConfig.fromJson(json);
  }
}
