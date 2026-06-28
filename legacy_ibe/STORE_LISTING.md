# Store listing & release prep — Islamabad Bullion Exchange

App ID / bundle ID (permanent): **`com.legacy.ibe`** · Display name: **Islamabad Bullion**
Backend: Laravel API at `https://islamabadbullionexchange.com/api` (release builds target this by default).
Privacy policy URL (both stores): **https://islamabadbullionexchange.com/privacy-policy**
Support email: thelegacyjewellers@gmail.com · Support phone: +92-340-2786222

---

## Listing copy (draft — edit freely)

**Title:** Islamabad Bullion Exchange

**Short description (Play, ≤80 chars):**
Live gold & silver rates, products, and verification from Islamabad Bullion.

**Full description:**
Islamabad Bullion Exchange brings live gold and silver rates straight to your
phone. Track 24K/22K/21K/18K gold and silver across grams, tola and kilo, see
international spot prices, and follow the market with a clean, real-time board.

Features:
• Live gold & silver rates (per tola, gram, 10g, kg) with international USD/oz spot
• Buy and Sell requests — pick metal, karat and quantity, get an instant price
• Product catalogue — bars and coins with order + payment-proof upload
• Authenticity check — scan the QR code or enter the serial on your item
• Zakat calculator based on current rates
• English & Urdu, with a premium dark interface
• Contact, business hours and directions to our shop

Rates and content are managed by Islamabad Bullion Exchange and update
automatically. This app does not process payments inside the app and does not
require an account.

**Category:** Finance (alt: Shopping) · **Content rating:** Everyone / 4+
**Keywords (Apple):** gold, silver, rate, bullion, Pakistan, Islamabad, tola, zakat, prices, exchange

---

## Permissions & why
| Permission | Used for |
|---|---|
| Internet | Fetch live rates and content from the website API |
| Camera | Scan the QR code on an item to verify authenticity |
| Photos / Photo library | Attach a payment-proof screenshot to an order |

iOS usage strings are set in `ios/Runner/Info.plist` (NSCamera / NSPhotoLibrary…).
Android camera permission is contributed by the scanner/image-picker plugins via manifest merge.

---

## Google Play — Data safety form
- **Account required:** No (guest-only app).
- **Data collected:**
  - *Name* and *Phone number* — when the user places a buy/sell/product order or sends a contact message. Purpose: App functionality (order fulfilment / support). Not shared with third parties. Not used for tracking.
  - *Photos* — only the payment-proof image the user chooses to upload. Purpose: App functionality. Not shared. Not used for tracking.
- **Data NOT collected:** location, contacts, financial account info, identifiers/ads.
- **Encryption in transit:** Yes (HTTPS). **Data deletion:** users can request via the support email.

## Apple — App Privacy (Nutrition labels)
- **Contact Info → Name, Phone Number:** linked to a transaction, not to identity; used for App Functionality; not used for tracking.
- **User Content → Photos:** payment proof; App Functionality; not tracking.
- **No tracking, no ads, no third-party SDKs collecting data.**

---

## Assets still needed (you/designer)
- **App icon:** 512×512 (Play) — already have launcher icon source; 1024×1024 (App Store).
- **Feature graphic:** 1024×500 (Play).
- **Screenshots:**
  - Play: 2–8 phone screenshots (e.g. 1080×2400 — Spot, Buy, Sell, Products, Verify).
  - App Store: 6.7" (1290×2796) and 6.5" (1242×2688) iPhone sets; iPad if you support it.
  - I can capture these from the emulator/simulator once we do a release run.

## Build commands
IMPORTANT: always pass `--no-tree-shake-icons`. The app uses font_awesome_flutter
(the WhatsApp bottom-nav icon), which is incompatible with Flutter's release
icon tree-shaker — the build FAILS during AOT without this flag.
- Android (Play): `flutter build appbundle --release --no-tree-shake-icons`  → `build/app/outputs/bundle/release/app-release.aab`
- Android (sideload): `flutter build apk --release --no-tree-shake-icons`
- iOS (needs Xcode + Apple account): `flutter build ipa --no-tree-shake-icons` then upload via Transporter/Xcode.
(Do NOT pass `--dart-define=API_BASE=…` for release — the default already points at the live API.)

## Review notes
- Guest-only (no login) → simpler review.
- "Buy/Sell" are **order requests fulfilled offline** (contact/bank transfer), not in-app
  financial transactions; physical goods are exempt from Apple in-app purchase.
- Target SDK / min SDK come from the Flutter toolchain (kept current automatically).
