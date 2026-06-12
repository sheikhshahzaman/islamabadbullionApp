// Models for the shop / checkout / verification features
// backed by the Laravel API.

double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
int _i(dynamic v) => (v is num) ? v.toInt() : 0;
String _s(dynamic v) => (v ?? "").toString();

Map<String, dynamic> _m(dynamic v) =>
    (v is Map) ? Map<String, dynamic>.from(v) : const {};

class ShopCategory {
  final int id;
  final String name;
  final String slug;
  final String icon;

  ShopCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> json) => ShopCategory(
        id: _i(json["id"]),
        name: _s(json["name"]),
        slug: _s(json["slug"]),
        icon: _s(json["icon"]),
      );
}

class ShopProduct {
  final int id;
  final String name;
  final String description;
  final String weight;
  final String metal; // gold | silver
  final String karat;
  final String? imageUrl;
  final ShopCategory? category;
  final double? currentPrice; // null = price unavailable right now
  final String? discountLabel;
  final int stockCount;

  ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.metal,
    required this.karat,
    required this.imageUrl,
    required this.category,
    required this.currentPrice,
    required this.discountLabel,
    required this.stockCount,
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final cat = _m(json["category"]);
    return ShopProduct(
      id: _i(json["id"]),
      name: _s(json["name"]),
      description: _s(json["description"]),
      weight: _s(json["weight"]),
      metal: _s(json["metal"]),
      karat: _s(json["karat"]),
      imageUrl: json["image"] == null ? null : _s(json["image"]),
      category: cat.isEmpty ? null : ShopCategory.fromJson(cat),
      currentPrice: json["current_price"] == null ? null : _d(json["current_price"]),
      discountLabel:
          json["discount_label"] == null ? null : _s(json["discount_label"]),
      stockCount: _i(json["stock_count"]),
    );
  }
}

class OrderLine {
  final String productName;
  final String metal;
  final String karat;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  OrderLine({
    required this.productName,
    required this.metal,
    required this.karat,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productName: _s(json["product_name"]),
        metal: _s(json["metal"]),
        karat: _s(json["karat"]),
        quantity: _i(json["quantity"]),
        unitPrice: _d(json["unit_price"]),
        lineTotal: _d(json["line_total"]),
      );
}

class OrderPayment {
  final String method;
  final String status;
  final String? referenceNumber;

  OrderPayment({
    required this.method,
    required this.status,
    this.referenceNumber,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
        method: _s(json["method"]),
        status: _s(json["status"]),
        referenceNumber: json["reference_number"]?.toString(),
      );
}

class ShopOrder {
  final String orderNumber;
  final String status;
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final List<OrderLine> items;
  final OrderPayment? payment;

  ShopOrder({
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.items,
    required this.payment,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
        orderNumber: _s(json["order_number"]),
        status: _s(json["status"]),
        customerName: _s(json["customer_name"]),
        customerPhone: _s(json["customer_phone"]),
        totalAmount: _d(json["total_amount"]),
        items: (json["items"] as List? ?? const [])
            .whereType<Map>()
            .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        payment: json["payment"] is Map
            ? OrderPayment.fromJson(_m(json["payment"]))
            : null,
      );
}

/// Payment account details (set by the admin on the website) shown to the
/// customer so they can transfer manually and upload proof.
class PaymentAccounts {
  final Map<String, Map<String, String>> accounts;

  PaymentAccounts(this.accounts);

  factory PaymentAccounts.fromJson(Map<String, dynamic> json) {
    final out = <String, Map<String, String>>{};
    json.forEach((method, details) {
      if (details is Map) {
        out[method] = details.map((k, v) => MapEntry(k.toString(), _s(v)));
      }
    });
    return PaymentAccounts(out);
  }

  Map<String, String> forMethod(String method) => accounts[method] ?? const {};
}

class CreatedOrder {
  final ShopOrder order;
  final PaymentAccounts paymentAccounts;

  CreatedOrder({required this.order, required this.paymentAccounts});

  factory CreatedOrder.fromJson(Map<String, dynamic> json) => CreatedOrder(
        order: ShopOrder.fromJson(_m(json["order"])),
        paymentAccounts: PaymentAccounts.fromJson(_m(json["payment_accounts"])),
      );
}

class VerifyResult {
  final bool valid;
  final String source; // inventory | approved_list
  final String message;
  final Map<String, dynamic> item;

  VerifyResult({
    required this.valid,
    required this.source,
    required this.message,
    required this.item,
  });

  factory VerifyResult.fromJson(Map<String, dynamic> json) => VerifyResult(
        valid: json["valid"] == true,
        source: _s(json["source"]),
        message: _s(json["message"]),
        item: _m(json["item"]),
      );
}
