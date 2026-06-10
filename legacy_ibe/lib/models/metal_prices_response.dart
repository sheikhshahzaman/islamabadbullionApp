import "metal_price.dart";

class MetalPricesResponse {
  final bool success;
  final int timestamp; // unix seconds
  final String currency;
  final List<MetalPrice> metals;

  MetalPricesResponse({
    required this.success,
    required this.timestamp,
    required this.currency,
    required this.metals,
  });

  factory MetalPricesResponse.fromJson(Map<String, dynamic> json) {
    final metalsJson = (json["metals"] as List<dynamic>? ?? const []);
    return MetalPricesResponse(
      success: json["success"] == true,
      timestamp: (json["timestamp"] is int) ? json["timestamp"] as int : 0,
      currency: (json["currency"] ?? "").toString(),
      metals: metalsJson
          .whereType<Map<String, dynamic>>()
          .map(MetalPrice.fromJson)
          .toList(),
    );
  }
}
