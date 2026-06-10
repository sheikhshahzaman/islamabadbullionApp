import "package:flutter/material.dart";

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale("en"),
    Locale("ur"),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocDelegate();

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return loc ?? AppLocalizations(const Locale("en"));
  }

  String get _lang => locale.languageCode;

  static const Map<String, Map<String, String>> _v = {
    "en": {
      "app_title": "Metal Prices",
      "currency": "Currency",
      "language": "Language",
      "english": "English",
      "urdu": "Urdu",
      "refresh": "Refresh",
      "loading": "Loading…",
      "offline": "Offline",
      "updated_pkt": "Updated (PKT): {time}",
      "mid": "Mid",
      "sell": "Sell",
      "buy": "Buy",
      "manual": "Manual",
      "gram": "Gram",
      "tola": "Tola",
      "ounce": "Ounce",
      "per_gram": "per gram",
      "per_tola": "per tola",
      "per_oz": "per oz",
      "gold_categories": "Gold Categories (per gram)",
      "could_not_load": "Could not load prices",
      "retry": "Retry",
      "no_data_yet": "No data yet.",
    },
    "ur": {
      "app_title": "دھاتوں کے ریٹس",
      "currency": "کرنسی",
      "language": "زبان",
      "english": "English",
      "urdu": "اردو",
      "refresh": "ریفریش",
      "loading": "لوڈ ہو رہا ہے…",
      "offline": "آف لائن",
      "updated_pkt": "آخری اپڈیٹ (پاکستان وقت): {time}",
      "mid": "درمیانی",
      "sell": "فروخت",
      "buy": "خرید",
      "manual": "مینول",
      "gram": "گرام",
      "tola": "تولہ",
      "ounce": "اونس",
      "per_gram": "فی گرام",
      "per_tola": "فی تولہ",
      "per_oz": "فی اونس",
      "gold_categories": "سونے کی اقسام (فی گرام)",
      "could_not_load": "قیمتیں لوڈ نہیں ہو سکیں",
      "retry": "دوبارہ کوشش",
      "no_data_yet": "ابھی ڈیٹا موجود نہیں۔",
    },
  };

  String t(String key) => _v[_lang]?[key] ?? _v["en"]![key] ?? key;

  String f(String key, Map<String, String> params) {
    var s = t(key);
    params.forEach((k, v) => s = s.replaceAll("{$k}", v));
    return s;
  }
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();

  @override
  bool isSupported(Locale locale) => ["en", "ur"].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
