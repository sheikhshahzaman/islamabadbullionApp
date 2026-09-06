import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../../models/shop_models.dart";
import "../../providers/site_config_provider.dart";
import "order_tracking_screen.dart";

class OrderConfirmationScreen extends StatelessWidget {
  final ShopOrder order;
  const OrderConfirmationScreen({super.key, required this.order});

  Future<void> _openWhatsApp(String number, String orderNumber) async {
    final digits = number.replaceAll(RegExp(r"[^0-9]"), "");
    final text = Uri.encodeComponent(
      "Hi, I placed an order #$orderNumber. Please confirm.",
    );
    await launchUrl(
      Uri.parse("https://wa.me/$digits?text=$text"),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callPhone(String number) async {
    await launchUrl(Uri.parse("tel:$number"));
  }

  Future<void> _copyOrderNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: order.orderNumber));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Order ID copied")));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat("#,##0");
    final config = context.watch<SiteConfigProvider>().config;

    return Scaffold(
      appBar: AppBar(title: const Text("Order placed")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "Thank you, ${order.customerName}!",
              style: theme.textTheme.titleLarge,
            ),
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
                  Text("Order ID", style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          order.orderNumber,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFamily: "monospace",
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Copy order ID",
                        onPressed: () => _copyOrderNumber(context),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Copy this order ID. You can use it on the Track Order page to verify the latest status anytime.",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(theme, "Order number", order.orderNumber, mono: true),
                  _row(theme, "Status", _statusLabel(order.status)),
                  if (order.payment != null)
                    _row(
                      theme,
                      "Payment method",
                      _methodLabel(order.payment!.method),
                    ),
                  const Divider(height: 20),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.isMetalLine
                                      ? item.productName
                                      : "${item.productName} × ${item.quantityLabel}",
                                ),
                                if (item.packagingCharge > 0)
                                  Text(
                                    "+ Rs ${money.format(item.packagingCharge)} packaging × ${item.quantityLabel}",
                                    style: theme.textTheme.bodySmall,
                                  )
                                else if (!item.isMetalLine)
                                  Text(
                                    "Free packaging",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF2E9E5B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text("Rs ${money.format(item.lineTotal)}"),
                        ],
                      ),
                    ),
                  _row(
                    theme,
                    "Delivery",
                    order.deliveryMethod == "delivery"
                        ? "Delivery"
                        : "Pickup from our shop",
                  ),
                  if (order.deliveryMethod == "delivery" &&
                      (order.deliveryAddress ?? "").isNotEmpty)
                    _row(theme, "Address", order.deliveryAddress!),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Text("Items Total")),
                      Text("Rs ${money.format(order.totalAmount)}"),
                    ],
                  ),
                  if (order.deliveryCharge > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Expanded(child: Text("Delivery Charge")),
                          Text("Rs ${money.format(order.deliveryCharge)}"),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Total",
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        "Rs ${money.format(order.grandTotal)}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Contact Us", style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    "Questions about your order? Reach us here.",
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  if (config.contactWhatsapp.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF25D366),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: const Text("WhatsApp"),
                      subtitle: Text(config.contactWhatsapp),
                      onTap: () => _openWhatsApp(
                        config.contactWhatsapp,
                        order.orderNumber,
                      ),
                    ),
                  if (config.contactPhone.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.call)),
                      title: const Text("Call Us"),
                      subtitle: Text(config.contactPhone),
                      onTap: () => _callPhone(config.contactPhone),
                    ),
                  if (config.contactAddress.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.place_outlined),
                      ),
                      title: const Text("Visit Us"),
                      subtitle: Text(config.contactAddress),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    OrderTrackingScreen(initialOrderNumber: order.orderNumber),
              ),
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text("Track this order"),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool mono = false,
  }) {
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
    "pending" => "Order pending",
    "awaiting_verification" => "Order pending",
    "confirmed" => "Order confirmed",
    "processing" => "Order dispatched",
    "dispatched" => "Order dispatched",
    "delivered" => "Order delivered",
    "cancelled" => "Order cancelled",
    _ => status,
  };

  String _methodLabel(String method) => switch (method) {
    "easypaisa" => "EasyPaisa",
    "jazzcash" => "JazzCash",
    "raast" => "Raast",
    "bank_transfer" => "Bank Transfer",
    "cash" => "Cash at Shop",
    "cod" => "Cash on Delivery",
    _ => method,
  };
}
