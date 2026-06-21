class AppConfig {
  // Laravel backend (islamabadbullionexchange.com). For local development
  // against `php artisan serve` run:
  //   flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api
  static const String apiBase = String.fromEnvironment(
    "API_BASE",
    defaultValue: "https://islamabadbullionexchange.com/api",
  );

  // How often the app refreshes UI data (backend updates every minute)
  static const int refreshSeconds = 60;

  // Default currency on first open
  static const String defaultCurrency = "PKR";
}
