import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../../models/shop_models.dart";

class OrderConfirmationScreen extends StatelessWidget {
  final ShopOrder order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat("#,##0");

    return Scaffold(
      appBar: AppBar(title: const Text("Order placed")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
          const SizedBox(height: 12),
          Center(
            child: Text("Thank you, ${order.customerName}!",
                style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Your payment is being verified. Our team will contact you "
              "on ${order.customerPhone} shortly.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(theme, "Order number", order.orderNumber, mono: true),
                  _row(theme, "Status", _statusLabel(order.status)),
                  if (order.payment != null)
                    _row(theme, "Payment method",
                        _methodLabel(order.payment!.method)),
                  const Divider(height: 20),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.isMetalLine
                                ? item.productName
                                : "${item.productName} × ${item.quantityLabel}"),
                          ),
                          Text("Rs ${money.format(item.lineTotal)}"),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text("Total",
                            style: theme.textTheme.titleMedium),
                      ),
                      Text(
                        "Rs ${money.format(order.totalAmount)}",
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Keep your order number safe — you can share it with our "
            "support team to check your order status anytime.",
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value,
      {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? "monospace" : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        "pending" => "Pending",
        "awaiting_verification" => "Awaiting payment verification",
        "confirmed" => "Confirmed",
        "processing" => "Processing",
        "delivered" => "Delivered",
        _ => status,
      };

  String _methodLabel(String method) => switch (method) {
        "easypaisa" => "EasyPaisa",
        "jazzcash" => "JazzCash",
        "raast" => "Raast",
        "bank_transfer" => "Bank Transfer",
        _ => method,
      };
}
