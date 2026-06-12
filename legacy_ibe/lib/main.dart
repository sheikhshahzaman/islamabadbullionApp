import "package:flutter/material.dart";
import "package:legacy_ibe/providers/auth_provider.dart";
import "package:legacy_ibe/providers/headlines_provider.dart";
import "package:legacy_ibe/providers/silver_note_provider.dart";
import "package:provider/provider.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:intl/date_symbol_data_local.dart";

import "providers/app_settings.dart";
import "providers/cart_provider.dart";
import "providers/prices_provider.dart";
import "providers/shop_provider.dart";
import "screens/splash_screen.dart";
import "theme/app_theme.dart";
import "l10n/app_localizations.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // enables better Urdu date formatting where available
  runApp(const MetalPricesApp());
}

class MetalPricesApp extends StatelessWidget {
  const MetalPricesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => HeadlinesProvider()),
        ChangeNotifierProxyProvider<AppSettings, PricesProvider>(
          create: (_) => PricesProvider(),
          update: (_, settings, provider) => provider!..bindSettings(settings),
        ),
        ChangeNotifierProvider(
          create: (_) => SilverNoteProvider()..load(),
        ),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Islamabad Bullion",
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,

            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
