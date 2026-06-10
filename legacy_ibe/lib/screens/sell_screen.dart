import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/prices_provider.dart";
import "../providers/app_settings.dart";
import "../models/metal_price.dart";
import "../widgets/animated_price_text.dart";
import "../widgets/currency_utils.dart";
import "../l10n/app_localizations.dart";
import "../utils/time_utils.dart";
import "../widgets/error_view.dart";

// Gold unit choices (keep gold logic same)
enum SellUnit { gram, tola }

// Silver fixed-quantity chips
enum SilverQty {
  gram1,
  gram10,
  tola1,
  tola5,
  tola10,
  tola10Qr,
  kg1,
}

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  int _step = 0;

  // Metals
  String? _metalCode; // XAU, XAG
  String? _goldKarat; // 24K, 22K, 21K, 18K (only for XAU)

  // GOLD only
  SellUnit _unit = SellUnit.gram;

  final TextEditingController _weightCtrl = TextEditingController(text: "");
  double _weight = 0.0;

  // SILVER only
  SilverQty _silverQty = SilverQty.gram1;

  // Conversion constants
  static const double _gramsPerTola = 11.6638038;

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  String _t(AppSettings s, String en, String ur) => s.isUrdu ? ur : en;

  String _metalName(AppSettings s, String code) {
    switch (code) {
      case "XAU":
        return _t(s, "Gold", "سونا");
      case "XAG":
        return _t(s, "Silver", "چاندی");
      default:
        return code;
    }
  }

  String _unitLabel(AppLocalizations loc, SellUnit u) {
    switch (u) {
      case SellUnit.gram:
        return loc.t("gram");
      case SellUnit.tola:
        return loc.t("tola");
    }
  }

  MetalPrice? _findMetal(List<MetalPrice> list, String code) {
    for (final m in list) {
      if (m.code == code) return m;
    }
    return null;
  }

  void _setMetal(String code) {
    setState(() {
      _metalCode = code;

      if (code == "XAU") {
        _goldKarat ??= "24K";
      } else {
        _goldKarat = null;
        _silverQty = SilverQty.gram1;
      }
    });
  }

  bool get _isGold => _metalCode == "XAU";
  bool get _isSilver => _metalCode == "XAG";

  bool get _canContinueStep1 {
    if (_metalCode == null) return false;
    if (_isGold && (_goldKarat == null || _goldKarat!.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  void _next() {
    if (_step == 0) {
      if (!_canContinueStep1) return;
      setState(() => _step = 1);
    }
  }

  void _back() {
    if (_step == 1) setState(() => _step = 0);
  }

  void _parseWeight(String v) {
    final cleaned = v.replaceAll(",", ".").trim();
    final d = double.tryParse(cleaned);
    setState(() => _weight = (d == null || d.isNaN || d.isInfinite) ? 0.0 : d);
  }

  double _silverQtyGrams(SilverQty q) {
    switch (q) {
      case SilverQty.gram1:
        return 1.0;
      case SilverQty.gram10:
        return 10.0;
      case SilverQty.tola1:
        return _gramsPerTola;
      case SilverQty.tola5:
        return _gramsPerTola * 5.0;
      case SilverQty.tola10:
        return _gramsPerTola * 10.0;
      case SilverQty.tola10Qr:
        return _gramsPerTola * 10.0;
      case SilverQty.kg1:
        return 1000.0;
    }
  }

  List<String> _silverQtyKeys(SilverQty q) {
    switch (q) {
      case SilverQty.gram1:
        return const ["Gram"];
      case SilverQty.gram10:
        return const ["10 Gram"];
      case SilverQty.tola1:
        return const ["Tola"];
      case SilverQty.tola5:
        return const ["5 Tola"];
      case SilverQty.tola10:
        return const ["10 Tola"];
      case SilverQty.tola10Qr:
        return const ["10 Tola (QR Packaging)", "10 Tola"];
      case SilverQty.kg1:
        return const ["1 KG"];
    }
  }

  String _silverQtyTitle(AppSettings s, SilverQty q) {
    final isUr = s.isUrdu;
    switch (q) {
      case SilverQty.gram1:
        return isUr ? "1 گرام" : "1 Gram";
      case SilverQty.gram10:
        return isUr ? "10 گرام" : "10 Gram";
      case SilverQty.tola1:
        return isUr ? "1 تولہ" : "1 Tola";
      case SilverQty.tola5:
        return isUr ? "5 تولہ" : "5 Tola";
      case SilverQty.tola10:
        return isUr ? "10 تولہ" : "10 Tola";
      case SilverQty.tola10Qr:
        return isUr ? "10 تولہ" : "10 Tola";
      case SilverQty.kg1:
        return isUr ? "1 کلو" : "1 KG";
    }
  }

  String? _silverQtySubtitle(AppSettings s, SilverQty q) {
    final isUr = s.isUrdu;
    switch (q) {
      case SilverQty.tola10Qr:
        return isUr ? "(QR پیکیجنگ)" : "(QR Packaging)";
      default:
        return null;
    }
  }

  Map<String, double> _safeSilverMapSell(dynamic metal) {
    try {
      final m = (metal as dynamic).silverQtySell;
      if (m is Map) {
        return m.map(
              (k, v) => MapEntry(
            k.toString(),
            (v is num) ? v.toDouble() : 0.0,
          ),
        );
      }
    } catch (_) {}
    return const {};
  }

  double _sellUnitPriceGold(MetalPrice metal) {
    final perGram = (() {
      final k = _goldKarat;
      if (k != null) {
        final v = metal.goldKaratSell[k];
        if (v != null && v > 0) return v;
      }
      return metal.sell.perGram;
    })();

    switch (_unit) {
      case SellUnit.gram:
        return perGram;
      case SellUnit.tola:
        return perGram * _gramsPerTola;
    }
  }

  double _sellPriceSilverQty(MetalPrice metal, SilverQty q) {
    final map = _safeSilverMapSell(metal);

    for (final key in _silverQtyKeys(q)) {
      final override = map[key];
      if (override != null && override > 0) return override;
    }

    return metal.sell.perGram * _silverQtyGrams(q);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final prices = context.watch<PricesProvider>();
    final loc = AppLocalizations.of(context);

    if (prices.isLoading) {
      return Container(
        color: _bg,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (prices.latest == null && prices.error != null) {
      return Container(
        color: _bg,
        child: ErrorView(message: prices.error!, onRetry: () => prices.refresh()),
      );
    }

    final latest = prices.latest;
    if (latest == null) {
      return Container(
        color: _bg,
        child: ErrorView(message: loc.t("no_data_yet"), onRetry: () => prices.refresh()),
      );
    }

    final sym = currencySymbol(latest.currency);
    final updatedPkt = formatPakistanTime(latest.timestamp, settings.locale);

    final selectedMetal = _metalCode == null ? null : _findMetal(latest.metals, _metalCode!);

    final unitSell = (selectedMetal == null)
        ? 0.0
        : _isGold
        ? _sellUnitPriceGold(selectedMetal)
        : _sellPriceSilverQty(selectedMetal, _silverQty);

    final totalSell = (selectedMetal == null)
        ? 0.0
        : _isGold
        ? unitSell * (_weight <= 0 ? 0.0 : _weight)
        : unitSell;

    return Container(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        children: [
          Card(
            color: _card,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _t(
                        settings,
                        "Sell • Updated (PKT): $updatedPkt",
                        "سیل • اپڈیٹ (پاکستان وقت): $updatedPkt",
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Text(
                      latest.currency,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: _card,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(settings, "Easy Steps", "آسان مراحل"),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: _accent,
                        secondary: Colors.grey,
                      ),
                    ),
                    child: Stepper(
                      currentStep: _step,
                      physics: const NeverScrollableScrollPhysics(),
                      controlsBuilder: (context, details) {
                        if (_step == 0) {
                          return Row(
                            children: [
                              _CustomOutlinedButton(
                                onPressed: _canContinueStep1 ? _next : null,
                                text: _t(settings, "Continue", "اگلا"),
                                isEnabled: _canContinueStep1,
                                accentColor: _accent,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            _CustomOutlinedButton(
                              onPressed: _back,
                              text: _t(settings, "Back", "واپس"),
                              isEnabled: true,
                              accentColor: _accent,
                            ),
                          ],
                        );
                      },
                      steps: [
                        Step(
                          title: Text(
                            _t(settings, "Step 1: Choose metal", "مرحلہ 1: دھات منتخب کریں"),
                            style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            _t(settings, "Gold, Silver", "سونا، چاندی"),
                            style: TextStyle(color: _accent.withOpacity(0.75)),
                          ),
                          isActive: _step == 0,
                          state: _step > 0 ? StepState.complete : StepState.indexed,
                          content: _step1(context, settings),
                        ),
                        Step(
                          title: Text(
                            _t(settings, "Step 2: Quantity", "مرحلہ 2: مقدار"),
                            style: TextStyle(
                              color: _step == 1 ? _accent : Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            _t(settings, "See SELL price instantly", "فوراً سیل قیمت دیکھیں"),
                            style: TextStyle(color: _accent.withOpacity(0.75)),
                          ),
                          isActive: _step == 1,
                          state: _step == 1 ? StepState.indexed : StepState.disabled,
                          content: _step2(
                            context,
                            settings,
                            loc,
                            sym: sym,
                            selectedMetal: selectedMetal,
                            unitSell: unitSell,
                            totalSell: totalSell,
                            updatedPkt: updatedPkt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step1(BuildContext context, AppSettings settings) {
    Widget metalCard({required String code, required IconData icon}) {
      final selected = _metalCode == code;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _setMetal(code),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _accent : Colors.white.withOpacity(0.35),
                width: selected ? 2 : 1,
              ),
              color: selected ? _accent : Colors.transparent,
            ),
            child: Column(
              children: [
                Icon(icon, size: 30, color: selected ? Colors.black : Colors.white),
                const SizedBox(height: 8),
                Text(
                  _metalName(settings, code),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            metalCard(code: "XAU", icon: Icons.workspace_premium),
            const SizedBox(width: 10),
            metalCard(code: "XAG", icon: Icons.blur_circular),
          ],
        ),
        if (_isGold) ...[
          const SizedBox(height: 14),
          Text(
            _t(settings, "Gold category", "سونے کی کیٹیگری"),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChoiceChip(
                label: "24K",
                selected: _goldKarat == "24K",
                onTap: () => setState(() => _goldKarat = "24K"),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: "22K",
                selected: _goldKarat == "22K",
                onTap: () => setState(() => _goldKarat = "22K"),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: "21K",
                selected: _goldKarat == "21K",
                onTap: () => setState(() => _goldKarat = "21K"),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: "18K",
                selected: _goldKarat == "18K",
                onTap: () => setState(() => _goldKarat = "18K"),
                accentColor: _accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              settings,
              "Gold category pricing uses SELL per gram and converts to selected unit.",
              "گولڈ کیٹیگری قیمت SELL فی گرام سے لی جاتی ہے اور منتخب یونٹ میں کنورٹ ہوتی ہے۔",
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _accent.withOpacity(0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _step2(
      BuildContext context,
      AppSettings settings,
      AppLocalizations loc, {
        required String sym,
        required MetalPrice? selectedMetal,
        required double unitSell,
        required double totalSell,
        required String updatedPkt,
      }) {
    if (!_canContinueStep1 || selectedMetal == null) {
      return Text(
        _t(settings, "Please complete Step 1 first.", "براہ کرم پہلے مرحلہ 1 مکمل کریں۔"),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _accent),
      );
    }

    final metalTitle = _isGold
        ? "${_metalName(settings, "XAU")} (${_goldKarat ?? ""})"
        : _metalName(settings, selectedMetal.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Text(
            _t(settings, "Selected: $metalTitle", "منتخب: $metalTitle"),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (_isGold) ...[
          Text(
            _t(settings, "Unit", "یونٹ"),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChoiceChip(
                label: _unitLabel(loc, SellUnit.gram),
                selected: _unit == SellUnit.gram,
                onTap: () => setState(() => _unit = SellUnit.gram),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: _unitLabel(loc, SellUnit.tola),
                selected: _unit == SellUnit.tola,
                onTap: () => setState(() => _unit = SellUnit.tola),
                accentColor: _accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _t(settings, "How much do you want to sell?", "آپ کتنا بیچنا چاہتے ہیں؟"),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _parseWeight,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _t(
                settings,
                "Enter weight in ${_unitLabel(loc, _unit)}",
                "${_unitLabel(loc, _unit)} میں وزن درج کریں",
              ),
              hintStyle: TextStyle(color: _accent.withOpacity(0.75)),
              prefixIcon: Icon(Icons.scale_outlined, color: _accent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accent.withOpacity(0.55)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accent.withOpacity(0.55)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accent),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ] else if (_isSilver) ...[
          Text(
            _t(settings, "Silver categories", "چاندی کی کیٹیگریز"),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChoiceChip(
                label: _silverQtyTitle(settings, SilverQty.kg1),
                selected: _silverQty == SilverQty.kg1,
                onTap: () => setState(() => _silverQty = SilverQty.kg1),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: _silverQtyTitle(settings, SilverQty.tola10),
                subtitle: '(999)',
                selected: _silverQty == SilverQty.tola10,
                onTap: () => setState(() => _silverQty = SilverQty.tola10),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: _silverQtyTitle(settings, SilverQty.tola10Qr),
                subtitle: _silverQtySubtitle(settings, SilverQty.tola10Qr),
                selected: _silverQty == SilverQty.tola10Qr,
                onTap: () => setState(() => _silverQty = SilverQty.tola10Qr),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: _silverQtyTitle(settings, SilverQty.tola5),
                selected: _silverQty == SilverQty.tola5,
                onTap: () => setState(() => _silverQty = SilverQty.tola5),
                accentColor: _accent,
              ),
              _ChoiceChip(
                label: _silverQtyTitle(settings, SilverQty.tola1),
                selected: _silverQty == SilverQty.tola1,
                onTap: () => setState(() => _silverQty = SilverQty.tola1),
                accentColor: _accent,
              ),
              // _ChoiceChip(
              //   label: _silverQtyTitle(settings, SilverQty.gram10),
              //   selected: _silverQty == SilverQty.gram10,
              //   onTap: () => setState(() => _silverQty = SilverQty.gram10),
              //   accentColor: _accent,
              // ),
              // _ChoiceChip(
              //   label: _silverQtyTitle(settings, SilverQty.gram1),
              //   selected: _silverQty == SilverQty.gram1,
              //   onTap: () => setState(() => _silverQty = SilverQty.gram1),
              //   accentColor: _accent,
              // ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        Card(
          color: _card,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(settings, "SELL Price", "سیل قیمت"),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 10),
                _priceLine(
                  context,
                  label: _t(settings, "Unit price", "یونٹ قیمت"),
                  value: unitSell,
                  sym: sym,
                ),
                const SizedBox(height: 8),
                _priceLine(
                  context,
                  label: _t(settings, "Total", "کل"),
                  value: totalSell,
                  sym: sym,
                  strong: true,
                ),
                const SizedBox(height: 10),
                Text(
                  _t(settings, "Updated (PKT): $updatedPkt", "اپڈیٹ (پاکستان وقت): $updatedPkt"),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _accent.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isGold) ...[
          const SizedBox(height: 14),
          Text(
            _t(
              settings,
              "a) making charges will be deducted on jewellery bought from us in case of return after 15 days.\nb) 15-20% deduction on jewellery bought from somewhere else, depending on the condition and purity of the jewellery (in case of selling)\nC) zero deduction on old jewellery exchange with us (after testing the purity and condition of the jewellery)",
              "ا) ہم سے خریدی گئی جیولری کی واپسی 15 دن کے بعد کی صورت میں میکنگ چارجز کٹے جائیں گے۔\nب) کہیں اور سے خریدی گئی جیولری پر 15-20% کٹوتی، جیولری کی حالت اور پاکیزگی پر منحصر (بیچنے کی صورت میں)\nج) ہمارے ساتھ پرانی جیولری کے تبادلے پر صفر کٹوتی (جیولری کی پاکیزگی اور حالت کی جانچ کے بعد)",
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _accent.withOpacity(0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _priceLine(
      BuildContext context, {
        required String label,
        required double value,
        required String sym,
        bool strong = false,
      }) {
    final style = (strong
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
      color: Colors.white,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AnimatedPriceText(
                value: value,
                currencyPrefix: sym,
                decimals: 2,
                style: style,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isEnabled;
  final Color accentColor;

  const _CustomOutlinedButton({
    required this.onPressed,
    required this.text,
    required this.isEnabled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isEnabled ? accentColor : accentColor.withOpacity(0.5),
        side: BorderSide(
          color: isEnabled ? accentColor : accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isEnabled ? accentColor : accentColor.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatefulWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _ChoiceChip({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<_ChoiceChip> createState() => _ChoiceChipState();
}

class _ChoiceChipState extends State<_ChoiceChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _isPressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? widget.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? widget.accentColor : widget.accentColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : widget.accentColor,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white.withOpacity(0.95)
                      : widget.accentColor.withOpacity(0.9),
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}