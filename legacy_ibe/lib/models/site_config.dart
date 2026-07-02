// Site/business configuration served by the Laravel admin (GET /api/app-config).
// Editing the matching Settings in the website admin updates the app.
//
// Named SiteConfig to avoid clashing with [AppConfig] in config.dart, which
// holds build-time constants (apiBase, etc.).

class SiteConfig {
  final String siteName;
  final bool liveRatesEnabled;

  final String contactPhone;
  final String contactWhatsapp;
  final String contactEmail;
  final String contactAddress;
  final String mapEmbedUrl;

  final String hoursMonThu;
  final String hoursFri;
  final String hoursSat;
  final String hoursSun;

  /// Flat delivery charge (PKR) applied to every order that chooses delivery.
  /// Pickup is always free. 0 means free delivery.
  final double deliveryCharge;

  const SiteConfig({
    required this.siteName,
    required this.liveRatesEnabled,
    required this.contactPhone,
    required this.contactWhatsapp,
    required this.contactEmail,
    required this.contactAddress,
    required this.mapEmbedUrl,
    required this.hoursMonThu,
    required this.hoursFri,
    required this.hoursSat,
    required this.hoursSun,
    this.deliveryCharge = 0,
  });

  /// Sensible defaults (the previously hardcoded values), used on first launch
  /// before the API responds and as an offline fallback.
  static const SiteConfig defaults = SiteConfig(
    siteName: "Islamabad Bullion",
    liveRatesEnabled: true,
    contactPhone: "+92-340-2786222",
    contactWhatsapp: "+923409786111",
    contactEmail: "thelegacyjewellers@gmail.com",
    contactAddress:
        "Shop No 1, Ground Floor, Trade Center, F-7 Markaz Block 20-B F-7, Islamabad, 44210",
    mapEmbedUrl: "",
    hoursMonThu: "10AM - 8PM",
    hoursFri: "3PM - 9:30PM",
    hoursSat: "12PM - 9:30PM",
    hoursSun: "2PM - 9:30PM",
  );

  /// Parse the API/cache payload. Empty values fall back to [defaults] so a
  /// blank admin field never wipes out a usable value in the app.
  factory SiteConfig.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? "").toString().trim();
    Map<String, dynamic> m(dynamic v) =>
        (v is Map) ? Map<String, dynamic>.from(v) : const {};

    final contact = m(json["contact"]);
    final hours = m(json["hours"]);

    String pick(String value, String fallback) =>
        value.isEmpty ? fallback : value;

    const d = SiteConfig.defaults;
    return SiteConfig(
      siteName: pick(s(json["site_name"]), d.siteName),
      liveRatesEnabled: json["live_rates_enabled"] is bool
          ? json["live_rates_enabled"] as bool
          : d.liveRatesEnabled,
      contactPhone: pick(s(contact["phone"]), d.contactPhone),
      contactWhatsapp: pick(s(contact["whatsapp"]), d.contactWhatsapp),
      contactEmail: pick(s(contact["email"]), d.contactEmail),
      contactAddress: pick(s(contact["address"]), d.contactAddress),
      mapEmbedUrl: s(contact["map_embed_url"]),
      hoursMonThu: pick(s(hours["mon_thu"]), d.hoursMonThu),
      hoursFri: pick(s(hours["fri"]), d.hoursFri),
      hoursSat: pick(s(hours["sat"]), d.hoursSat),
      hoursSun: pick(s(hours["sun"]), d.hoursSun),
      deliveryCharge: (json["delivery_charge"] is num)
          ? (json["delivery_charge"] as num).toDouble()
          : 0,
    );
  }

  /// Round-trips through the local cache (SharedPreferences).
  Map<String, dynamic> toCacheJson() => {
        "site_name": siteName,
        "live_rates_enabled": liveRatesEnabled,
        "contact": {
          "phone": contactPhone,
          "whatsapp": contactWhatsapp,
          "email": contactEmail,
          "address": contactAddress,
          "map_embed_url": mapEmbedUrl,
        },
        "hours": {
          "mon_thu": hoursMonThu,
          "fri": hoursFri,
          "sat": hoursSat,
          "sun": hoursSun,
        },
        "delivery_charge": deliveryCharge,
      };
}
