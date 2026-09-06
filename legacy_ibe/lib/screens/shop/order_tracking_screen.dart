import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../models/shop_models.dart";
import "../../providers/shop_provider.dart";
import "../../theme/brand.dart";
import "../../widgets/brand_kit.dart";

class OrderTrackingScreen extends StatefulWidget {
  final String? initialOrderNumber;

  const OrderTrackingScreen({super.key, this.initialOrderNumber});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _orderCtrl = TextEditingController();
  final _money = NumberFormat("#,##0");
  bool _loading = false;
  String? _error;
  ShopOrder? _order;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialOrderNumber;
    if (initial != null && initial.trim().isNotEmpty) {
      _orderCtrl.text = OrderNumberFormatter.format(initial);
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final orderNumber = OrderNumberFormatter.format(_orderCtrl.text);
    if (_orderCtrl.text != orderNumber) {
      _orderCtrl.value = TextEditingValue(
        text: orderNumber,
        selection: TextSelection.collapsed(offset: orderNumber.length),
      );
    }

    if (orderNumber.isEmpty) {
      setState(() => _error = "Please enter your order number.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final created = await context.read<ShopProvider>().api.fetchOrder(
        orderNumber,
      );
      if (!mounted) return;
      setState(() => _order = created.order);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _order = null;
        _error = "Order not found. Please check the number and try again.";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.teal,
      appBar: AppBar(title: const Text("Track Order")),
      body: BrandBackground(
        child: RefreshIndicator(
          color: Brand.gold,
          onRefresh: _track,
          child: ListView(
            padding: const EdgeInsets.all(Brand.s16),
            children: [
              BrandCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order number",
                      style: Brand.sans(13, color: Brand.textMuted),
                    ),
                    const SizedBox(height: Brand.s8),
                    TextField(
                      controller: _orderCtrl,
                      inputFormatters: [OrderNumberInputFormatter()],
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _track(),
                      decoration: const InputDecoration(
                        hintText: "IBE-12345-12345678",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: Brand.s8),
                      Text(
                        _error!,
                        style: Brand.sans(
                          12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: Brand.s12),
                    FilledButton.icon(
                      onPressed: _loading ? null : _track,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text("Track"),
                    ),
                  ],
                ),
              ).entrance(),
              if (_order != null) ...[
                const SizedBox(height: Brand.s16),
                _statusCard(_order!).entrance(delayMs: 80),
                const SizedBox(height: Brand.s16),
                _detailsCard(_order!).entrance(delayMs: 140),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(ShopOrder order) {
    final steps = order.tracking?.steps ?? _fallbackSteps(order.status);

    return BrandCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderNumber,
            style: Brand.sans(
              12,
              color: Brand.textMuted,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Brand.s4),
          Text(order.statusLabel, style: Brand.display(24, color: Brand.gold)),
          const SizedBox(height: Brand.s16),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: Brand.s12),
              child: Row(
                children: [
                  _stepIcon(step.state),
                  const SizedBox(width: Brand.s12),
                  Expanded(
                    child: Text(
                      step.label,
                      style: Brand.sans(
                        14,
                        color: step.state == "current"
                            ? Brand.gold
                            : step.state == "upcoming"
                            ? Brand.textMuted.withValues(alpha: 0.45)
                            : Brand.textMuted,
                        weight: step.state == "current"
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailsCard(ShopOrder order) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Details", style: Brand.sans(16, weight: FontWeight.w800)),
          const SizedBox(height: Brand.s12),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: Brand.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.isMetalLine
                          ? item.productName
                          : "${item.productName} × ${item.quantityLabel}",
                      style: Brand.sans(13, color: Brand.textMuted),
                    ),
                  ),
                  Text(
                    "Rs ${_money.format(item.lineTotal)}",
                    style: Brand.sans(13, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          Divider(color: Brand.hairlineSoft),
          _row(
            "Delivery",
            order.deliveryMethod == "delivery" ? "Delivery" : "Pickup",
          ),
          if ((order.deliveryAddress ?? "").isNotEmpty)
            _row("Address", order.deliveryAddress!),
          if (order.payment != null)
            _row(
              "Payment",
              "${order.payment!.method} · ${order.payment!.status}",
            ),
          Divider(color: Brand.hairlineSoft),
          _row("Total", "Rs ${_money.format(order.grandTotal)}", strong: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Brand.s8),
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
              style: Brand.sans(
                13,
                weight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIcon(String state) {
    final cancelled = state == "cancelled";
    final complete = state == "complete";
    final current = state == "current";
    final upcoming = state == "upcoming";
    final color = cancelled
        ? Colors.redAccent
        : complete
        ? Colors.greenAccent.shade400
        : current
        ? Brand.gold
        : Brand.textMuted.withValues(alpha: 0.45);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: current ? 0.22 : 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: current ? Brand.gold : Colors.transparent,
          width: current ? 2 : 1,
        ),
      ),
      child: Icon(
        cancelled
            ? Icons.close
            : complete
            ? Icons.check
            : upcoming
            ? Icons.circle
            : Icons.radio_button_checked,
        size: complete || cancelled ? 20 : 10,
        color: color,
      ),
    );
  }

  List<OrderTrackingStep> _fallbackSteps(String status) {
    final normalized = switch (status) {
      "awaiting_verification" => "pending",
      "processing" => "dispatched",
      _ => status,
    };
    const keys = ["pending", "confirmed", "dispatched", "delivered"];
    const labels = {
      "pending": "Order pending",
      "confirmed": "Order confirmed",
      "dispatched": "Order dispatched",
      "delivered": "Order delivered",
    };
    final currentIndex = keys.indexOf(normalized);

    return [
      for (var i = 0; i < keys.length; i++)
        OrderTrackingStep(
          key: keys[i],
          label: labels[keys[i]]!,
          state: normalized == "cancelled"
              ? "cancelled"
              : i < currentIndex
              ? "complete"
              : i == currentIndex
              ? "current"
              : "upcoming",
        ),
    ];
  }
}

/// Order numbers look like `IBE-YYDDD-NNNNNNNN`, for example
/// `IBE-26249-40571836`.
///
/// `IBE-` is added automatically and the value is always upper case, so the
/// customer only types the 13 digits and can paste any casing or spacing.
class OrderNumberFormatter {
  static const String prefix = "IBE";
  static const String legacyPrefix = "ORD";

  /// 5 date digits + 8 serial digits.
  static const int _dateDigits = 5;
  static const int _serialDigits = 8;
  static const int _totalDigits = _dateDigits + _serialDigits;

  static String format(String value) {
    var cleaned =
        value.replaceAll(RegExp(r"[^A-Za-z0-9]"), "").toUpperCase();

    if (cleaned.isEmpty) return "";

    // Orders placed before this format keep working.
    if (cleaned.startsWith(legacyPrefix)) {
      final body = cleaned.substring(legacyPrefix.length);
      final first = body.length > 8 ? body.substring(0, 8) : body;
      final rest = body.length > 8
          ? body.substring(8, body.length > 18 ? 18 : body.length)
          : "";
      return rest.isEmpty
          ? "$legacyPrefix-$first"
          : "$legacyPrefix-$first-$rest";
    }

    if (cleaned.startsWith(prefix)) {
      cleaned = cleaned.substring(prefix.length);
    }

    var digits = cleaned.replaceAll(RegExp(r"\D"), "");
    if (digits.isEmpty) return "";
    if (digits.length > _totalDigits) {
      digits = digits.substring(0, _totalDigits);
    }

    final date = digits.length > _dateDigits
        ? digits.substring(0, _dateDigits)
        : digits;
    final serial =
        digits.length > _dateDigits ? digits.substring(_dateDigits) : "";

    return serial.isEmpty ? "$prefix-$date" : "$prefix-$date-$serial";
  }
}

class OrderNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = OrderNumberFormatter.format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
