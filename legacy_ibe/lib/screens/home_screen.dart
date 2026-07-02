// lib/screens/home_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../providers/app_settings.dart";
import "../providers/prices_provider.dart";
import "../providers/silver_note_provider.dart";
import "../widgets/error_view.dart";
import "../widgets/animated_price_text.dart";
import "../widgets/currency_utils.dart";
import "../widgets/brand_kit.dart";
import "../theme/brand.dart";
import "../l10n/app_localizations.dart";
import "../utils/time_utils.dart";
import "../models/metal_price.dart";

import "../widgets/headline_slider_card.dart";
import "more_screen.dart";
import "contact_us_screen.dart";
import "shop/products_screen.dart";
import "../providers/site_config_provider.dart";
import "dart:async";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart";

enum _GoldQty { gram1, gram5, gram10, tola1, tola10 }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  int _navIndex = 2;
  int _lastNonContactIndex = 2;

  _GoldQty _goldQty = _GoldQty.tola1;

  StreamSubscription<InternetStatus>? _internetSubscription;
  bool _isOfflineDialogOpen = false;
  bool _hasInternet = true;
  bool _internetChecked = false;

  @override
  void initState() {
    super.initState();
    _checkInitialInternet();
    _listenToInternetChanges();
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialInternet() async {
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!mounted) return;

    setState(() {
      _hasInternet = hasInternet;
      _internetChecked = true;
    });

    if (!hasInternet) {
      _showNoInternetDialog();
    }
  }

  void _listenToInternetChanges() {
    _internetSubscription =
        InternetConnection().onStatusChange.listen((InternetStatus status) {
          if (!mounted) return;

          final connected = status == InternetStatus.connected;
          final wasConnected = _hasInternet;

          setState(() {
            _hasInternet = connected;
            _internetChecked = true;
          });

          if (!connected) {
            _showNoInternetDialog();
            return;
          }

          _hideNoInternetDialog();

          // Show "restored" only when internet was previously OFF
          if (!wasConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.read<AppSettings>().isUrdu
                      ? "انٹرنیٹ کنکشن بحال ہو گیا ہے"
                      : "Internet connection restored",
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            context.read<PricesProvider>().refresh();
          }
        });
  }

  void _showNoInternetDialog() {
    if (_isOfflineDialogOpen || !mounted) return;

    setState(() => _isOfflineDialogOpen = true);

    final isUrdu = context.read<AppSettings>().isUrdu;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: _accent.withOpacity(0.35)),
            ),
            title: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: _accent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isUrdu ? "انٹرنیٹ دستیاب نہیں" : "No Internet Connection",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              isUrdu
                  ? "براہِ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔ کنکشن بحال ہوتے ہی ایپ دوبارہ صحیح کام کرے گی۔"
                  : "Please check your internet connection. The app will continue normally as soon as the connection is restored.",
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final hasInternet =
                  await InternetConnection().hasInternetAccess;
                  if (!mounted) return;

                  if (hasInternet) {
                    _hideNoInternetDialog();
                    context.read<PricesProvider>().refresh();
                  }
                },
                icon: Icon(Icons.refresh_rounded, color: _accent),
                label: Text(
                  isUrdu ? "دوبارہ چیک کریں" : "Try Again",
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() => _isOfflineDialogOpen = false);
    });
  }

  void _hideNoInternetDialog() {
    if (!_isOfflineDialogOpen || !mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (mounted) {
      setState(() => _isOfflineDialogOpen = false);
    }
  }

  MetalPrice? _findMetal(List<MetalPrice> list, String code) {
    for (final m in list) {
      if (m.code == code) return m;
    }
    return null;
  }

  String _liveLabel(AppSettings settings) => settings.isUrdu ? "لائیو" : "Live";

  String _navLabel(int i, bool isUrdu) {
    switch (i) {
      case 0:
        return isUrdu ? "ہم سے رابطہ" : "Contact Us";
      case 1:
        return isUrdu ? "شاپ" : "Shop";
      case 2:
        return isUrdu ? "اسپاٹ" : "Spot";
      case 3:
        return isUrdu ? "واٹس ایپ" : "WhatsApp";
      default:
        return isUrdu ? "مزید" : "More";
    }
  }

  Future<void> _openWhatsApp() async {
    final number = context
        .read<SiteConfigProvider>()
        .config
        .contactWhatsapp
        .replaceAll(RegExp(r"[^0-9]"), "");
    if (number.isEmpty) return;
    try {
      final ok = await launchUrl(
        Uri.parse("https://wa.me/$number"),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppSettings>().isUrdu
                ? "واٹس ایپ نہیں کھل سکا"
                : "Couldn't open WhatsApp"),
          ),
        );
      }
    } catch (_) {}
  }

  void _onBottomNavTap(int i) {
    // Contact (0) and Shop (1) open as pushed full screens; WhatsApp (3)
    // launches the WhatsApp app. None of these replace the persistent body
    // (Spot / More) — we restore it when a pushed screen is closed.
    if (i == 0 || i == 1) {
      setState(() {
        // Only remember a real persistent body (Spot / More), never another
        // pushed tab, so closing the pushed screen restores the right body.
        if (_navIndex == 2 || _navIndex == 4) _lastNonContactIndex = _navIndex;
        _navIndex = i;
      });

      final Widget screen =
          i == 0 ? const ContactUsScreen() : const ProductsScreen();

      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen))
          .then((result) {
        if (!mounted) return;
        // A pushed screen (e.g. Contact) can pop with a nav index when the user
        // taps its own bottom bar — honour that tap instead of just restoring.
        if (result is int && result != 0) {
          _onBottomNavTap(result);
        } else {
          setState(() => _navIndex = _lastNonContactIndex);
        }
      });
      return;
    }

    if (i == 3) {
      _openWhatsApp();
      // Keep the highlight on the visible body, not the WhatsApp tab.
      if (_navIndex != 2 && _navIndex != 4) {
        setState(() => _navIndex = _lastNonContactIndex);
      }
      return;
    }

    setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final prices = context.watch<PricesProvider>();
    final loc = AppLocalizations.of(context);

    // Spot (2) and More (4) are the persistent body tabs. Contact (0) and Shop
    // (1) are pushed screens; while one is open we keep the last body tab
    // underneath it.
    final bodyIndex =
        (_navIndex == 0 || _navIndex == 1) ? _lastNonContactIndex : _navIndex;
    final isSpot = bodyIndex == 2;
    final isMore = bodyIndex == 4;

    final usesPrices = isSpot;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        toolbarHeight: 80,
        leading: isSpot
            ? _SignalLanguageIcon(
          accentColor: _accent,
          sheetColor: _card,
          current: settings.locale,
          onSelected: settings.setLocale,
        )
            : null,
        title: isSpot
            ? Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 70,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'YOUR LOGO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        )
            : Text(
          _navLabel(bodyIndex, settings.isUrdu),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        actions: [
          if (usesPrices)
            _AppBarLiveIndicator(
              isPulsing: prices.error == null,
              accentColor: _accent,
              label: _liveLabel(settings),
            ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _navIndex,
        onTap: _onBottomNavTap,
        items: [
          BrandNavItem(
            icon: Icons.call_outlined,
            activeIcon: Icons.call,
            label: _navLabel(0, settings.isUrdu),
          ),
          BrandNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
            label: _navLabel(1, settings.isUrdu),
          ),
          BrandNavItem(
            icon: Icons.show_chart_rounded,
            activeIcon: Icons.insights_rounded,
            label: _navLabel(2, settings.isUrdu),
          ),
          BrandNavItem(
            icon: Icons.chat_outlined,
            activeIcon: Icons.chat,
            label: _navLabel(3, settings.isUrdu),
            customIcon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                gradient: Brand.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  size: 13, color: Brand.teal),
            ),
          ),
          BrandNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: _navLabel(4, settings.isUrdu),
          ),
        ],
      ),
      body: SafeArea(
        child: _isOfflineDialogOpen
            ? Container(
          color: _bg,
        )
            : AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSpot
              ? _SpotBody(
            key: const ValueKey("spot"),
            settings: settings,
            prices: prices,
            loc: loc,
            findMetal: _findMetal,
            liveLabel: _liveLabel,
            goldQty: _goldQty,
            onGoldQtyChanged: (q) => setState(() => _goldQty = q),
            accentColor: _accent,
            hasInternet: _hasInternet,
            internetChecked: _internetChecked,
          )
              : isMore
              ? const MoreScreen(key: ValueKey("more"))
              : _PlaceholderPage(
            key: ValueKey("page_$_navIndex"),
            title: _navLabel(_navIndex, settings.isUrdu),
            subtitle: settings.isUrdu
                ? "یہ سیکشن بعد میں مکمل کریں گے۔"
                : "This section will be completed next.",
            icon: Icons.contact_mail_outlined,
            background: _bg,
            cardColor: _card,
          ),
        ),
      ),
    );
  }
}

