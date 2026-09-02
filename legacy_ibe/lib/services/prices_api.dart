import "../config.dart";
import "../models/metal_prices_response.dart";
import "api_client.dart";

/// Fetches prices from the Laravel backend (/api/prices) and adapts the
/// response into the app's existing [MetalPricesResponse] model, so every
/// screen built against the old backend keeps working unchanged.
///
/// The backend serves PKR. Other currencies are converted client-side
/// using the exchange rates included in the same response.
class PricesApi {
  final ApiClient _client;
  PricesApi(this._client);

  static const double _gramsPerOz = 31.1035;
  static const double _gramsPerTola = 11.6638038;

  Future<MetalPricesResponse> fetchLatest({required String currency}) async {
    final uri = Uri.parse(
      "${AppConfig.apiBase}/prices?t=${DateTime.now().millisecondsSinceEpoch}",
    );
    final json = await _client.getJson(uri);
    return _adapt(json, currency.toUpperCase());
  }

  MetalPricesResponse _adapt(Map<String, dynamic> json, String currency) {
    double d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    Map<String, dynamic> m(dynamic v) =>
        (v is Map) ? Map<String, dynamic>.from(v) : const {};

    final gold = m(json["gold"]);
    final silver = m(json["silver"]);
    final currencies = m(json["currencies"]);
    final catalog = m(json["price_catalog"]);
    final catalogSilverUnits = m(m(catalog["silver"])["units"]);

    // PKR -> selected currency divisor (1.0 for PKR itself).
    double rate = 1.0;
    if (currency != "PKR") {
      final pair = m(currencies["${currency.toLowerCase()}_pkr"]);
      final buy = d(pair["buy"]);
      if (buy > 0) rate = buy;
    }
    double conv(double pkr) => pkr <= 0 ? 0.0 : pkr / rate;

    // --- helpers over the gold/silver matrices ---
    double goldAt(String karat, String unit, String side) =>
        conv(d(m(m(gold[karat])[unit])[side]));
    double silverAt(String unit, String side) => conv(d(m(silver[unit])[side]));

    Map<String, dynamic> goldKaratPerGram(String side) => {
      "24K": goldAt("24k", "gram", side),
      "Rawa": goldAt("rawa", "gram", side),
      "22K": goldAt("22k", "gram", side),
      "21K": goldAt("21k", "gram", side),
      "18K": goldAt("18k", "gram", side),
    };

    Map<String, dynamic> silverByQty(String side) {
      final out = <String, dynamic>{
        "10 Tola (QR Packaging)": silverAt("10_tola_qr", side) > 0
            ? silverAt("10_tola_qr", side)
            : silverAt("10_tola", side),
        "Tola": silverAt("tola", side),
        "10 Tola": silverAt("10_tola", side),
        "5 Tola": silverAt("5_tola", side),
        "1 KG": silverAt("kg", side),
      };

      catalogSilverUnits.forEach((unit, label) {
        final value = silverAt(unit.toString(), side);
        if (value > 0) out[label.toString()] = value;
      });

      return out;
    }

    Map<String, dynamic> block(double perGram, double perTola) => {
      "per_oz": perGram * _gramsPerOz,
      "per_gram": perGram,
      "per_tola": perTola,
    };

    final metals = <Map<String, dynamic>>[];

    // Gold (headline price = 24K)
    final g24Gram = goldAt("24k", "gram", "base");
    if (g24Gram > 0) {
      metals.add({
        "code": "XAU",
        "name": "Gold",
        ...block(g24Gram, goldAt("24k", "tola", "base")),
        "sell": block(
          goldAt("24k", "gram", "sell"),
          goldAt("24k", "tola", "sell"),
        ),
        "buy": block(
          goldAt("24k", "gram", "buy"),
          goldAt("24k", "tola", "buy"),
        ),
        "gold_by_karat_per_gram": goldKaratPerGram("base"),
        "gold_by_karat_per_gram_sell": goldKaratPerGram("sell"),
        "gold_by_karat_per_gram_buy": goldKaratPerGram("buy"),
      });
    }

    // Silver
    final sGram = silverAt("gram", "base");
    if (sGram > 0) {
      metals.add({
        "code": "XAG",
        "name": "Silver",
        ...block(sGram, silverAt("tola", "base")),
        "sell": block(silverAt("gram", "sell"), silverAt("tola", "sell")),
        "buy": block(silverAt("gram", "buy"), silverAt("tola", "buy")),
        "silver_by_qty": silverByQty("base"),
        "silver_by_qty_sell": silverByQty("sell"),
        "silver_by_qty_buy": silverByQty("buy"),
      });
    }

    // Platinum / Palladium: backend gives {international: USD/oz, local: PKR/tola}
    for (final entry in const [
      ["platinum", "XPT", "Platinum"],
      ["palladium", "XPD", "Palladium"],
    ]) {
      final src = m(json[entry[0]]);
      final localTola = conv(d(src["local"]));
      if (localTola > 0) {
        final perGram = localTola / _gramsPerTola;
        final b = block(perGram, localTola);
        metals.add({
          "code": entry[1],
          "name": entry[2],
          ...b,
          "sell": b,
          "buy": b,
        });
      }
    }

    final updated = DateTime.tryParse((json["last_updated"] ?? "").toString());

    // Live international spot (USD/oz) — always USD, passed through untouched so
    // the app's spot table shows the real market spot, not the local rates.
    final quotes = m(json["quotes"]);
    final intl = m(json["international"]);
    final qGold = m(quotes["gold"]);
    final qSilver = m(quotes["silver"]);
    double? spot(dynamic v) => (v is num && v > 0) ? v.toDouble() : null;
    final spotGoldBid = spot(qGold["bid"]) ?? spot(intl["xau_usd"]);
    final spotSilverBid = spot(qSilver["bid"]) ?? spot(intl["xag_usd"]);

    return MetalPricesResponse.fromJson({
      "success": metals.isNotEmpty,
      "timestamp": (updated ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      "currency": currency,
      "metals": metals,
      "price_catalog": catalog,
      "spot_gold_bid": spotGoldBid,
      "spot_gold_ask": spot(qGold["ask"]) ?? spotGoldBid,
      "spot_silver_bid": spotSilverBid,
      "spot_silver_ask": spot(qSilver["ask"]) ?? spotSilverBid,
    });
  }
}
