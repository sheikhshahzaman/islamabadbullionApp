import "package:flutter/foundation.dart";

import "../models/shop_models.dart";

class CartLine {
  final ShopProduct product;
  int quantity;

  CartLine({required this.product, this.quantity = 1});

  double get lineTotal =>
      ((product.currentPrice ?? 0) + product.packagingCharge) * quantity;
}

/// Local (in-app) cart. The server reprices everything at checkout, so the
/// cart only needs product ids and quantities — prices shown here are
/// live estimates from the catalog.
class CartProvider extends ChangeNotifier {
  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList(growable: false);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal =>
      _lines.values.fold(0.0, (sum, line) => sum + line.lineTotal);

  /// product_id -> quantity, the shape the order API expects.
  Map<int, int> get productQuantities =>
      _lines.map((id, line) => MapEntry(id, line.quantity));

  void add(ShopProduct product, [int quantity = 1]) {
    final existing = _lines[product.id];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _lines[product.id] = CartLine(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void increase(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    line.quantity = (line.quantity + 1).clamp(1, 9999);
    notifyListeners();
  }

  void decrease(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    if (line.quantity <= 1) {
      _lines.remove(productId);
    } else {
      line.quantity -= 1;
    }
    notifyListeners();
  }

  void remove(int productId) {
    if (_lines.remove(productId) != null) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }

  /// Refresh stored product data (and its live price) after a catalog reload.
  void refreshProducts(List<ShopProduct> products) {
    var changed = false;
    for (final product in products) {
      final line = _lines[product.id];
      if (line != null) {
        _lines[product.id] = CartLine(product: product, quantity: line.quantity);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
