import "../config.dart";
import "../models/silver_note_response.dart";
import "api_client.dart";

class SilverNoteApi {
  final ApiClient _client;
  SilverNoteApi(this._client);

  Future<SilverNoteResponse> fetchNote() async {
    final uri = Uri.parse("${AppConfig.baseUrl}/api/silver_note.php");
    final json = await _client.getJson(uri);
    return SilverNoteResponse.fromJson(json);
  }
}