/* ------------------------- Signal Language Icon (Pulse Animation) ------------------------- */

class _SignalLanguageIcon extends StatefulWidget {
  final Color accentColor;
  final Color sheetColor;
  final Locale current;
  final ValueChanged<Locale> onSelected;

  const _SignalLanguageIcon({
    required this.accentColor,
    required this.sheetColor,
    required this.current,
    required this.onSelected,
  });

  @override
  State<_SignalLanguageIcon> createState() => _SignalLanguageIconState();
}

class _SignalLanguageIconState extends State<_SignalLanguageIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openLanguageSheet() async {
    final loc = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: widget.sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        Widget tile({
          required String code,
          required String title,
          required String subtitle,
        }) {
          final selected = widget.current.languageCode == code;
          return InkWell(
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelected(Locale(code));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(Icons.translate, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.t("language"),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white.withOpacity(0.06),
                  child: Column(
                    children: [
                      tile(
                        code: "en",
                        title: loc.t("english"),
                        subtitle: "English interface & labels",
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.22)),
                      tile(
                        code: "ur",
                        title: loc.t("urdu"),
                        subtitle: "اردو انٹرفیس اور لیبلز",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: IconButton(
              icon: Icon(Icons.language, color: widget.accentColor),
              onPressed: _openLanguageSheet,
            ),
          ),
        );
      },
    );
  }
}

