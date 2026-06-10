// lib/screens/zakat_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";
import "../providers/prices_provider.dart";
import "../widgets/error_view.dart";
import "../widgets/animated_price_text.dart";
import "../widgets/currency_utils.dart";
import "../utils/time_utils.dart";
import "../l10n/app_localizations.dart";
import "../models/metal_price.dart";

enum _SpotUnit { gram, tola }
enum _PriceBasis { sell }
enum _NisabBasis { silver }

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  int _stepIndex = 0; // 0=assets, 1=result

  bool _includeGold = true;
  bool _includeSilver = true;

  // Fixed values - no longer changeable by user
  final _PriceBasis _basis = _PriceBasis.sell;
  final _NisabBasis _nisabBasis = _NisabBasis.silver;

  final List<_GoldLine> _goldLines = [ _GoldLine() ];
  final List<_SilverLine> _silverLines = [ _SilverLine() ];

  // Conversions
  static const double _gramsPerTola = 11.6638038;

  // Nisab thresholds (grams) - commonly used values
  static const double _nisabGoldGrams = 87.48;
  static const double _nisabSilverGrams = 612.36;

  // Colors - Match About Us screen
  static const Color _backgroundColor = Color(0xFF1A5249);
  static const Color _cardColor = Color(0xFF0A3C30);
  static const Color _accentColor = Color(0xFFdfa273);
  static const Color _borderColor = Color(0x38dfa273); // 0x38 = 0.22 opacity

  @override
  void dispose() {
    for (final g in _goldLines) {
      g.weightCtrl.dispose();
    }
    for (final s in _silverLines) {
      s.weightCtrl.dispose();
    }
    super.dispose();
  }

  MetalPrice? _findMetal(List<MetalPrice> list, String code) {
    for (final m in list) {
      if (m.code == code) return m;
    }
    return null;
  }

  String _t(BuildContext context, String en, String ur) {
    final isUrdu = context.read<AppSettings>().isUrdu;
    return isUrdu ? ur : en;
  }

  double _parseNum(String raw) {
    final s = raw.trim().replaceAll(",", "");
    if (s.isEmpty) return 0.0;
    return double.tryParse(s) ?? 0.0;
  }

  double _toGrams(double w, _SpotUnit unit) {
    if (unit == _SpotUnit.gram) return w;
    return w * _gramsPerTola; // tola
  }

  String _unitLabel(AppLocalizations loc, _SpotUnit u) {
    switch (u) {
      case _SpotUnit.gram:
        return loc.t("gram");
      case _SpotUnit.tola:
        return loc.t("tola");
    }
  }

  String _basisLabel(BuildContext context, _PriceBasis b) {
    switch (b) {
      case _PriceBasis.sell:
        return _t(context, "Sell", "سیل");
    }
  }

  String _nisabLabel(BuildContext context, _NisabBasis b) {
    switch (b) {
      case _NisabBasis.silver:
        return _t(context, "Silver Nisab", "چاندی نصاب");
    }
  }

  List<String> _goldCategories(MetalPrice g) {
    final keys = <String>{};
    keys.addAll(g.goldKaratSell.keys);
    keys.addAll(g.goldKaratBuy.keys);
    keys.addAll(g.goldKaratMid.keys);

    const ordered = ["24K", "22K", "21K", "18K"];
    final result = <String>["Spot"];

    for (final k in ordered) {
      if (keys.contains(k)) result.add(k);
    }

    // If backend has unusual keys, include them too.
    final others = keys.difference(ordered.toSet()).toList()..sort();
    result.addAll(others);

    return result;
  }

  double _spotPerGram(MetalPrice m) {
    // Always use sell price
    return m.sell.perGram;
  }

  double _goldPerGramForCategory(MetalPrice g, String cat) {
    if (cat == "Spot") return _spotPerGram(g);

    // Always use sell price
    final v = g.goldKaratSell[cat];
    return v ?? _spotPerGram(g);
  }

  double _silverPerGram(MetalPrice s) => _spotPerGram(s);

  double _goldTotalValue(MetalPrice? gold) {
    if (!_includeGold || gold == null) return 0.0;
    double total = 0.0;

    for (final line in _goldLines) {
      final w = _parseNum(line.weightCtrl.text);
      if (w <= 0) continue;
      final grams = _toGrams(w, line.unit);
      final perGram = _goldPerGramForCategory(gold, line.category);
      total += grams * perGram;
    }
    return total;
  }

  double _silverTotalValue(MetalPrice? silver) {
    if (!_includeSilver || silver == null) return 0.0;
    double total = 0.0;

    for (final line in _silverLines) {
      final w = _parseNum(line.weightCtrl.text);
      if (w <= 0) continue;
      final grams = _toGrams(w, line.unit);
      total += grams * _silverPerGram(silver);
    }
    return total;
  }

  double _nisabValue({required MetalPrice? gold, required MetalPrice? silver}) {
    // Always use silver nisab
    if (silver != null) return _nisabSilverGrams * _silverPerGram(silver);
    if (gold != null) return _nisabGoldGrams * _goldPerGramForCategory(gold, "24K");
    return 0.0;
  }

  bool _hasAnyInput() {
    bool any = false;
    if (_includeGold) {
      for (final g in _goldLines) {
        if (_parseNum(g.weightCtrl.text) > 0) {
          any = true;
          break;
        }
      }
    }
    if (!any && _includeSilver) {
      for (final s in _silverLines) {
        if (_parseNum(s.weightCtrl.text) > 0) {
          any = true;
          break;
        }
      }
    }
    return any;
  }

  void _reset() {
    setState(() {
      _stepIndex = 0;
      _includeGold = true;
      _includeSilver = true;

      for (final g in _goldLines) {
        g.weightCtrl.dispose();
      }
      for (final s in _silverLines) {
        s.weightCtrl.dispose();
      }

      _goldLines
        ..clear()
        ..add(_GoldLine());
      _silverLines
        ..clear()
        ..add(_SilverLine());
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final prices = context.watch<PricesProvider>();
    final loc = AppLocalizations.of(context);

    // Loading & error handling
    if (prices.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t(context, "Zakat Calculator", "زکوٰۃ کیلکولیٹر"),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          backgroundColor: _cardColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: _backgroundColor,
        body: const Center(child: CircularProgressIndicator(color: _accentColor)),
      );
    }

    if (prices.latest == null && prices.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t(context, "Zakat Calculator", "زکوٰۃ کیلکولیٹر"),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          backgroundColor: _cardColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: _backgroundColor,
        body: ErrorView(message: prices.error!, onRetry: () => prices.refresh()),
      );
    }

    final latest = prices.latest;
    if (latest == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t(context, "Zakat Calculator", "زکوٰۃ کیلکولیٹر"),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          backgroundColor: _cardColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: _backgroundColor,
        body: ErrorView(message: loc.t("no_data_yet"), onRetry: () => prices.refresh()),
      );
    }

    final sym = currencySymbol(latest.currency);
    final updatedPkt = formatPakistanTime(latest.timestamp, settings.locale);

    final gold = _findMetal(latest.metals, "XAU");
    final silver = _findMetal(latest.metals, "XAG");

    // Ensure gold lines have valid category when live data exists
    if (gold != null) {
      final cats = _goldCategories(gold);
      for (final line in _goldLines) {
        if (!cats.contains(line.category)) {
          line.category = cats.first; // usually "Spot"
        }
      }
    }

    final goldValue = _goldTotalValue(gold);
    final silverValue = _silverTotalValue(silver);
    final totalValue = goldValue + silverValue;

    final nisabValue = _nisabValue(gold: gold, silver: silver);
    final bool zakatDue = (nisabValue > 0.0) && (totalValue >= nisabValue);
    final double zakatAmount = zakatDue ? (totalValue * 0.025) : 0.0;

    final canGoResult = _hasAnyInput();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(_t(context, "Zakat Calculator", "زکوٰۃ کیلکولیٹر"),
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: _cardColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: loc.t("refresh"),
            onPressed: () => prices.refresh(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            tooltip: _t(context, "Reset", "ری سیٹ"),
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt, color: Colors.white),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TopHeader(
              title: _t(context, "Live Zakat Estimator", "لائیو زکوٰۃ تخمینہ"),
              subtitle: _t(context, "Gold & Silver only", "صرف سونا اور چاندی"),
              trailingTop: Text(
                loc.f("updated_pkt", {"time": updatedPkt}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailingBottom: _Pill(
                text: "${latest.currency} $sym",
                icon: Icons.currency_exchange,
              ),
              stepIndex: _stepIndex,
              stepCount: 2,
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _stepIndex == 0
                    ? _AssetsView(
                  key: const ValueKey("assets"),
                  settings: settings,
                  loc: loc,
                  sym: sym,
                  basis: _basis,
                  nisabBasis: _nisabBasis,
                  includeGold: _includeGold,
                  includeSilver: _includeSilver,
                  onToggleGold: (v) => setState(() => _includeGold = v),
                  onToggleSilver: (v) => setState(() => _includeSilver = v),
                  gold: gold,
                  silver: silver,
                  goldLines: _goldLines,
                  silverLines: _silverLines,
                  unitLabel: (u) => _unitLabel(loc, u),
                  basisLabel: (b) => _basisLabel(context, b),
                  nisabLabel: (b) => _nisabLabel(context, b),
                  goldCategories: gold == null ? const ["Spot", "24K", "22K", "21K", "18K"] : _goldCategories(gold),
                  goldLineEstimate: (line) {
                    if (gold == null) return 0.0;
                    final w = _parseNum(line.weightCtrl.text);
                    if (w <= 0) return 0.0;
                    final grams = _toGrams(w, line.unit);
                    final perGram = _goldPerGramForCategory(gold, line.category);
                    return grams * perGram;
                  },
                  silverLineEstimate: (line) {
                    if (silver == null) return 0.0;
                    final w = _parseNum(line.weightCtrl.text);
                    if (w <= 0) return 0.0;
                    final grams = _toGrams(w, line.unit);
                    return grams * _silverPerGram(silver);
                  },
                  totals: _Totals(gold: goldValue, silver: silverValue, total: totalValue),
                  onChanged: () => setState(() {}),
                )
                    : _ResultView(
                  key: const ValueKey("result"),
                  settings: settings,
                  loc: loc,
                  sym: sym,
                  basisLabel: _basisLabel(context, _basis),
                  nisabLabel: _nisabLabel(context, _nisabBasis),
                  goldValue: goldValue,
                  silverValue: silverValue,
                  totalValue: totalValue,
                  nisabValue: nisabValue,
                  zakatDue: zakatDue,
                  zakatAmount: zakatAmount,
                  includeGold: _includeGold,
                  includeSilver: _includeSilver,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _BottomActionBar(
          leftText: _stepIndex == 0 ? _t(context, "Cancel", "منسوخ") : _t(context, "Back", "واپس"),
          rightText: _stepIndex == 0 ? _t(context, "View Result", "نتیجہ دیکھیں") : _t(context, "Done", "ہو گیا"),
          rightEnabled: _stepIndex == 0 ? canGoResult : true,
          onLeft: () {
            if (_stepIndex == 0) {
              Navigator.of(context).maybePop();
            } else {
              setState(() => _stepIndex = 0);
            }
          },
          onRight: () {
            if (_stepIndex == 0) {
              if (!canGoResult) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _cardColor,
                    content: Text(_t(context, "Please enter at least one amount.", "براہ کرم کم از کم ایک مقدار درج کریں۔"),
                        style: const TextStyle(color: Colors.white)),
                  ),
                );
                return;
              }
              setState(() => _stepIndex = 1);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  UI Parts                                  */
/* -------------------------------------------------------------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailingTop;
  final Widget trailingBottom;
  final int stepIndex;
  final int stepCount;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.trailingTop,
    required this.trailingBottom,
    required this.stepIndex,
    required this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (stepIndex + 1) / stepCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3C30),
        border: Border(bottom: BorderSide(color: _ZakatScreenState._borderColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  trailingTop,
                  const SizedBox(height: 6),
                  trailingBottom,
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white12,
              color: _ZakatScreenState._accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _ZakatScreenState._accentColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ZakatScreenState._borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final String leftText;
  final String rightText;
  final bool rightEnabled;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _BottomActionBar({
    required this.leftText,
    required this.rightText,
    required this.rightEnabled,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3C30),
        border: Border(top: BorderSide(color: _ZakatScreenState._borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onLeft,
              child: Text(leftText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ZakatScreenState._accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: rightEnabled ? onRight : null,
              child: Text(rightText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                 Step 1 View                                */
/* -------------------------------------------------------------------------- */

class _Totals {
  final double gold;
  final double silver;
  final double total;

  const _Totals({required this.gold, required this.silver, required this.total});
}

class _AssetsView extends StatelessWidget {
  final AppSettings settings;
  final AppLocalizations loc;
  final String sym;

  final _PriceBasis basis;
  final _NisabBasis nisabBasis;

  final bool includeGold;
  final bool includeSilver;
  final ValueChanged<bool> onToggleGold;
  final ValueChanged<bool> onToggleSilver;

  final MetalPrice? gold;
  final MetalPrice? silver;

  final List<_GoldLine> goldLines;
  final List<_SilverLine> silverLines;

  final String Function(_SpotUnit) unitLabel;
  final String Function(_PriceBasis) basisLabel;
  final String Function(_NisabBasis) nisabLabel;

  final List<String> goldCategories;

  final double Function(_GoldLine) goldLineEstimate;
  final double Function(_SilverLine) silverLineEstimate;

  final _Totals totals;
  final VoidCallback onChanged;

  const _AssetsView({
    super.key,
    required this.settings,
    required this.loc,
    required this.sym,
    required this.basis,
    required this.nisabBasis,
    required this.includeGold,
    required this.includeSilver,
    required this.onToggleGold,
    required this.onToggleSilver,
    required this.gold,
    required this.silver,
    required this.goldLines,
    required this.silverLines,
    required this.unitLabel,
    required this.basisLabel,
    required this.nisabLabel,
    required this.goldCategories,
    required this.goldLineEstimate,
    required this.silverLineEstimate,
    required this.totals,
    required this.onChanged,
  });

  String _t(String en, String ur) => settings.isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _SectionCard(
          title: _t("Settings", "سیٹنگز"),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(text: "${_t("Price basis", "قیمت کی بنیاد")}: ${basisLabel(basis)}"),
              const SizedBox(height: 8),
              _InfoLine(text: "${_t("Nisab basis", "نصاب کی بنیاد")}: ${nisabLabel(nisabBasis)}"),
              const SizedBox(height: 10),
              Text(
                _t(
                  "Tip: Silver Nisab is commonly used because it is more inclusive.",
                  "مشورہ: چاندی کا نصاب عام طور پر استعمال ہوتا ہے کیونکہ یہ زیادہ جامع ہے۔",
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: _t("What you own", "آپ کے اثاثے"),
          child: Column(
            children: [
              _ToggleTile(
                title: _t("Gold", "سونا"),
                subtitle: _t("Add multiple categories (24K/22K/…)", "مختلف کیٹیگریز (24K/22K/…) شامل کریں"),
                value: includeGold,
                onChanged: (v) {
                  onToggleGold(v);
                  onChanged();
                },
                icon: Icons.workspace_premium,
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                title: _t("Silver", "چاندی"),
                subtitle: _t("Add your silver weight", "چاندی کا وزن شامل کریں"),
                value: includeSilver,
                onChanged: (v) {
                  onToggleSilver(v);
                  onChanged();
                },
                icon: Icons.brightness_7,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (includeGold) ...[
          _SectionCard(
            title: _t("Gold entries", "سونے کے اندراجات"),
            trailing: TextButton.icon(
              onPressed: () {
                goldLines.add(_GoldLine());
                onChanged();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(_t("Add", "شامل کریں"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            child: Column(
              children: [
                if (gold == null)
                  _InfoLine(text: _t("Gold rate is not available right now.", "اس وقت سونے کا ریٹ دستیاب نہیں۔")),
                for (int i = 0; i < goldLines.length; i++) ...[
                  _GoldEntryCard(
                    index: i,
                    isUrdu: settings.isUrdu,
                    loc: loc,
                    sym: sym,
                    line: goldLines[i],
                    categories: goldCategories,
                    unitLabel: unitLabel,
                    estimate: goldLineEstimate(goldLines[i]),
                    canRemove: goldLines.length > 1,
                    onRemove: () {
                      goldLines[i].weightCtrl.dispose();
                      goldLines.removeAt(i);
                      if (goldLines.isEmpty) goldLines.add(_GoldLine());
                      onChanged();
                    },
                    onChanged: onChanged,
                  ),
                  if (i != goldLines.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (includeSilver) ...[
          _SectionCard(
            title: _t("Silver entries", "چاندی کے اندراجات"),
            trailing: TextButton.icon(
              onPressed: () {
                silverLines.add(_SilverLine());
                onChanged();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(_t("Add", "شامل کریں"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            child: Column(
              children: [
                if (silver == null)
                  _InfoLine(text: _t("Silver rate is not available right now.", "اس وقت چاندی کا ریٹ دستیاب نہیں۔")),
                for (int i = 0; i < silverLines.length; i++) ...[
                  _SilverEntryCard(
                    index: i,
                    isUrdu: settings.isUrdu,
                    sym: sym,
                    loc: loc,
                    line: silverLines[i],
                    unitLabel: unitLabel,
                    estimate: silverLineEstimate(silverLines[i]),
                    canRemove: silverLines.length > 1,
                    onRemove: () {
                      silverLines[i].weightCtrl.dispose();
                      silverLines.removeAt(i);
                      if (silverLines.isEmpty) silverLines.add(_SilverLine());
                      onChanged();
                    },
                    onChanged: onChanged,
                  ),
                  if (i != silverLines.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        _SectionCard(
          title: _t("Estimated total", "کل تخمینہ"),
          child: Column(
            children: [
              _AmountRow(
                label: _t("Gold value", "سونے کی قیمت"),
                value: totals.gold,
                sym: sym,
              ),
              const SizedBox(height: 10),
              _AmountRow(
                label: _t("Silver value", "چاندی کی قیمت"),
                value: totals.silver,
                sym: sym,
              ),
              const Divider(height: 22, color: Colors.white24),
              _AmountRow(
                label: _t("Total: ", "کل: "),
                value: totals.total,
                sym: sym,
                prominent: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                 Step 2 View                                */
/* -------------------------------------------------------------------------- */

class _ResultView extends StatelessWidget {
  final AppSettings settings;
  final AppLocalizations loc;
  final String sym;

  final String basisLabel;
  final String nisabLabel;

  final double goldValue;
  final double silverValue;
  final double totalValue;
  final double nisabValue;

  final bool zakatDue;
  final double zakatAmount;

  final bool includeGold;
  final bool includeSilver;

  const _ResultView({
    super.key,
    required this.settings,
    required this.loc,
    required this.sym,
    required this.basisLabel,
    required this.nisabLabel,
    required this.goldValue,
    required this.silverValue,
    required this.totalValue,
    required this.nisabValue,
    required this.zakatDue,
    required this.zakatAmount,
    required this.includeGold,
    required this.includeSilver,
  });

  String _t(String en, String ur) => settings.isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _SectionCard(
          title: _t("Summary", "خلاصہ"),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(text: "${_t("Price basis", "قیمت کی بنیاد")}: $basisLabel"),
              const SizedBox(height: 6),
              _InfoLine(text: "${_t("Nisab basis", "نصاب کی بنیاد")}: $nisabLabel"),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: zakatDue ? const Color(0xFF0A3C30) : const Color(0xFF0A3C30),
            border: Border.all(color: _ZakatScreenState._borderColor),
          ),
          child: Row(
            children: [
              Icon(zakatDue ? Icons.verified : Icons.info_outline,
                  size: 22, color: _ZakatScreenState._accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  zakatDue
                      ? _t("Zakat is due based on your inputs.", "آپ کی دی گئی معلومات کے مطابق زکوٰۃ واجب ہے۔")
                      : _t("Zakat is not due (below Nisab).", "زکوٰۃ واجب نہیں (نصاب سے کم)۔"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: _t("Values", "قیمتیں"),
          child: Column(
            children: [
              if (includeGold) ...[
                _AmountRow(label: _t("Gold value", "سونے کی قیمت"), value: goldValue, sym: sym),
                const SizedBox(height: 10),
              ],
              if (includeSilver) ...[
                _AmountRow(label: _t("Silver value", "چاندی کی قیمت"), value: silverValue, sym: sym),
                const SizedBox(height: 10),
              ],
              _AmountRow(label: _t("Total", "کل"), value: totalValue, sym: sym, prominent: true),
              const Divider(height: 22, color: Colors.white24),
              _AmountRow(label: _t("Calculated Nisab", "حساب شدہ نصاب"), value: nisabValue, sym: sym),
              const SizedBox(height: 12),
              _AmountRow(
                label: _t("Zakat (2.5%)", "زکوٰۃ (2.5%)"),
                value: zakatAmount,
                sym: sym,
                prominent: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: _t("How we calculated", "ہم نے کیسے حساب کیا"),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullet(text: _t("Converted each entry to grams (if needed).", "ہر اندراج کو گرام میں تبدیل کیا (اگر ضرورت ہو)۔")),
              _Bullet(text: _t("Estimated value = grams × price per gram (based on your selected basis).", "تخمینی قیمت = گرام × فی گرام قیمت (آپ کی منتخب بنیاد کے مطابق)۔")),
              _Bullet(text: _t("Total eligible value = Gold + Silver.", "کل قابلِ زکوٰۃ = سونا + چاندی۔")),
              _Bullet(text: _t("If total ≥ Nisab, Zakat = total × 2.5% (1/40).", "اگر کل ≥ نصاب، تو زکوٰۃ = کل × 2.5% (1/40)۔")),
              const SizedBox(height: 10),
              Text(
                _t(
                  "Note: This is an estimate using live prices. For final guidance, consult your scholar.",
                  "نوٹ: یہ لائیو قیمتوں کے مطابق تخمینہ ہے۔ حتمی رہنمائی کے لیے عالم سے رجوع کریں۔",
                ),
                style: const TextStyle(color: Colors.white70, height: 1.35, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               Shared Widgets                               */
/* -------------------------------------------------------------------------- */

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A3C30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _ZakatScreenState._borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? Colors.white : const Color(0xFF0A3C30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ZakatScreenState._borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: value ? _ZakatScreenState._accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ZakatScreenState._accentColor.withOpacity(0.25)),
              ),
              child: Icon(icon, color: value ? _ZakatScreenState._accentColor : Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: value ? Colors.black : _ZakatScreenState._accentColor,
                          fontSize: 14
                      )),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: value ? Colors.black54 : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _ZakatScreenState._accentColor,
              trackColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return _ZakatScreenState._accentColor.withOpacity(0.5);
                }
                return Colors.white24;
              }),
              thumbColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return _ZakatScreenState._accentColor;
                }
                return Colors.white70;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;
  const _InfoLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final String sym;
  final bool prominent;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.sym,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = prominent
        ? const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15)
        : const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14);

    final valueStyle = prominent
        ? const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)
        : const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15);

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedPriceText(
            value: value,
            currencyPrefix: sym,
            decimals: 2,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
                color: _ZakatScreenState._accentColor,
                shape: BoxShape.circle
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, height: 1.35, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            Entry models + cards                            */
/* -------------------------------------------------------------------------- */

class _GoldLine {
  String category = "Spot";
  _SpotUnit unit = _SpotUnit.gram;
  final TextEditingController weightCtrl = TextEditingController();
}

class _SilverLine {
  _SpotUnit unit = _SpotUnit.gram;
  final TextEditingController weightCtrl = TextEditingController();
}

class _GoldEntryCard extends StatelessWidget {
  final int index;
  final bool isUrdu;
  final AppLocalizations loc;
  final String sym;

  final _GoldLine line;
  final List<String> categories;
  final String Function(_SpotUnit) unitLabel;
  final double estimate;

  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _GoldEntryCard({
    required this.index,
    required this.isUrdu,
    required this.loc,
    required this.sym,
    required this.line,
    required this.categories,
    required this.unitLabel,
    required this.estimate,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  String _t(String en, String ur) => isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3C30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ZakatScreenState._borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t("Entry ${index + 1}", "اندراج ${index + 1}"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: _ZakatScreenState._accentColor, fontSize: 14),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: _t("Remove", "حذف کریں"),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 6,
                child: DropdownButtonFormField<String>(
                  value: categories.contains(line.category) ? line.category : categories.first,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0A3C30),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) {
                    if (v == null) return;
                    line.category = v;
                    onChanged();
                  },
                  items: categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  decoration: InputDecoration(
                    labelText: _t("Category", "کیٹیگری"),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _ZakatScreenState._borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _ZakatScreenState._borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<_SpotUnit>(
                  value: line.unit,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0A3C30),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) {
                    if (v == null) return;
                    line.unit = v;
                    onChanged();
                  },
                  items: _SpotUnit.values.map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(unitLabel(u), style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  decoration: InputDecoration(
                    labelText: _t("Unit", "اکائی"),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _ZakatScreenState._borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _ZakatScreenState._borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: line.weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: _t("Your gold amount", "آپ کے پاس سونا"),
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: _t("Enter weight", "وزن درج کریں"),
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _ZakatScreenState._borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _ZakatScreenState._borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(_t("Estimated value", "تخمینی قیمت"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white70, fontSize: 13)),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedPriceText(
                  value: estimate,
                  currencyPrefix: sym,
                  decimals: 2,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SilverEntryCard extends StatelessWidget {
  final int index;
  final bool isUrdu;
  final AppLocalizations loc;
  final String sym;

  final _SilverLine line;
  final String Function(_SpotUnit) unitLabel;
  final double estimate;

  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _SilverEntryCard({
    required this.index,
    required this.isUrdu,
    required this.loc,
    required this.sym,
    required this.line,
    required this.unitLabel,
    required this.estimate,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  String _t(String en, String ur) => isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3C30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ZakatScreenState._borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t("Entry ${index + 1}", "اندراج ${index + 1}"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: _ZakatScreenState._accentColor, fontSize: 14),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: _t("Remove", "حذف کریں"),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<_SpotUnit>(
            value: line.unit,
            isExpanded: true,
            dropdownColor: const Color(0xFF0A3C30),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (v) {
              if (v == null) return;
              line.unit = v;
              onChanged();
            },
            items: _SpotUnit.values.map((u) => DropdownMenuItem(
              value: u,
              child: Text(unitLabel(u), style: const TextStyle(color: Colors.white)),
            )).toList(),
            decoration: InputDecoration(
              labelText: _t("Unit", "اکائی"),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _ZakatScreenState._borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _ZakatScreenState._borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: line.weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: _t("Your silver amount", "آپ کے پاس چاندی"),
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: _t("Enter weight", "وزن درج کریں"),
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _ZakatScreenState._borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _ZakatScreenState._borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(_t("Estimated value", "تخمینی قیمت"),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white70, fontSize: 13)),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedPriceText(
                  value: estimate,
                  currencyPrefix: sym,
                  decimals: 2,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}