import "metal_price.dart";

class MetalPricesResponse {
  final bool success;
  final int timestamp; // unix seconds
  final String currency;
  final List<MetalPrice> metals;
  final PriceCatalog priceCatalog;

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
    this.priceCatalog = PriceCatalog.empty,
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
      priceCatalog: PriceCatalog.fromJson(json["price_catalog"]),
      spotGoldBid: sd(json["spot_gold_bid"]),
      spotGoldAsk: sd(json["spot_gold_ask"]),
      spotSilverBid: sd(json["spot_silver_bid"]),
      spotSilverAsk: sd(json["spot_silver_ask"]),
    );
  }
}

class PriceCatalog {
  final Map<String, String> metals;
  final Map<String, String> goldKarats;
  final Map<String, String> goldUnits;
  final Map<String, String> silverUnits;

  const PriceCatalog({
    required this.metals,
    required this.goldKarats,
    required this.goldUnits,
    required this.silverUnits,
  });

  static const empty = PriceCatalog(
    metals: {},
    goldKarats: {},
    goldUnits: {},
    silverUnits: {},
  );

  factory PriceCatalog.fromJson(dynamic json) {
    Map<String, dynamic> m(dynamic v) =>
        (v is Map) ? Map<String, dynamic>.from(v) : const {};

    Map<String, String> labels(dynamic value) {
      final source = m(value);
      return source.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    final catalog = m(json);
    final gold = m(catalog["gold"]);
    final silver = m(catalog["silver"]);

    return PriceCatalog(
      metals: labels(catalog["metals"]),
      goldKarats: labels(gold["karats"]),
      goldUnits: labels(gold["units"]),
      silverUnits: labels(silver["units"]),
    );
  }
}