/* ------------------------- AppBar Live Indicator ------------------------- */

class _AppBarLiveIndicator extends StatelessWidget {
  final bool isPulsing;
  final Color accentColor;
  final String label;

  const _AppBarLiveIndicator({
    required this.isPulsing,
    required this.accentColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LiveDot(isPulsing: isPulsing, accentColor: accentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- Live Dot (with pulse) ------------------------- */

class _LiveDot extends StatefulWidget {
  final bool isPulsing;
  final Color accentColor;

  const _LiveDot({required this.isPulsing, required this.accentColor});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPulsing != widget.isPulsing) {
      if (widget.isPulsing) {
        _controller.reset();
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.isPulsing ? Colors.green : widget.accentColor,
        shape: BoxShape.circle,
      ),
    );

    if (!widget.isPulsing) return dot;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: dot),
    );
  }
}

/* ------------------------- Spot body (removed logo, added announcement at top) ------------------------- */

class _SpotBody extends StatelessWidget {
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);

  final AppSettings settings;
  final PricesProvider prices;
  final AppLocalizations loc;
  final bool hasInternet;
  final bool internetChecked;

  final MetalPrice? Function(List<MetalPrice> list, String code) findMetal;
  final String Function(AppSettings settings) liveLabel;

  final _GoldQty goldQty;
  final ValueChanged<_GoldQty> onGoldQtyChanged;

  final Color accentColor;

  const _SpotBody({
    super.key,
    required this.settings,
    required this.prices,
    required this.loc,
    required this.findMetal,
    required this.liveLabel,
    required this.goldQty,
    required this.onGoldQtyChanged,
    required this.accentColor,
    required this.hasInternet,
    required this.internetChecked,
  });

  @override
  Widget build(BuildContext context) {
    if (!internetChecked && prices.latest == null) {
      return _PremiumHomeLoading(
        accentColor: accentColor,
        isUrdu: settings.isUrdu,
      );
    }

    if (!hasInternet && prices.latest == null) {
      return Container(
        color: _bg,
        child: ErrorView(
          isOffline: true,
          onRetry: () async {
            final hasInternet = await InternetConnection().hasInternetAccess;
            if (hasInternet) {
              prices.refresh();
            }
          },
        ),
      );
    }

    if (prices.isLoading) {
      return _PremiumHomeLoading(
        accentColor: accentColor,
        isUrdu: settings.isUrdu,
      );
    }

    if (prices.latest == null && prices.error != null) {
      return Container(
        color: _bg,
        child: ErrorView(
          message: prices.error!,
          onRetry: () => prices.refresh(),
        ),
      );
    }

    final latest = prices.latest;
    if (latest == null) {
      return Container(
        color: _bg,
        child: ErrorView(
          message: loc.t("no_data_yet"),
          onRetry: () => prices.refresh(),
        ),
      );
    }

    final sym = currencySymbol(latest.currency);
    final updatedPkt = formatPakistanTime(latest.timestamp, settings.locale);

    final gold = findMetal(latest.metals, "XAU");
    final silver = findMetal(latest.metals, "XAG");
    final silverNoteProvider = context.watch<SilverNoteProvider>();
    final silverNoteText = silverNoteProvider.note?.noteFor(settings.isUrdu) ?? "";

    // USD/oz international SPOT (live) — comes straight from the API, separate
    // from the admin-set local rates, so it matches the website's spot prices.
    final usdSym = currencySymbol("USD");
    final goldBidUsd = latest.spotGoldBid;
    final goldAskUsd = latest.spotGoldAsk;
    final silverBidUsd = latest.spotSilverBid;
    final silverAskUsd = latest.spotSilverAsk;

    return BrandBackground(
      child: RefreshIndicator(
      backgroundColor: _bg,
      color: Colors.white,
      onRefresh: () async {
        await Future.wait([
          prices.refresh(),
          context.read<SilverNoteProvider>().load(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        children: [
          HeadlineSliderCard(
            bg: _bg,
            card: _card,
            accent: accentColor,
          ),
          const SizedBox(height: 14),

          const SizedBox(height: 8),
          _TableCard(
            accentColor: accentColor,
            child: _UsdOunceBidAskTable(
              isUrdu: settings.isUrdu,
              symUsd: usdSym,
              accentColor: accentColor,
              goldBidUsd: goldBidUsd,
              goldAskUsd: goldAskUsd,
              silverBidUsd: silverBidUsd,
              silverAskUsd: silverAskUsd,
              showUnavailableNote: (goldBidUsd == null &&
                  goldAskUsd == null &&
                  silverBidUsd == null &&
                  silverAskUsd == null),
              updatedTime: updatedPkt,
            ),
          ).entrance(delayMs: 80),

          const SizedBox(height: 14),

          _SectionTitle(title: "Gold (XAU)", accentColor: accentColor),
          const SizedBox(height: 8),
          _TableCard(
            accentColor: accentColor,
            child: _GoldTablePro(
              loc: loc,
              isUrdu: settings.isUrdu,
              sym: sym,
              qty: goldQty,
              onQtyChanged: onGoldQtyChanged,
              gold: gold,
              onOpenDetails: null,
              accentColor: accentColor,
              updatedTime: updatedPkt,
            ),
          ).entrance(delayMs: 160),

          const SizedBox(height: 14),

          _SectionTitle(title: "Silver (XAG)", accentColor: accentColor),
          const SizedBox(height: 8),
          _TableCard(
            accentColor: accentColor,
            child: _SilverTablePro(
              loc: loc,
              isUrdu: settings.isUrdu,
              sym: sym,
              silver: silver,
              onOpenDetails: null,
              accentColor: accentColor,
              updatedTime: updatedPkt,
            ),
          ).entrance(delayMs: 240),

          if (silverNoteText.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _AppSignatureCard(
              text: silverNoteText.trim(),
              isUrdu: settings.isUrdu,
              accentColor: accentColor,
            ).entrance(delayMs: 300),
          ],
        ],
      ),
    ),
    );
  }
}

/* ------------------------- USD Source resolver ------------------------- */

class _UsdSource {
  final String currentCurrency;
  final bool isDirectUsd;
  final List<MetalPrice>? usdMetals;
  final dynamic latestDyn;

  _UsdSource._({
    required this.currentCurrency,
    required this.isDirectUsd,
    required this.usdMetals,
    required this.latestDyn,
  });

  static _UsdSource from({
    required PricesProvider prices,
    required dynamic latest,
  }) {
    dynamic usdLatest;
    try {
      usdLatest = (prices as dynamic).latestUsd;
    } catch (_) {}
    try {
      usdLatest ??= (prices as dynamic).usdLatest;
    } catch (_) {}
    try {
      usdLatest ??= (prices as dynamic).latestUSD;
    } catch (_) {}

    List<MetalPrice>? usdMetals;
    bool directUsd = false;

    if (usdLatest != null) {
      try {
        final c = (usdLatest as dynamic).currency;
        final metalsAny = (usdLatest as dynamic).metals;

        if (c is String && c.toUpperCase() == "USD" && metalsAny is List) {
          usdMetals = metalsAny.cast<MetalPrice>();
          directUsd = true;
        }
      } catch (_) {}
    }

    final cur = (latest as dynamic).currency as String? ?? "USD";
    if (!directUsd && cur.toUpperCase() == "USD") {
      try {
        final metalsAny = (latest as dynamic).metals;
        if (metalsAny is List) {
          usdMetals = metalsAny.cast<MetalPrice>();
          directUsd = true;
        }
      } catch (_) {}
    }

    return _UsdSource._(
      currentCurrency: cur,
      isDirectUsd: directUsd,
      usdMetals: usdMetals,
      latestDyn: latest,
    );
  }

  MetalPrice? directMetalFor(String code, {required MetalPrice? fallback}) {
    if (!isDirectUsd || usdMetals == null) return fallback;
    for (final m in usdMetals!) {
      if (m.code == code) return m;
    }
    return fallback;
  }

  double? toUsdOrNull(double value) {
    if (isDirectUsd) return value;

    final cur = currentCurrency.toUpperCase();
    if (cur == "USD") return value;

    try {
      final dyn = latestDyn;
      final base = (dyn.base ??
          dyn.baseCurrency ??
          dyn.baseCode ??
          dyn.base_code ??
          dyn.base_code) as String?;
      final rates =
      (dyn.rates ?? dyn.fxRates ?? dyn.currencyRates ?? dyn.fx ?? dyn.conversionRates);

      if (rates is Map) {
        if (base != null && base.toUpperCase() == "USD") {
          final r = rates[cur];
          if (r is num) {
            final rr = r.toDouble();
            if (rr > 0) return value / rr;
          }
        }

        if (base != null && base.toUpperCase() == cur) {
          final r = rates["USD"];
          if (r is num) {
            final rr = r.toDouble();
            if (rr > 0) return value * rr;
          }
        }
      }
    } catch (_) {}

    return null;
  }
}

/* ------------------------- USD ounce BID/ASK table ------------------------- */

class _UsdOunceBidAskTable extends StatelessWidget {
  final bool isUrdu;
  final String symUsd;
  final Color accentColor;

  final double? goldBidUsd;
  final double? goldAskUsd;
  final double? silverBidUsd;
  final double? silverAskUsd;

  final bool showUnavailableNote;
  final String updatedTime;

  const _UsdOunceBidAskTable({
    required this.isUrdu,
    required this.symUsd,
    required this.accentColor,
    required this.goldBidUsd,
    required this.goldAskUsd,
    required this.silverBidUsd,
    required this.silverAskUsd,
    required this.showUnavailableNote,
    required this.updatedTime,
  });

  String _t(String en, String ur) => isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    final divider = accentColor.withOpacity(0.35);

    TextStyle headStyle() =>
        Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: accentColor,
        ) ??
            TextStyle(fontWeight: FontWeight.w900, color: accentColor);

    Widget priceCell(double? v) {
      if (v == null) {
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            "—",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }

      return Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: AnimatedPriceText(
            value: v,
            currencyPrefix: symUsd,
            decimals: 2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    Widget row({
      required String title,
      required double? bid,
      required double? ask,
    }) {
      final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: accentColor,
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(title,
                  style: titleStyle, overflow: TextOverflow.ellipsis),
            ),
            Expanded(flex: 3, child: priceCell(bid)),
            Container(
              width: 1,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: divider,
            ),
            Expanded(flex: 3, child: priceCell(ask)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(_t("Metal (per oz)", "دھات (فی اونس)"),
                    style: headStyle()),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text("BID", style: headStyle()),
                ),
              ),
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: divider,
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text("ASK", style: headStyle()),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: accentColor.withOpacity(0.24)),
        row(
          title: _t("Gold (XAU)", "گولڈ (XAU)"),
          bid: goldBidUsd,
          ask: goldAskUsd,
        ),
        Divider(height: 1, color: accentColor.withOpacity(0.24)),
        row(
          title: _t("Silver (XAG)", "سلور (XAG)"),
          bid: silverBidUsd,
          ask: silverAskUsd,
        ),
        if (showUnavailableNote) ...[
          const SizedBox(height: 8),
          Text(
            _t(
              "USD ounce feed not available in this snapshot.",
              "اس اسنیپ شاٹ میں USD اونس ڈیٹا دستیاب نہیں۔",
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Divider(height: 1, color: accentColor.withOpacity(0.2)),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              _t("Updated: $updatedTime", "اپ ڈیٹ: $updatedTime"),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accentColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ------------------------- Placeholder page ------------------------- */

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color cardColor;

  const _PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 44, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------- Layout helpers ------------------------- */

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _SectionTitle({required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: Brand.goldGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Brand.display(19, weight: FontWeight.w700, color: accentColor),
        ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const _TableCard({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A3C30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withOpacity(0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: child,
      ),
    );
  }
}

/* ------------------------- Smaller chip widget (Gold only) ------------------------- */

class _SmallChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _SmallChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accentColor.withOpacity(selected ? 1.0 : 0.55),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? Colors.white : accentColor,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/* ------------------------- Pro table header + row (Buy | Sell) ------------------------- */

class _BuySellHeader extends StatelessWidget {
  final String leftTitle;
  final String buyLabel;
  final String sellLabel;
  final Color accentColor;

  const _BuySellHeader({
    required this.leftTitle,
    required this.buyLabel,
    required this.sellLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final divider = accentColor.withOpacity(0.35);
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: accentColor,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(leftTitle, style: textStyle)),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(buyLabel, style: textStyle),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: divider,
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(sellLabel, style: textStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuySellRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String sym;
  final double buy;
  final double sell;
  final bool showManualBadge;
  final String manualLabel;
  final VoidCallback? onTap;
  final Color accentColor;

  const _BuySellRow({
    required this.title,
    required this.subtitle,
    required this.sym,
    required this.buy,
    required this.sell,
    required this.showManualBadge,
    required this.manualLabel,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final divider = accentColor.withOpacity(0.35);

    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: accentColor,
    );

    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: accentColor.withOpacity(0.75),
      fontWeight: FontWeight.w700,
    );

    Widget price(double v) {
      return Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: AnimatedPriceText(
            value: v,
            currencyPrefix: sym,
            decimals: 2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: titleStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showManualBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: accentColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            manualLabel,
                            style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: subStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(flex: 3, child: price(buy)),
            Container(
              width: 1,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: divider,
            ),
            Expanded(flex: 3, child: price(sell)),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- GOLD table ------------------------- */

class _GoldTablePro extends StatelessWidget {
  final AppLocalizations loc;
  final bool isUrdu;
  final String sym;

  final _GoldQty qty;
  final ValueChanged<_GoldQty> onQtyChanged;

  final MetalPrice? gold;
  final VoidCallback? onOpenDetails;
  final Color accentColor;
  final String updatedTime;

  const _GoldTablePro({
    required this.loc,
    required this.isUrdu,
    required this.sym,
    required this.qty,
    required this.onQtyChanged,
    required this.gold,
    required this.onOpenDetails,
    required this.accentColor,
    required this.updatedTime,
  });

  static const double _gramsPerTola = 11.6638038;

  double _gramsFor(_GoldQty q) {
    switch (q) {
      case _GoldQty.gram1:
        return 1.0;
      case _GoldQty.gram5:
        return 5.0;
      case _GoldQty.gram10:
        return 10.0;
      case _GoldQty.tola1:
        return _gramsPerTola;
      case _GoldQty.tola10:
        return _gramsPerTola * 10.0;
    }
  }

  String _labelFor(_GoldQty q) {
    final en = () {
      switch (q) {
        case _GoldQty.gram1:
          return "1 Gram";
        case _GoldQty.gram5:
          return "5 Gram";
        case _GoldQty.gram10:
          return "10 Gram";
        case _GoldQty.tola1:
          return "1 Tola";
        case _GoldQty.tola10:
          return "10 Tola";
      }
    }();

    final ur = () {
      switch (q) {
        case _GoldQty.gram1:
          return "1 گرام";
        case _GoldQty.gram5:
          return "5 گرام";
        case _GoldQty.gram10:
          return "10 گرام";
        case _GoldQty.tola1:
          return "1 تولہ";
        case _GoldQty.tola10:
          return "10 تولہ";
      }
    }();

    return isUrdu ? ur : en;
  }

  double _scale(double perGram) => perGram * _gramsFor(qty);

  String _t(String en, String ur) => isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    if (gold == null) {
      return Text(
        _t("Gold data not available.", "گولڈ کا ڈیٹا دستیاب نہیں۔"),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accentColor),
      );
    }

    final g = gold!;

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SmallChoiceChip(
            label: _labelFor(_GoldQty.tola1),
            selected: qty == _GoldQty.tola1,
            onTap: () => onQtyChanged(_GoldQty.tola1),
            accentColor: accentColor,
          ),
          const SizedBox(width: 6),
          _SmallChoiceChip(
            label: _labelFor(_GoldQty.tola10),
            selected: qty == _GoldQty.tola10,
            onTap: () => onQtyChanged(_GoldQty.tola10),
            accentColor: accentColor,
          ),
          const SizedBox(width: 6),
          _SmallChoiceChip(
            label: _labelFor(_GoldQty.gram10),
            selected: qty == _GoldQty.gram10,
            onTap: () => onQtyChanged(_GoldQty.gram10),
            accentColor: accentColor,
          ),
          const SizedBox(width: 6),
          _SmallChoiceChip(
            label: _labelFor(_GoldQty.gram5),
            selected: qty == _GoldQty.gram5,
            onTap: () => onQtyChanged(_GoldQty.gram5),
            accentColor: accentColor,
          ),
          const SizedBox(width: 6),
          _SmallChoiceChip(
            label: _labelFor(_GoldQty.gram1),
            selected: qty == _GoldQty.gram1,
            onTap: () => onQtyChanged(_GoldQty.gram1),
            accentColor: accentColor,
          ),
        ],
      ),
    );

    final selectedLabel = _labelFor(qty);

    final List<_GoldRowSpec> rows = [];

    double buyForKarat(String karat) => g.goldKaratBuy[karat] ?? g.buy.perGram;
    double sellForKarat(String karat) =>
        g.goldKaratSell[karat] ?? g.sell.perGram;

    rows.add(_GoldRowSpec(
      title: "24K",
      buyPerGram: buyForKarat("24K"),
      sellPerGram: sellForKarat("24K"),
    ));

    final rawBuy =
        g.goldKaratBuy["Rawa"] ?? (g.goldKaratBuy["24K"] ?? g.buy.perGram);
    final rawSell =
        g.goldKaratSell["Rawa"] ?? (g.goldKaratSell["24K"] ?? g.sell.perGram);
    rows.add(_GoldRowSpec(
      title: _t("Rawa", "روا"),
      buyPerGram: rawBuy,
      sellPerGram: rawSell,
    ));

    rows.add(_GoldRowSpec(
      title: "22K",
      buyPerGram: buyForKarat("22K"),
      sellPerGram: sellForKarat("22K"),
    ));

    rows.add(_GoldRowSpec(
      title: "21K",
      buyPerGram: buyForKarat("21K"),
      sellPerGram: sellForKarat("21K"),
    ));

    rows.add(_GoldRowSpec(
      title: "18K",
      buyPerGram: buyForKarat("18K"),
      sellPerGram: sellForKarat("18K"),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips,
        const SizedBox(height: 10),
        _BuySellHeader(
          leftTitle: _t("Gold", "گولڈ"),
          buyLabel: loc.t("buy"),
          sellLabel: loc.t("sell"),
          accentColor: accentColor,
        ),
        Divider(height: 1, color: accentColor.withOpacity(0.24)),
        for (int i = 0; i < rows.length; i++) ...[
          _BuySellRow(
            title: rows[i].title,
            subtitle: selectedLabel,
            sym: sym,
            buy: _scale(rows[i].buyPerGram),
            sell: _scale(rows[i].sellPerGram),
            showManualBadge: false,
            manualLabel: loc.t("manual"),
            onTap: onOpenDetails,
            accentColor: accentColor,
          ),
          if (i != rows.length - 1)
            Divider(height: 1, color: accentColor.withOpacity(0.24)),
        ],
        if (g.isManual)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.20),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withOpacity(0.35)),
              ),
              child: Text(
                loc.t("manual"),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: accentColor),
              ),
            ),
          ),
        const SizedBox(height: 2),
        if (g.goldKaratSell.isNotEmpty || g.goldKaratBuy.isNotEmpty)
          Text(
            _t("Prices calculated for selected quantity", "قیمت منتخب مقدار کے مطابق"),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accentColor.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 10),
        Divider(height: 1, color: accentColor.withOpacity(0.2)),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              _t("Updated: $updatedTime", "اپ ڈیٹ: $updatedTime"),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accentColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldRowSpec {
  final String title;
  final double buyPerGram;
  final double sellPerGram;

  _GoldRowSpec({
    required this.title,
    required this.buyPerGram,
    required this.sellPerGram,
  });
}

/* ------------------------- SILVER table ------------------------- */

class _SilverTablePro extends StatelessWidget {
  final AppLocalizations loc;
  final bool isUrdu;
  final String sym;

  final MetalPrice? silver;
  final VoidCallback? onOpenDetails;
  final Color accentColor;
  final String updatedTime;

  const _SilverTablePro({
    required this.loc,
    required this.isUrdu,
    required this.sym,
    required this.silver,
    required this.onOpenDetails,
    required this.accentColor,
    required this.updatedTime,
  });

  static const double _gramsPerTola = 11.6638038;

  String _t(String en, String ur) => isUrdu ? ur : en;

  double _resolveSell(MetalPrice s, _QtySpec row) {
    for (final key in row.lookupKeys) {
      final value = s.silverQtySell[key];
      if (value != null) return value;
    }
    return s.sell.perGram * row.grams;
  }

  double _resolveBuy(MetalPrice s, _QtySpec row) {
    for (final key in row.lookupKeys) {
      final value = s.silverQtyBuy[key];
      if (value != null) return value;
    }
    return s.buy.perGram * row.grams;
  }

  @override
  Widget build(BuildContext context) {
    if (silver == null) {
      return Text(
        _t("Silver data not available.", "سلور کا ڈیٹا دستیاب نہیں۔"),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: accentColor,
        ),
      );
    }

    final s = silver!;

    final rows = <_QtySpec>[
      _QtySpec(
        key: "10 Tola (QR Packaging)",
        title: _t("10 Tola", "10 تولہ"),
        subtitle: _t("(QR Packaging)", "(QR پیکیجنگ)"),
        grams: _gramsPerTola * 10,
        fallbackKeys: const ["10 Tola"],
      ),
      _QtySpec(
        key: "10 Tola",
        title: _t("10 Tola", "10 تولہ"),
        subtitle: _t("(999)", "(999)"),
        grams: _gramsPerTola * 10,
      ),
      _QtySpec(
        key: "1 KG",
        title: _t("1 KG", "1 کلو"),
        grams: 1000,
      ),
      _QtySpec(
        key: "5 Tola",
        title: _t("5 Tola", "5 تولہ"),
        subtitle: _t("(Bar)", "(بار)"),
        grams: _gramsPerTola * 5,
      ),
      _QtySpec(
        key: "Tola",
        title: _t("1 Tola", "1 تولہ"),
        subtitle: _t("(Bar)", "(بار)"),
        grams: _gramsPerTola,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuySellHeader(
          leftTitle: _t("Silver", "سلور"),
          buyLabel: loc.t("buy"),
          sellLabel: loc.t("sell"),
          accentColor: accentColor,
        ),
        Divider(height: 1, color: accentColor.withOpacity(0.24)),
        for (int i = 0; i < rows.length; i++) ...[
          _BuySellRow(
            title: rows[i].title,
            subtitle: rows[i].subtitle,
            sym: sym,
            buy: _resolveBuy(s, rows[i]),
            sell: _resolveSell(s, rows[i]),
            showManualBadge: s.isManual,
            manualLabel: loc.t("manual"),
            onTap: onOpenDetails,
            accentColor: accentColor,
          ),
          if (i != rows.length - 1)
            Divider(height: 1, color: accentColor.withOpacity(0.24)),
        ],
        const SizedBox(height: 10),
        Divider(height: 1, color: accentColor.withOpacity(0.2)),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              _t("Updated: $updatedTime", "اپ ڈیٹ: $updatedTime"),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accentColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumHomeLoading extends StatefulWidget {
  final Color accentColor;
  final bool isUrdu;

  const _PremiumHomeLoading({
    required this.accentColor,
    required this.isUrdu,
  });

  @override
  State<_PremiumHomeLoading> createState() => _PremiumHomeLoadingState();
}

class _PremiumHomeLoadingState extends State<_PremiumHomeLoading>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title =>
      widget.isUrdu ? "تازہ قیمتیں لوڈ ہو رہی ہیں" : "Loading latest prices";

  String get _subtitle => widget.isUrdu
      ? "براہِ کرم انتظار کریں، تازہ ترین دھاتوں کی قیمتیں حاصل کی جا رہی ہیں۔"
      : "Please wait while the latest metal prices are being prepared.";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
        children: [
          const SizedBox(height: 4),
          Center(
            child: Column(
              children: [
                _AnimatedGlowBadge(
                  controller: _controller,
                  accentColor: widget.accentColor,
                ),
                const SizedBox(height: 14),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _LoadingCard(
            accentColor: widget.accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerLine(
                  controller: _controller,
                  widthFactor: 0.52,
                  height: 16,
                  radius: 10,
                ),
                const SizedBox(height: 14),
                _ShimmerLine(
                  controller: _controller,
                  widthFactor: 1,
                  height: 12,
                  radius: 8,
                ),
                const SizedBox(height: 10),
                _ShimmerLine(
                  controller: _controller,
                  widthFactor: 0.85,
                  height: 12,
                  radius: 8,
                ),
                const SizedBox(height: 10),
                _ShimmerLine(
                  controller: _controller,
                  widthFactor: 0.72,
                  height: 12,
                  radius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LoadingSectionTitle(
            title: widget.isUrdu ? "گولڈ (XAU)" : "Gold (XAU)",
            accentColor: widget.accentColor,
          ),
          const SizedBox(height: 8),
          _LoadingPriceTableCard(
            controller: _controller,
            accentColor: widget.accentColor,
          ),
          const SizedBox(height: 14),
          _LoadingSectionTitle(
            title: widget.isUrdu ? "سلور (XAG)" : "Silver (XAG)",
            accentColor: widget.accentColor,
          ),
          const SizedBox(height: 8),
          _LoadingPriceTableCard(
            controller: _controller,
            accentColor: widget.accentColor,
            rowCount: 5,
          ),
        ],
      ),
    );
  }
}

class _AnimatedGlowBadge extends StatelessWidget {
  final AnimationController controller;
  final Color accentColor;

  const _AnimatedGlowBadge({
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    final fade = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Transform.scale(
          scale: scale.value,
          child: Opacity(
            opacity: fade.value,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withOpacity(0.34),
                    accentColor.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: accentColor.withOpacity(0.55),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 22,
                    spreadRadius: 1,
                    color: accentColor.withOpacity(0.18),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_graph_rounded,
                color: accentColor,
                size: 34,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingSectionTitle extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _LoadingSectionTitle({
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: accentColor,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const _LoadingCard({
    required this.child,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A3C30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withOpacity(0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: child,
      ),
    );
  }
}

class _LoadingPriceTableCard extends StatelessWidget {
  final AnimationController controller;
  final Color accentColor;
  final int rowCount;

  const _LoadingPriceTableCard({
    required this.controller,
    required this.accentColor,
    this.rowCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return _LoadingCard(
      accentColor: accentColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _ShimmerLine(
                  controller: controller,
                  widthFactor: 0.62,
                  height: 13,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ShimmerLine(
                    controller: controller,
                    widthFactor: 0.7,
                    height: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ShimmerLine(
                    controller: controller,
                    widthFactor: 0.7,
                    height: 13,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 20, color: accentColor.withOpacity(0.20)),
          for (int i = 0; i < rowCount; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerLine(
                          controller: controller,
                          widthFactor: i.isEven ? 0.55 : 0.42,
                          height: 14,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerLine(
                          controller: controller,
                          widthFactor: i.isEven ? 0.36 : 0.28,
                          height: 11,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _ShimmerLine(
                        controller: controller,
                        widthFactor: 0.82,
                        height: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _ShimmerLine(
                        controller: controller,
                        widthFactor: 0.82,
                        height: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rowCount - 1)
              Divider(height: 18, color: accentColor.withOpacity(0.18)),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: accentColor.withOpacity(0.20)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _ShimmerLine(
              controller: controller,
              widthFactor: 0.34,
              height: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final AnimationController controller;
  final double widthFactor;
  final double height;
  final double radius;

  const _ShimmerLine({
    required this.controller,
    required this.widthFactor,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor.clamp(0.0, 1.0),
      alignment: Alignment.centerLeft,
      child: _ShimmerBox(
        controller: controller,
        height: height,
        radius: radius,
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final AnimationController controller;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.controller,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    const Color base = Color(0x1FFFFFFF);
    const Color highlight = Color(0x33DFA273);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + (controller.value * 2.4), 0),
              end: Alignment(-0.2 + (controller.value * 2.4), 0),
              colors: const [
                base,
                highlight,
                base,
              ],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
        );
      },
    );
  }
}

class _AppSignatureCard extends StatelessWidget {
  final String text;
  final bool isUrdu;
  final Color accentColor;

  const _AppSignatureCard({
    required this.text,
    required this.isUrdu,
    required this.accentColor,
  });

  String _label() => isUrdu ? "پاورڈ بائے" : "Powered by";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A3C30),
            Color(0xFF114B3E),
          ],
        ),
        border: Border.all(color: accentColor.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.14),
              border: Border.all(color: accentColor.withOpacity(0.35)),
            ),
            child: Icon(
              Icons.verified_outlined,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  _label(),
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accentColor.withOpacity(0.95),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtySpec {
  final String key;
  final String title;
  final String? subtitle;
  final double grams;
  final List<String> fallbackKeys;

  const _QtySpec({
    required this.key,
    required this.title,
    this.subtitle,
    required this.grams,
    this.fallbackKeys = const [],
  });

  List<String> get lookupKeys => [key, ...fallbackKeys];
}