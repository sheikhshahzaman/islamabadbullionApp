import "dart:async";
import "package:flutter/foundation.dart";

import "../services/api_client.dart";
import "../services/headlines_api.dart";
import "../models/headline_item.dart";

class HeadlinesProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();
  late final HeadlinesApi _api = HeadlinesApi(_client);

  Timer? _timer;
  bool _fetching = false;

  List<HeadlineItem> _items = [];
  String? _error;

  List<HeadlineItem> get items => _items;
  String? get error => _error;
  bool get isLoading => _items.isEmpty && _fetching;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh(silent: true));
    refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    if (_fetching) return;

    _fetching = true;
    if (!silent) {
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _api.fetchHeadlines();
      _items = data;
      _error = null;
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
    _client.dispose();
    super.dispose();
  }
}