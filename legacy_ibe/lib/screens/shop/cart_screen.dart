import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../providers/cart_provider.dart";
import "../../providers/shop_provider.dart";
import "checkout_screen.dart";

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final money = NumberFormat("#,##0");
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping Cart"),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => cart.clear(),
              child: const Text("Clear"),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 56, color: Colors.grey.shade500),
                  const SizedBox(height: 12),
                  const Text("Your cart is empty"),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cart.lines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final line = cart.lines[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: line.product.imageUrl != null
                                ? Image.network(
                                    line.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _cartImagePlaceholder(line.product.metal),
                                  )
                                : _cartImagePlaceholder(line.product.metal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.product.name,
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                "Rs ${money.format(line.product.currentPrice ?? 0)} each",
                                style: theme.textTheme.bodySmall,
                              ),
                              if (line.product.packagingCharge > 0)
                                Text(
                                  "+ Rs ${money.format(line.product.packagingCharge)} packaging",
                                  style: theme.textTheme.bodySmall,
                                )
                              else
                                Text(
                                  "Free packaging",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF2E9E5B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                "Rs ${money.format(line.lineTotal)}",
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context
                              .read<CartProvider>()
                              .decrease(line.product.id),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text("${line.quantity}",
                            style: theme.textTheme.titleMedium),
                        IconButton(
                          onPressed: () => context
                              .read<CartProvider>()
                              .increase(line.product.id),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          onPressed: () => context
                              .read<CartProvider>()
                              .remove(line.product.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Subtotal", style: theme.textTheme.bodySmall),
                          Text(
                            "Rs ${money.format(cart.subtotal)}",
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        final api = context.read<ShopProvider>().api;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              estimatedTotal: cart.subtotal,
                              onCreateOrder: (name, phone) => api.createOrder(
                                customerName: name,
                                customerPhone: phone,
                                productQuantities: cart.productQuantities,
                              ),
                              onOrderComplete: () => cart.clear(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Checkout"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _cartImagePlaceholder(String metal) => Container(
        color: metal == "silver"
            ? const Color(0xFFD9D9D9)
            : const Color(0xFFF0CBA3),
        child: Icon(
          metal == "silver" ? Icons.circle_outlined : Icons.toll,
          color: metal == "silver" ? Colors.black45 : Colors.black54,
        ),
      );
}
