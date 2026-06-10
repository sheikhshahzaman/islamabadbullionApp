import "package:flutter/foundation.dart";

import "../models/silver_note_response.dart";
import "../services/api_client.dart";
import "../services/silver_note_api.dart";

class SilverNoteProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();
  late final SilverNoteApi _api = SilverNoteApi(_client);

  SilverNoteResponse? _note;
  String? _error;
  bool _loading = false;

  SilverNoteResponse? get note => _note;
  String? get error => _error;
  bool get isLoading => _loading;

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.fetchNote();
      if (res.success) {
        _note = res;
      } else {
        _error = "Failed to load silver note";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}