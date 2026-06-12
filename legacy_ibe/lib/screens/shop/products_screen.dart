import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../models/shop_models.dart";
import "../../providers/cart_provider.dart";
import "../../providers/shop_provider.dart";
import "cart_screen.dart";

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _money = NumberFormat("#,##0");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Gold & Silver"),
        actions: [_CartButton(count: cart.itemCount)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await shop.load(refresh: true);
          if (context.mounted) {
            context.read<CartProvider>().refreshProducts(shop.products);
          }
        },
        child: _body(shop, cart),
      ),
    );
  }

  Widget _body(ShopProvider shop, CartProvider cart) {
    if (shop.loading && shop.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shop.error != null && shop.products.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Center(child: Text(shop.error!)),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: () => shop.load(refresh: true),
              child: const Text("Retry"),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _categoryChips(shop)),
        if (shop.loading)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(minHeight: 2),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          sliver: SliverList.separated(
            itemCount: shop.products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ProductCard(product: shop.products[index], money: _money),
          ),
        ),
      ],
    );
  }

  Widget _categoryChips(ShopProvider shop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text("All"),
              selected: shop.selectedCategorySlug == null,
              onSelected: (_) => shop.selectCategory(null),
            ),
          ),
          for (final c in shop.categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: shop.selectedCategorySlug == c.slug,
                onSelected: (_) => shop.selectCategory(c.slug),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  const _CartButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Cart",
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text("$count"),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ShopProduct product;
  final NumberFormat money;

  const _ProductCard({required this.product, required this.money});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = product.currentPrice;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(theme),
                      )
                    : _placeholder(theme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.weight.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        product.weight,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price != null
                              ? "Rs ${money.format(price)}"
                              : "Price on request",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (product.discountLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.discountLabel!,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: price == null
                  ? null
                  : () {
                      context.read<CartProvider>().add(product);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text("${product.name} added to cart"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                    },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          product.metal == "silver" ? Icons.circle_outlined : Icons.toll,
          color: theme.colorScheme.outline,
        ),
      );
}
