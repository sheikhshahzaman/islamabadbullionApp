import "metal_price.dart";

class MetalPricesResponse {
  final bool success;
  final int timestamp; // unix seconds
  final String currency;
  final List<MetalPrice> metals;

  /// Live international spot (USD per ounce) straight from the backend, kept
  /// separate from the admin-set local rates. Null when unavailable.
  final double? spotGoldBid;
  final double? spotGoldAsk;
  final double? spotSilverBid;
  final double? spotSilverAsk;

  MetalPricesResponse({
    required this.success,
    required this.timestamp,
    required this.currency,
    required this.metals,
    this.spotGoldBid,
    this.spotGoldAsk,
    this.spotSilverBid,
    this.spotSilverAsk,
  });

  factory MetalPricesResponse.fromJson(Map<String, dynamic> json) {
    final metalsJson = (json["metals"] as List<dynamic>? ?? const []);
    double? sd(dynamic v) => (v is num && v > 0) ? v.toDouble() : null;
    return MetalPricesResponse(
      success: json["success"] == true,
      timestamp: (json["timestamp"] is int) ? json["timestamp"] as int : 0,
      currency: (json["currency"] ?? "").toString(),
      metals: metalsJson
          .whereType<Map<String, dynamic>>()
          .map(MetalPrice.fromJson)
          .toList(),
      spotGoldBid: sd(json["spot_gold_bid"]),
      spotGoldAsk: sd(json["spot_gold_ask"]),
      spotSilverBid: sd(json["spot_silver_bid"]),
      spotSilverAsk: sd(json["spot_silver_ask"]),
    );
  }
}
