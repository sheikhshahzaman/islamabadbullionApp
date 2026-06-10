// lib/models/metal_price.dart

class PriceBlock {
  final double perOz;
  final double perGram;
  final double perTola;

  const PriceBlock({
    required this.perOz,
    required this.perGram,
    required this.perTola,
  });

  factory PriceBlock.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return PriceBlock(
      perOz: d(json["per_oz"]),
      perGram: d(json["per_gram"]),
      perTola: d(json["per_tola"]),
    );
  }
}

class MetalPrice {
  final String code; // XAU, XAG...
  final String name; // Gold...
  final bool isManual; // optional (backend may or may not return this)

  // MID (backward compatible fields)
  final PriceBlock mid;

  // SELL/BUY blocks
  final PriceBlock sell;
  final PriceBlock buy;

  // Gold karats per gram (optional)
  final Map<String, double> goldKaratMid;
  final Map<String, double> goldKaratSell;
  final Map<String, double> goldKaratBuy;

  // ✅ Silver quantities (optional)
  // Keys expected from backend: "Gram", "10 Gram", "Tola", "10 Tola", "1 KG"
  final Map<String, double> silverQtyMid;
  final Map<String, double> silverQtySell;
  final Map<String, double> silverQtyBuy;

  MetalPrice({
    required this.code,
    required this.name,
    required this.isManual,
    required this.mid,
    required this.sell,
    required this.buy,
    required this.goldKaratMid,
    required this.goldKaratSell,
    required this.goldKaratBuy,
    required this.silverQtyMid,
    required this.silverQtySell,
    required this.silverQtyBuy,
  });

  factory MetalPrice.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    Map<String, double> mapD(dynamic m) {
      if (m is Map) {
        // Works for Map<String, dynamic> or Map<dynamic, dynamic>
        final out = <String, double>{};
        m.forEach((k, v) {
          out[k.toString()] = d(v);
        });
        return out;
      }
      return {};
    }

    final mid = PriceBlock(
      perOz: d(json["per_oz"]),
      perGram: d(json["per_gram"]),
      perTola: d(json["per_tola"]),
    );

    final sell = PriceBlock.fromJson((json["sell"] as Map<String, dynamic>?) ?? const {});
    final buy = PriceBlock.fromJson((json["buy"] as Map<String, dynamic>?) ?? const {});

    return MetalPrice(
      code: (json["code"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      isManual: json["is_manual"] == true, // safe if missing

      mid: mid,
      sell: sell,
      buy: buy,

      goldKaratMid: mapD(json["gold_by_karat_per_gram"]),
      goldKaratSell: mapD(json["gold_by_karat_per_gram_sell"]),
      goldKaratBuy: mapD(json["gold_by_karat_per_gram_buy"]),

      // ✅ Silver quantities (safe if missing)
      silverQtyMid: mapD(json["silver_by_qty"]),
      silverQtySell: mapD(json["silver_by_qty_sell"]),
      silverQtyBuy: mapD(json["silver_by_qty_buy"]),
    );
  }
}
