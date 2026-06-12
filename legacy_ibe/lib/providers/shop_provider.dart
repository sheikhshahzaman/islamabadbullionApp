import "package:flutter/foundation.dart";

import "../models/shop_models.dart";
import "../services/api_client.dart";
import "../services/shop_api.dart";

/// Loads the product catalog + categories from the Laravel backend.
class ShopProvider extends ChangeNotifier {
  final ShopApi _api = ShopApi(ApiClient());

  List<ShopProduct> _products = [];
  List<ShopCategory> _categories = [];
  String? _selectedCategorySlug;
  bool _loading = false;
  String? _error;

  List<ShopProduct> get products => _products;
  List<ShopCategory> get categories => _categories;
  String? get selectedCategorySlug => _selectedCategorySlug;
  bool get loading => _loading;
  String? get error => _error;

  ShopApi get api => _api;

  Future<void> load({bool refresh = false}) async {
    if (_loading) return;
    if (_products.isNotEmpty && !refresh) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.fetchCategories(),
        _api.fetchProducts(categorySlug: _selectedCategorySlug),
      ]);
      _categories = results[0] as List<ShopCategory>;
      _products = results[1] as List<ShopProduct>;
    } catch (e) {
      _error = "Could not load products. Please check your connection.";
      if (kDebugMode) debugPrint("Shop load failed: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(String? slug) async {
    if (_selectedCategorySlug == slug) return;
    _selectedCategorySlug = slug;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _api.fetchProducts(categorySlug: slug);
    } catch (e) {
      _error = "Could not load products. Please check your connection.";
      if (kDebugMode) debugPrint("Shop category load failed: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
