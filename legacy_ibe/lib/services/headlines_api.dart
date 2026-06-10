import "../config.dart";
import "../services/api_client.dart";
import "../models/headline_item.dart";

class HeadlinesApi {
  final ApiClient _client;
  HeadlinesApi(this._client);

  Future<List<HeadlineItem>> fetchHeadlines() async {
    final uri = Uri.parse(
      "${AppConfig.baseUrl}/api/headlines.php?t=${DateTime.now().millisecondsSinceEpoch}",
    );
    final json = await _client.getJson(uri);

    final ok = json["success"] == true;
    if (!ok) return [];

    final list = (json["headlines"] as List? ?? const []);
    return list
        .whereType<Map>()
        .map((e) => HeadlineItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}