import "package:flutter/material.dart";
import "../models/metal_price.dart";
import "../providers/app_settings.dart";
import "animated_price_text.dart";
import "currency_utils.dart";

class MetalCard extends StatelessWidget {
  final MetalPrice metal;
  final String currency;
  final PriceUnit unit;
  final VoidCallback onTap;

  const MetalCard({
    super.key,
    required this.metal,
    required this.currency,
    required this.unit,
    required this.onTap,
  });

  double _pick(PriceBlock b) {
    switch (unit) {
      case PriceUnit.gram:
        return b.perGram;
      case PriceUnit.tola:
        return b.perTola;
      case PriceUnit.ounce:
        return b.perOz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = currencySymbol(currency);
    final unitLabel = switch (unit) {
      PriceUnit.gram => "per gram",
      PriceUnit.tola => "per tola",
      PriceUnit.ounce => "per oz",
    };

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metal.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (metal.isManual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text("Manual", style: Theme.of(context).textTheme.labelMedium),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text("$unitLabel • ${metal.code}", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _col(context, "Mid", sym, _pick(metal.mid))),
                  const SizedBox(width: 10),
                  Expanded(child: _col(context, "Sell", sym, _pick(metal.sell))),
                  const SizedBox(width: 10),
                  Expanded(child: _col(context, "Buy", sym, _pick(metal.buy))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _col(BuildContext context, String title, String sym, double value) {
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
            style: Theme.of(context).textTheme.titleMedium,
            decimals: 2,
          ),
        ],
      ),
    );
  }
}
