// Headless smoke tests: build each redesigned screen with its real providers
// and assert it renders without throwing. Catches runtime build() crashes that
// `flutter analyze` cannot (bad casts, null derefs, layout errors), without
// needing an emulator. Network/prefs are stubbed; screens render their initial
// (loading / default) state.

import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:google_fonts/google_fonts.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:legacy_ibe/l10n/app_localizations.dart";
import "package:legacy_ibe/services/api_client.dart";
import "package:legacy_ibe/providers/app_settings.dart";
import "package:legacy_ibe/providers/cart_provider.dart";
import "package:legacy_ibe/providers/headlines_provider.dart";
import "package:legacy_ibe/providers/prices_provider.dart";
import "package:legacy_ibe/providers/shop_provider.dart";
import "package:legacy_ibe/providers/silver_note_provider.dart";
import "package:legacy_ibe/providers/site_config_provider.dart";
import "package:legacy_ibe/screens/buy_screen.dart";
import "package:legacy_ibe/screens/sell_screen.dart";
import "package:legacy_ibe/screens/more_screen.dart";
import "package:legacy_ibe/screens/contact_us_screen.dart";
import "package:legacy_ibe/screens/shop/products_screen.dart";

Widget _wrap(Widget screen, {required bool needsScaffold}) {
  final body = needsScaffold ? Scaffold(body: screen) : screen;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppSettings()),
      ChangeNotifierProvider(create: (_) => HeadlinesProvider()),
      ChangeNotifierProxyProvider<AppSettings, PricesProvider>(
        create: (_) => PricesProvider(),
        update: (_, settings, provider) => provider!..bindSettings(settings),
      ),
      ChangeNotifierProvider(create: (_) => SilverNoteProvider()),
      ChangeNotifierProvider(
        create: (_) => ShopProvider(
          client: ApiClient(
            client: MockClient(
              (_) async => http.Response('{"products":[],"categories":[]}', 200),
            ),
          ),
        ),
      ),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => SiteConfigProvider()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale("en"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: body,
    ),
  );
}

Future<void> _smoke(
  WidgetTester tester,
  Widget screen,
  Type screenType, {
  bool needsScaffold = false,
}) async {
  // Phone-sized viewport so phone layouts don't report false overflow errors.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(screen, needsScaffold: needsScaffold));
  await tester.pump(); // resolve localizations + first frame
  // Pump past all one-shot entrance-delay timers so none are pending at teardown.
  await tester.pump(const Duration(milliseconds: 900));

  expect(tester.takeException(), isNull);
  expect(find.byType(screenType), findsOneWidget);

  // Tear the tree down so providers dispose (cancels timers, closes http).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets("Buy screen builds without errors", (tester) async {
    await _smoke(tester, const BuyScreen(), BuyScreen, needsScaffold: true);
  });

  testWidgets("Sell screen builds without errors", (tester) async {
    await _smoke(tester, const SellScreen(), SellScreen, needsScaffold: true);
  });

  testWidgets("More screen builds without errors", (tester) async {
    await _smoke(tester, const MoreScreen(), MoreScreen);
  });

  testWidgets("Contact screen builds without errors", (tester) async {
    await _smoke(tester, const ContactUsScreen(), ContactUsScreen);
  });

  testWidgets("Products screen builds without errors", (tester) async {
    await _smoke(tester, const ProductsScreen(), ProductsScreen);
  });
}
