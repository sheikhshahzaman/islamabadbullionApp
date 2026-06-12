import "../config.dart";
import "../services/api_client.dart";
import "../models/headline_item.dart";

/// Headlines now come from the Laravel backend's news ticker
/// (managed in the website admin panel).
class HeadlinesApi {
  final ApiClient _client;
  HeadlinesApi(this._client);

  Future<List<HeadlineItem>> fetchHeadlines() async {
    final uri = Uri.parse(
      "${AppConfig.apiBase}/ticker?t=${DateTime.now().millisecondsSinceEpoch}",
    );
    final json = await _client.getJson(uri);

    final list = (json["headlines"] as List? ?? const []);
    return list.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      final text = (map["title"] ?? "").toString();
      return HeadlineItem.fromJson({
        "id": map["id"] is int ? map["id"] : 0,
        // The ticker is single-language; show the same text for EN and UR.
        "en": text,
        "ur": text,
      });
    }).toList();
  }
}
