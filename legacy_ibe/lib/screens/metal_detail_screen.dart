// lib/screens/metal_detail_screen.dart
import "package:flutter/material.dart";

import "../models/metal_price.dart";
import "../providers/app_settings.dart";
import "../widgets/animated_price_text.dart";
import "../widgets/currency_utils.dart";
import "../l10n/app_localizations.dart";
import "../utils/time_utils.dart";

class MetalDetailScreen extends StatefulWidget {
  final MetalPrice metal;
  final String currency;
  final int timestamp;

  const MetalDetailScreen({
    super.key,
    required this.metal,
    required this.currency,
    required this.timestamp,
  });

  @override
  State<MetalDetailScreen> createState() => _MetalDetailScreenState();
}

class _MetalDetailScreenState extends State<MetalDetailScreen> {
  PriceUnit _unit = PriceUnit.gram;

  double _pick(PriceBlock b) {
    switch (_unit) {
      case PriceUnit.gram:
        return b.perGram;
      case PriceUnit.tola:
        return b.perTola;
      case PriceUnit.ounce:
        return b.perOz;
    }
  }

  String _unitLabel(AppLocalizations loc) {
    switch (_unit) {
      case PriceUnit.gram:
        return loc.t("per_gram");
      case PriceUnit.tola:
        return loc.t("per_tola");
      case PriceUnit.ounce:
        return loc.t("per_oz");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sym = currencySymbol(widget.currency);

    final timeStr = formatPakistanTime(
      widget.timestamp,
      Localizations.localeOf(context),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.metal.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${widget.metal.code} • ${widget.currency}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (widget.metal.isManual)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(loc.t("manual"), style: Theme.of(context).textTheme.labelMedium),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(loc.t("gram")),
                  selected: _unit == PriceUnit.gram,
                  onSelected: (_) => setState(() => _unit = PriceUnit.gram),
                ),
                ChoiceChip(
                  label: Text(loc.t("tola")),
                  selected: _unit == PriceUnit.tola,
                  onSelected: (_) => setState(() => _unit = PriceUnit.tola),
                ),
                ChoiceChip(
                  label: Text(loc.t("ounce")),
                  selected: _unit == PriceUnit.ounce,
                  onSelected: (_) => setState(() => _unit = PriceUnit.ounce),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _bigCard(context, sym, loc),

            const SizedBox(height: 14),

            if (widget.metal.code == "XAU" && widget.metal.goldKaratMid.isNotEmpty) ...[
              Text(
                loc.t("gold_categories"),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ..._karatRows(context, sym, loc),
              const SizedBox(height: 6),
            ],

            Text(
              loc.f("updated_pkt", {"time": timeStr}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigCard(BuildContext context, String sym, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_unitLabel(loc), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _bigCol(context, loc.t("mid"), sym, _pick(widget.metal.mid))),
                const SizedBox(width: 10),
                Expanded(child: _bigCol(context, loc.t("sell"), sym, _pick(widget.metal.sell))),
                const SizedBox(width: 10),
                Expanded(child: _bigCol(context, loc.t("buy"), sym, _pick(widget.metal.buy))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigCol(BuildContext context, String title, String sym, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          AnimatedPriceText(
            value: value,
            currencyPrefix: sym,
            // Admin-set rates: only the two digits before the point move.
            fluctuation: PriceFluctuation.lastTwoDigits,
            style: Theme.of(context).textTheme.titleLarge,
            decimals: 2,
          ),
        ],
      ),
    );
  }

  List<Widget> _karatRows(BuildContext context, String sym, AppLocalizations loc) {
    const karats = ["24K", "22K", "21K", "18K"];
    return karats.map((k) {
      final mid = widget.metal.goldKaratMid[k] ?? 0;
      final sell = widget.metal.goldKaratSell[k] ?? mid;
      final buy = widget.metal.goldKaratBuy[k] ?? mid;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _smallCol(context, loc.t("mid"), sym, mid)),
                    const SizedBox(width: 10),
                    Expanded(child: _smallCol(context, loc.t("sell"), sym, sell)),
                    const SizedBox(width: 10),
                    Expanded(child: _smallCol(context, loc.t("buy"), sym, buy)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _smallCol(BuildContext context, String title, String sym, double value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          AnimatedPriceText(
            value: value,
            currencyPrefix: sym,
            // Admin-set rates: only the two digits before the point move.
            fluctuation: PriceFluctuation.lastTwoDigits,
            style: Theme.of(context).textTheme.titleMedium,
            decimals: 2,
          ),
        ],
      ),
    );
  }
}
