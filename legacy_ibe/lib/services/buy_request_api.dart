import "../config.dart";
import "api_client.dart";

/// One bar size offered on the request screen, taken from admin products.
class BuyRequestSize {
  final int productId;
  final String name;
  final String weight;
  final double packagingCharge;

  const BuyRequestSize({
    required this.productId,
    required this.name,
    required this.weight,
    required this.packagingCharge,
  });

  /// What the customer sees as the "size". Falls back to the product name when
  /// admin left the weight blank.
  String get label => weight.trim().isNotEmpty ? weight.trim() : name;

  factory BuyRequestSize.fromJson(Map<String, dynamic> json) => BuyRequestSize(
    productId: (json["product_id"] as num).toInt(),
    name: (json["name"] ?? "").toString(),
    weight: (json["weight"] ?? "").toString(),
    packagingCharge: ((json["packaging_charge"] ?? 0) as num).toDouble(),
  );
}

class BuyRequestOptions {
  final Map<String, List<String>> categories;   // metal -> [bar, rawa]
  final Map<String, String> categoryLabels;
  final Map<String, List<BuyRequestSize>> barSizes; // metal -> sizes
  final Map<String, String> rawaUnits;          // gram -> Gram
  final double rawaPackagingCharge;

  const BuyRequestOptions({
    required this.categories,
    required this.categoryLabels,
    required this.barSizes,
    required this.rawaUnits,
    required this.rawaPackagingCharge,
  });

  List<String> categoriesFor(String metal) =>
      categories[metal] ?? const ["bar"];

  List<BuyRequestSize> sizesFor(String metal) =>
      barSizes[metal] ?? const <BuyRequestSize>[];

  factory BuyRequestOptions.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> m(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : const {};

    List<String> strings(dynamic v) =>
        (v is List) ? v.map((e) => e.toString()).toList() : const <String>[];

    final cats = m(json["categories"]);
    final sizes = m(json["bar_sizes"]);

    return BuyRequestOptions(
      categories: {
        for (final e in cats.entries) e.key: strings(e.value),
      },
      categoryLabels: m(json["category_labels"])
          .map((k, v) => MapEntry(k, v.toString())),
      barSizes: {
        for (final e in sizes.entries)
          e.key: (e.value is List)
              ? (e.value as List)
                  .whereType<Map<String, dynamic>>()
                  .map(BuyRequestSize.fromJson)
                  .toList()
              : <BuyRequestSize>[],
      },
      rawaUnits: m(json["rawa_units"]).map((k, v) => MapEntry(k, v.toString())),
      rawaPackagingCharge:
          ((json["rawa_packaging_charge"] ?? 0) as num).toDouble(),
    );
  }
}

/// What a selection costs. Always computed by the server.
class BuyRequestQuote {
  final double unitPrice;
  final double packagingCharge;
  final double totalAmount;

  const BuyRequestQuote({
    required this.unitPrice,
    required this.packagingCharge,
    required this.totalAmount,
  });

  factory BuyRequestQuote.fromJson(Map<String, dynamic> json) =>
      BuyRequestQuote(
        unitPrice: ((json["unit_price"] ?? 0) as num).toDouble(),
        packagingCharge: ((json["packaging_charge"] ?? 0) as num).toDouble(),
        totalAmount: ((json["total_amount"] ?? 0) as num).toDouble(),
      );
}

class SubmittedBuyRequest {
  final String reference;
  final String selection;
  final double totalAmount;

  const SubmittedBuyRequest({
    required this.reference,
    required this.selection,
    required this.totalAmount,
  });

  factory SubmittedBuyRequest.fromJson(Map<String, dynamic> json) =>
      SubmittedBuyRequest(
        reference: (json["reference"] ?? "").toString(),
        selection: (json["selection"] ?? "").toString(),
        totalAmount: ((json["total_amount"] ?? 0) as num).toDouble(),
      );
}

/// "Request to buy gold/silver" — a call-back request, not an order.
class BuyRequestApi {
  final ApiClient _client;
  BuyRequestApi(this._client);

  Uri _uri(String path) => Uri.parse("${AppConfig.apiBase}$path");

  /// Screens own their client, so they close it when they go away.
  void dispose() => _client.dispose();

  Future<BuyRequestOptions> fetchOptions() async {
    final json = await _client.getJson(_uri("/buy-requests/options"));
    return BuyRequestOptions.fromJson(json);
  }

  /// Prices a selection without saving. The app never sends a price.
  Future<BuyRequestQuote> quote({
    required String metal,
    required String category,
    int? productId,
    double? weightValue,
    String? weightUnit,
  }) async {
    final json = await _client.postJson(
      _uri("/buy-requests/quote"),
      body: {
        "metal": metal,
        "category": category,
        if (productId != null) "product_id": productId,
        if (weightValue != null) "weight_value": weightValue,
        if (weightUnit != null) "weight_unit": weightUnit,
      },
    );
    return BuyRequestQuote.fromJson(
      Map<String, dynamic>.from(json["quote"] as Map),
    );
  }

  Future<SubmittedBuyRequest> submit({
    required String metal,
    required String category,
    int? productId,
    double? weightValue,
    String? weightUnit,
    required String customerName,
    required String customerPhone,
  }) async {
    final json = await _client.postJson(
      _uri("/buy-requests"),
      body: {
        "metal": metal,
        "category": category,
        if (productId != null) "product_id": productId,
        if (weightValue != null) "weight_value": weightValue,
        if (weightUnit != null) "weight_unit": weightUnit,
        "customer_name": customerName,
        "customer_phone": customerPhone,
        "source": "app",
      },
    );
    return SubmittedBuyRequest.fromJson(
      Map<String, dynamic>.from(json["request"] as Map),
    );
  }
}
