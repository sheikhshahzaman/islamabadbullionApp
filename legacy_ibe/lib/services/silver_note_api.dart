import "../config.dart";
import "../models/silver_note_response.dart";
import "api_client.dart";

/// Fetches the optional admin-managed silver note from the Laravel backend
/// (GET /api/silver-note). The note is shown under the silver table only when
/// the admin marks it active and provides text. If the endpoint is unavailable
/// the call throws and the provider keeps the note hidden — so the screen
/// degrades gracefully.
class SilverNoteApi {
  final ApiClient _client;
  SilverNoteApi(this._client);

  Future<SilverNoteResponse> fetchNote() async {
    final json = await _client.getJson(
      Uri.parse("${AppConfig.apiBase}/silver-note"),
    );
    return SilverNoteResponse.fromJson(json);
  }
}
