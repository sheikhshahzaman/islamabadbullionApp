import "../config.dart";
import "../models/metal_prices_response.dart";
import "api_client.dart";

class PricesApi {
  final ApiClient _client;
  PricesApi(this._client);

  Future<MetalPricesResponse> fetchLatest({required String currency}) async {
    final uri = Uri.parse("${AppConfig.baseUrl}/api/latest.php?currency=$currency&t=${DateTime.now().millisecondsSinceEpoch}");
    final json = await _client.getJson(uri);
    return MetalPricesResponse.fromJson(json);
  }
}
