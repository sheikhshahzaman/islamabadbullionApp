# Islamabad Bullion Exchange — Mobile App

Flutter app for [Islamabad Bullion Exchange](https://islamabadbullionexchange.com), a gold and
silver dealer in Pakistan. It shows live and dealer-set metal rates, sells bullion products,
takes buy requests, and calculates Zakat.

- **Package / bundle id:** `com.legacy.ibe`
- **Current version:** `4.2.0+2407`
- **Platforms:** Android (live on Play Store) and iOS
- **Backend:** Laravel API at `islamabadbullionexchange.com` — separate private repository,
  ask the project owner for access

---

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.44.1 (stable) or newer |
| Dart SDK | `^3.9.2` (bundled with Flutter) |
| Android | Android Studio + SDK, JDK 17 |
| iOS | Xcode 15+, CocoaPods (macOS only) |

## Quick start

```bash
git clone https://github.com/sheikhshahzaman/islamabadbullionApp.git
cd islamabadbullionApp/legacy_ibe
flutter pub get
flutter run
```

That runs against the **live production API** by default. To point at a local Laravel backend:

```bash
# Android emulator (10.0.2.2 is the host machine from inside the emulator)
flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api

# iOS simulator / physical device on the same network
flutter run --dart-define=API_BASE=http://192.168.1.x:8000/api
```

`API_BASE` is the only build-time configuration. It is read in `lib/config.dart` and defaults to
`https://islamabadbullionexchange.com/api`.

## Backend endpoints

All of these are consumed relative to `API_BASE`:

| Endpoint | Used by |
|---|---|
| `GET /prices` | Metal rates (home, detail, buy/sell) |
| `GET /ticker` | Scrolling ticker and the headline slider |
| `GET /app-config` | Site config; also the connectivity probe |
| `GET /silver-note` | Silver availability note |
| `GET /pages/{slug}` | Legal / static pages |
| `GET /categories`, `GET /products` | Shop catalogue |
| `POST /orders`, `GET /orders/{orderNumber}` | Orders and tracking |
| `POST /orders/{orderNumber}/payment` | Payment proof upload |
| `POST /buy-sell-orders` | Buy/sell enquiries |
| `GET /buy-requests/options`, `POST /buy-requests/quote`, `POST /buy-requests` | Request to Buy |
| `POST /contact` | Contact form |
| `POST /verify` | Product QR verification |

## Project structure

```
lib/
├── config.dart          API base URL, refresh interval, default currency
├── main.dart            App entry, provider wiring, routes
├── models/              Plain data classes parsed from API JSON
├── providers/           State management (provider package)
├── screens/             One file per screen; shop/ holds the commerce flow
├── services/            HTTP layer — one client per API area
├── theme/               Colours, typography, brand constants
├── widgets/             Shared UI components
└── l10n/                Localisation strings
```

## Things worth knowing before you change anything

These are deliberate and easy to break:

**Prices always come from the server.** The app never calculates or sends a price. It sends a
selection (metal, category, size, weight) and the backend returns the amount. Do not move pricing
into the client — the dealer changes rates from the admin panel and they must be authoritative.

**Writes are never retried.** `ApiClient` retries `GET`/`HEAD` on timeouts and 5xx with backoff,
but never `POST`. A timed-out order POST may already have reached the server, so retrying would
create duplicate orders. `429` is never retried either and surfaces as `RateLimitedException`.

**Connectivity is judged by our own API,** not by the default foreign probe hosts, which time out
constantly on slow Pakistani connections and produced false "No Internet" errors. See
`services/connectivity_service.dart` — it needs three consecutive failures before it reports
offline, and any successful API call counts as proof of being online.

**Price fluctuation is cosmetic and bounded.** Dealer-set rates animate only the two digits
*before* the decimal point; international spot prices animate cents. Values below
`kLastTwoDigitsFloor` (1000) never animate, so small numbers like a USD/PKR rate stay put. The
logic is a pure function, `applyPriceFluctuation()` in `widgets/animated_price_text.dart`, and is
covered by tests.

**Order numbers** use the format `IBE-YYDDD-NNNNNNNN` (year, day-of-year, random serial). The
tracking field uppercases input and adds the `IBE-` prefix automatically.

**Checkout branches by payment method.** Cash (pickup) and COD (delivery) submit immediately with
no screenshot step. Bank transfer keeps the payment-proof step. The order is only recorded once
the customer completes submission.

**Product images use `ProductThumb`,** which requests the server's generated thumbnail and caches
it to disk. Do not swap it back to `Image.network` — that is memory-only, ignores HTTP cache
headers, and re-downloads several MB on every cold start.

## Tests

```bash
flutter test      # 16 tests
flutter analyze   # expect 0 errors; deprecation infos are known
```

## Release builds

Debug and profile builds need no extra setup. **Release signing does**, and the credentials are
deliberately not in this repository.

`android/key.properties` and the `.jks` keystore are gitignored. Without them the build still
succeeds — `android/app/build.gradle.kts` skips the signing config — but the APK is unsigned and
**cannot be uploaded to the Play Store**.

To produce an uploadable build:

1. Ask the project owner for the upload keystore and its passwords. They are shared through a
   secure channel, never committed, never sent over chat or email.
2. Put the keystore at `android/app/upload-keystore.jks`.
3. Copy `android/key.properties.example` to `android/key.properties` and fill in the real values.
4. Build:

```bash
flutter build appbundle --release   # .aab for Play Store
flutter build apk --release         # .apk for direct install / testing
```

> Never generate a new upload key. The Play Store listing is tied to the existing one, and
> replacing it requires an official key reset through Google.

For iOS, open `ios/Runner.xcworkspace` in Xcode and use a provisioning profile from the owner's
Apple Developer account.

Store copy and screenshots live in [`STORE_LISTING.md`](STORE_LISTING.md).
