import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "../config.dart";

enum PriceUnit { gram, tola, ounce }

class AppSettings extends ChangeNotifier {
  String _currency = AppConfig.defaultCurrency;
  PriceUnit _unit = PriceUnit.gram;

  Locale _locale = const Locale("en");

  // Currencies backed by exchange rates in the Laravel /api/prices response.
  List<String> get currencies => const ["PKR", "USD", "GBP", "EUR", "SAR", "AED"];

  String get currency => _currency;
  PriceUnit get unit => _unit;
  Locale get locale => _locale;

  bool get isUrdu => _locale.languageCode == "ur";

  void setCurrency(String c) {
    if (c == _currency) return;
    _currency = c;
    notifyListeners();
  }

  void setUnit(PriceUnit u) {
    if (u == _unit) return;
    _unit = u;
    notifyListeners();
  }

  void setLocale(Locale l) {
    if (l.languageCode == _locale.languageCode) return;
    _locale = Locale(l.languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    setLocale(isUrdu ? const Locale("en") : const Locale("ur"));
  }
}
