import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../models/metal_price.dart";
import "../models/metal_prices_response.dart";
import "../providers/prices_provider.dart";
import "../providers/site_config_provider.dart";
import "../theme/brand.dart";
import "../widgets/brand_kit.dart";

class BuyCalculatorScreen extends StatefulWidget {
  const BuyCalculatorScreen({super.key});

  @override
  State<BuyCalculatorScreen> createState() => _BuyCalculatorScreenState();
}

class _BuyCalculatorScreenState extends State<BuyCalculatorScreen> {
  static const double _gramsPerTola = 11.6638038;
  static const _fallbackGoldKarats = {
    "24k": "24K",
    "rawa": "Rawa",
    "22k": "22K",
    "21k": "21K",
    "18k": "18K",
  };
  static const _fallbackGoldUnits = [
    _CalculatorUnit("tola", "1 Tola"),
    _CalculatorUnit("gram", "1 Gram"),
    _CalculatorUnit("10_gram", "10 Gram"),
    _CalculatorUnit("kg", "1 KG"),
  ];
  static const _fallbackSilverUnits = [
    _CalculatorUnit("10_tola_qr", "10 Tola (QR Packaging)"),
    _CalculatorUnit("10_tola", "10 Tola (999)"),
    _CalculatorUnit("kg", "1 KG"),
    _CalculatorUnit("5_tola", "5 Tola (Bar)"),
    _CalculatorUnit("tola", "1 Tola (Bar)"),
  ];

  final _quantityCtrl = TextEditingController(text: "1");
  final _money = NumberFormat("#,##0.##");
  String _metal = "gold";
  String _karat = "24k";
  String _unit = "tola";
  bool _showResult = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PricesProvider>().refresh();
      context.read<SiteConfigProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  double get _quantity {
    final value = double.tryParse(_quantityCtrl.text.trim());
    if (value == null || value <= 0) return 0;
    return value;
  }

  Map<String, String> _goldKarats(PriceCatalog? catalog) {
    final karats = catalog?.goldKarats ?? const {};
    return karats.isEmpty ? _fallbackGoldKarats : karats;
  }

  List<_CalculatorUnit> _units(PriceCatalog? catalog) {
    final source = _metal == "silver"
        ? catalog?.silverUnits ?? const {}
        : catalog?.goldUnits ?? const {};

    if (source.isNotEmpty) {
      return [
        for (final entry in source.entries)
          _CalculatorUnit(entry.key, entry.value),
      ];
    }

    return _metal == "silver" ? _fallbackSilverUnits : _fallbackGoldUnits;
  }

  String _effectiveKarat(PriceCatalog? catalog) {
    final karats = _goldKarats(catalog);
    return karats.containsKey(_karat) ? _karat : karats.keys.first;
  }

  String _effectiveUnit(List<_CalculatorUnit> units) {
    return units.any((u) => u.key == _unit) ? _unit : units.first.key;
  }

  String _selectionLabel(PriceCatalog? catalog) {
    final units = _units(catalog);
    final unit = _effectiveUnit(units);
    final unitLabel = units.firstWhere((u) => u.key == unit).label;
    return _metal == "gold"
        ? "Gold ${_goldKarats(catalog)[_effectiveKarat(catalog)]} - $unitLabel"
        : "Silver - $unitLabel";
  }

  Future<void> _calculate() async {
    setState(() => _refreshing = true);
    await context.read<PricesProvider>().refresh();
    if (!mounted) return;
    setState(() {
      _showResult = true;
      _refreshing = false;
    });
  }

