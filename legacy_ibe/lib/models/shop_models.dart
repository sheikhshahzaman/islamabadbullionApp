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
  final double packagingCharge; // per unit, shown separately at checkout

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
    this.packagingCharge = 0,
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
      currentPrice: json["current_price"] == null
          ? null
          : _d(json["current_price"]),
      discountLabel: json["discount_label"] == null
          ? null
          : _s(json["discount_label"]),
      stockCount: _i(json["stock_count"]),
      packagingCharge: _d(json["packaging_charge"]),
    );
  }
}

class OrderLine {
  final String productName;
  final String metal;
  final String karat;
  final double quantity;
  final String? unit; // non-null for metal-by-weight Buy/Sell lines
  final double unitPrice;
  final double packagingCharge; // per unit
  final double packagingTotal; // packagingCharge * quantity
  final double lineTotal;

  OrderLine({
    required this.productName,
    required this.metal,
    required this.karat,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.packagingCharge,
    required this.packagingTotal,
    required this.lineTotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    productName: _s(json["product_name"]),
    metal: _s(json["metal"]),
    karat: _s(json["karat"]),
    quantity: _d(json["quantity"]),
    unit: json["unit"] == null ? null : _s(json["unit"]),
    unitPrice: _d(json["unit_price"]),
    packagingCharge: _d(json["packaging_charge"]),
    packagingTotal: _d(json["packaging_total"]),
    lineTotal: _d(json["line_total"]),
  );

  /// A synthesized Buy/Sell (metal-by-weight) line carries a [unit];
  /// cart product lines do not.
  bool get isMetalLine => unit != null && unit!.trim().isNotEmpty;

  /// Quantity without a trailing ".0" (3.5 -> "3.5", 2.0 -> "2").
  String get quantityLabel => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();
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
  final String statusLabel;
  final String orderType; // buy | sell
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final String deliveryMethod; // pickup | delivery
  final String? deliveryAddress;
  final double deliveryCharge;
  final double grandTotal;
  final List<OrderLine> items;
  final OrderPayment? payment;
  final OrderTracking? tracking;

  ShopOrder({
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    required this.orderType,
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.deliveryMethod,
    required this.deliveryAddress,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.items,
    required this.payment,
    required this.tracking,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
    orderNumber: _s(json["order_number"]),
    status: _s(json["status"]),
    statusLabel: _s(json["status_label"]).isEmpty
        ? _statusLabel(_s(json["status"]))
        : _s(json["status_label"]),
    orderType: _s(json["type"]),
    customerName: _s(json["customer_name"]),
    customerPhone: _s(json["customer_phone"]),
    totalAmount: _d(json["total_amount"]),
    deliveryMethod:
        json["delivery_method"] == null || _s(json["delivery_method"]).isEmpty
        ? "pickup"
        : _s(json["delivery_method"]),
    deliveryAddress: json["delivery_address"]?.toString(),
    deliveryCharge: _d(json["delivery_charge"]),
    grandTotal: json["grand_total"] != null
        ? _d(json["grand_total"])
        : _d(json["total_amount"]) + _d(json["delivery_charge"]),
    items: (json["items"] as List? ?? const [])
        .whereType<Map>()
        .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    payment: json["payment"] is Map
        ? OrderPayment.fromJson(_m(json["payment"]))
        : null,
    tracking: json["tracking"] is Map
        ? OrderTracking.fromJson(_m(json["tracking"]))
        : null,
  );
}

class OrderTrackingStep {
  final String key;
  final String label;
  final String state; // complete | current | upcoming | cancelled

  OrderTrackingStep({
    required this.key,
    required this.label,
    required this.state,
  });

  factory OrderTrackingStep.fromJson(Map<String, dynamic> json) =>
      OrderTrackingStep(
        key: _s(json["key"]),
        label: _s(json["label"]),
        state: _s(json["state"]),
      );
}

class OrderTracking {
  final String currentStatus;
  final String currentLabel;
  final List<OrderTrackingStep> steps;

  OrderTracking({
    required this.currentStatus,
    required this.currentLabel,
    required this.steps,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) => OrderTracking(
    currentStatus: _s(json["current_status"]),
    currentLabel: _s(json["current_label"]),
    steps: (json["steps"] as List? ?? const [])
        .whereType<Map>()
        .map((e) => OrderTrackingStep.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

String _statusLabel(String status) => switch (status) {
  "pending" => "Order pending",
  "awaiting_verification" => "Order pending",
  "confirmed" => "Order confirmed",
  "processing" => "Order dispatched",
  "dispatched" => "Order dispatched",
  "delivered" => "Order delivered",
  "cancelled" => "Order cancelled",
  _ => status,
};

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