  Future<void> _openWhatsApp(String number, double total) async {
    final digits = number.replaceAll(RegExp(r"[^0-9]"), "");
    if (digits.isEmpty) return;
    final message = Uri.encodeComponent(
      "Hi, I calculated ${_selectionLabel(context.read<PricesProvider>().latest?.priceCatalog)} x ${_quantityCtrl.text.trim()} = Rs ${_money.format(total)}. I want to buy.",
    );
    await launchUrl(
      Uri.parse("https://wa.me/$digits?text=$message"),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callPhone(String number) async {
    final clean = number.replaceAll(RegExp(r"[^0-9+]"), "");
    if (clean.isEmpty) return;
    await launchUrl(Uri.parse("tel:$clean"));
  }

  MetalPrice? _findMetal(List<MetalPrice> list, String code) {
    for (final metal in list) {
      if (metal.code == code) return metal;
    }
    return null;
  }

  double? _unitPrice(MetalPrice metal, PriceCatalog? catalog) {
    final units = _units(catalog);
    final unit = _effectiveUnit(units);

    if (_metal == "gold") {
      final karatLabel = _goldKarats(catalog)[_effectiveKarat(catalog)];
      final perGram = metal.goldKaratBuy[karatLabel] ?? metal.buy.perGram;
      if (perGram <= 0) return null;

      return switch (unit) {
        "gram" => perGram,
        "10_gram" => perGram * 10,
        "5_gram" => perGram * 5,
        "kg" => perGram * 1000,
        _ => perGram * _gramsPerTola,
      };
    }

    const silverKeys = {
      "10_tola_qr": ["10 Tola (QR Packaging)", "10 Tola"],
      "10_tola": ["10 Tola"],
      "kg": ["1 KG"],
      "5_tola": ["5 Tola"],
      "tola": ["Tola"],
    };

    final selectedLabel = units.firstWhere((u) => u.key == unit).label;
    final directValue = metal.silverQtyBuy[selectedLabel];
    if (directValue != null && directValue > 0) return directValue;

    for (final key in silverKeys[unit] ?? const <String>[]) {
      final value = metal.silverQtyBuy[key];
      if (value != null && value > 0) return value;
    }

    final perGram = metal.buy.perGram;
    if (perGram <= 0) return null;

    return switch (unit) {
      "10_tola_qr" || "10_tola" => perGram * _gramsPerTola * 10,
      "kg" => perGram * 1000,
      "5_tola" => perGram * _gramsPerTola * 5,
      _ => perGram * _gramsPerTola,
    };
  }

  @override
  Widget build(BuildContext context) {
    final prices = context.watch<PricesProvider>();
    final site = context.watch<SiteConfigProvider>().config;
    final catalog = prices.latest?.priceCatalog;
    final metals = (catalog?.metals.isNotEmpty ?? false)
        ? catalog!.metals
        : const {"gold": "Gold", "silver": "Silver"};
    final goldKarats = _goldKarats(catalog);
    final units = _units(catalog);
    final selectedKarat = _effectiveKarat(catalog);
    final selectedUnit = _effectiveUnit(units);
    final metal = _findMetal(
      prices.latest?.metals ?? const [],
      _metal == "gold" ? "XAU" : "XAG",
    );
    final unitPrice = metal == null ? null : _unitPrice(metal, catalog);
    final total = unitPrice == null || _quantity <= 0
        ? null
        : unitPrice * _quantity;
    final canCalculate = unitPrice != null && _quantity > 0 && !_refreshing;

    return Scaffold(
      backgroundColor: Brand.teal,
      appBar: AppBar(title: const Text("Buy Calculator")),
      body: BrandBackground(
        child: RefreshIndicator(
          color: Brand.gold,
          onRefresh: () => context.read<PricesProvider>().refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s16,
              Brand.s16,
              Brand.s24,
            ),
            children: [
              SectionHeader(
                eyebrow: "Estimate",
                title: "Buy Calculator",
                trailing: prices.isLoading || _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LiveDot(size: 7),
                          const SizedBox(width: Brand.s8),
                          Text(
                            "Live",
                            style: Brand.sans(
                              12,
                              color: Brand.goldBright,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ).entrance(),
              const SizedBox(height: Brand.s16),
              BrandCard(
                gold: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Metal"),
                    const SizedBox(height: Brand.s8),
                    Wrap(
                      spacing: Brand.s8,
                      runSpacing: Brand.s8,
                      children: [
                        for (final metal in metals.entries)
                          _choice(
                            metal.value,
                            _metal == metal.key,
                            () => _setMetal(metal.key, catalog),
                          ),
                      ],
                    ),
                    if (_metal == "gold") ...[
                      const SizedBox(height: Brand.s16),
                      _label("Karat"),
                      const SizedBox(height: Brand.s8),
                      Wrap(
                        spacing: Brand.s8,
                        runSpacing: Brand.s8,
                        children: [
                          for (final karat in goldKarats.entries)
                            _choice(
                              karat.value,
                              selectedKarat == karat.key,
                              () {
                                setState(() {
                                  _karat = karat.key;
                                  _showResult = false;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: Brand.s16),
                    _label("Size"),
                    const SizedBox(height: Brand.s8),
                    Wrap(
                      spacing: Brand.s8,
                      runSpacing: Brand.s8,
                      children: [
                        for (final unit in units)
                          _choice(unit.label, selectedUnit == unit.key, () {
                            setState(() {
                              _unit = unit.key;
                              _showResult = false;
                            });
                          }),
                      ],
                    ),
                    const SizedBox(height: Brand.s16),
                    _label("Quantity"),
                    const SizedBox(height: Brand.s8),
                    TextField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                      ],
                      onChanged: (_) => setState(() => _showResult = false),
                      decoration: InputDecoration(
                        hintText: "1",
                        suffixText: units
                            .firstWhere((u) => u.key == selectedUnit)
                            .label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (prices.error != null) ...[
                      const SizedBox(height: Brand.s8),
                      Text(
                        prices.error!,
                        style: Brand.sans(12, color: Brand.down),
                      ),
                    ],
                    const SizedBox(height: Brand.s16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canCalculate ? _calculate : null,
                        icon: _refreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.calculate_outlined),
                        label: const Text("Calculate Total"),
                      ),
                    ),
                  ],
                ),
              ).entrance(delayMs: 70),
              if (_showResult && total != null && unitPrice != null) ...[
                const SizedBox(height: Brand.s16),
                _resultCard(
                  site,
                  unitPrice,
                  total,
                  catalog,
                ).entrance(delayMs: 100),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _setMetal(String metal, PriceCatalog? catalog) {
    final nextUnits = metal == "silver"
        ? catalog?.silverUnits ?? const {}
        : catalog?.goldUnits ?? const {};
    final fallbackUnits = metal == "silver"
        ? _fallbackSilverUnits
        : _fallbackGoldUnits;
    final validUnitKeys = nextUnits.isNotEmpty
        ? nextUnits.keys.toSet()
        : fallbackUnits.map((unit) => unit.key).toSet();

    setState(() {
      _metal = metal;
      _showResult = false;
      if (!validUnitKeys.contains(_unit)) {
        _unit = validUnitKeys.first;
      }
    });
  }

  Widget _resultCard(
    dynamic site,
    double unitPrice,
    double total,
    PriceCatalog? catalog,
  ) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Estimated total",
            style: Brand.sans(13, color: Brand.textMuted),
          ),
          const SizedBox(height: Brand.s8),
          Text(
            "Rs ${_money.format(total)}",
            style: Brand.number(
              28,
              color: Brand.goldBright,
              weight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: Brand.s8),
          _summaryRow("Selected", _selectionLabel(catalog)),
          _summaryRow("Quantity", _quantityCtrl.text.trim()),
          _summaryRow("Unit price", "Rs ${_money.format(unitPrice)}"),
          const SizedBox(height: Brand.s16),
          Text(
            "Contact us to buy",
            style: Brand.sans(15, weight: FontWeight.w800),
          ),
          const SizedBox(height: Brand.s12),
          Row(
            children: [
              if (site.contactWhatsapp.isNotEmpty)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openWhatsApp(site.contactWhatsapp, total),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("WhatsApp"),
                  ),
                ),
              if (site.contactWhatsapp.isNotEmpty &&
                  site.contactPhone.isNotEmpty)
                const SizedBox(width: Brand.s8),
              if (site.contactPhone.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callPhone(site.contactPhone),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text("Call"),
                  ),
                ),
            ],
          ),
          if (site.contactAddress.isNotEmpty) ...[
            const SizedBox(height: Brand.s12),
            Text(
              site.contactAddress,
              style: Brand.sans(12, color: Brand.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Brand.sans(12, color: Brand.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Brand.sans(12, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: Brand.sans(13, color: Brand.textMuted, weight: FontWeight.w800),
  );

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Brand.base,
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(
            horizontal: Brand.s16,
            vertical: Brand.s12,
          ),
          decoration: BoxDecoration(
            gradient: selected ? Brand.goldGradient : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : Brand.hairline,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Brand.sans(
              12,
              color: selected ? const Color(0xFF1A1207) : Brand.textMuted,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorUnit {
  final String key;
  final String label;

  const _CalculatorUnit(this.key, this.label);
}
