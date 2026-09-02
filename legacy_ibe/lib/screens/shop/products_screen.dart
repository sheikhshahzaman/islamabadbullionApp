import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../models/shop_models.dart";
import "../../providers/cart_provider.dart";
import "../../providers/shop_provider.dart";
import "../../theme/brand.dart";
import "../../widgets/brand_kit.dart";
import "cart_screen.dart";

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _money = NumberFormat("#,##0");
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCatalog(silent: false);
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshCatalog(),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshCatalog({bool force = true, bool silent = true}) async {
    if (!mounted) return;
    final shop = context.read<ShopProvider>();
    await shop.load(refresh: force, silent: silent);
    if (!mounted) return;
    context.read<CartProvider>().refreshProducts(shop.products);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Brand.teal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Shop Gold & Silver",
          style: Brand.display(20, weight: FontWeight.w700),
        ),
        actions: [_CartButton(count: cart.itemCount)],
      ),
      body: BrandBackground(
        child: RefreshIndicator(
          color: Brand.gold,
          backgroundColor: Brand.cardHigh,
          onRefresh: () async {
            await _refreshCatalog(silent: false);
          },
          child: _body(shop, cart),
        ),
      ),
    );
  }

  Widget _body(ShopProvider shop, CartProvider cart) {
    if (shop.loading && shop.products.isEmpty) {
      return _loadingSkeleton(shop);
    }

    if (shop.error != null && shop.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Brand.s24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off,
            size: 52,
            color: Brand.gold.withValues(alpha: 0.7),
          ).entrance(),
          const SizedBox(height: Brand.s16),
          Center(
            child: Text(
              shop.error!,
              textAlign: TextAlign.center,
              style: Brand.sans(14, color: Brand.textMuted),
            ),
          ).entrance(delayMs: 50),
          const SizedBox(height: Brand.s16),
          Center(
            child: FilledButton(
              style: _goldButtonStyle(),
              onPressed: () => shop.load(refresh: true),
              child: const Text("Retry"),
            ),
          ).entrance(delayMs: 80),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _categoryChips(shop)),
        if (shop.loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Brand.s12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Brand.gold,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        if (shop.products.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _emptyStateContent())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s12,
              Brand.s4,
              Brand.s12,
              Brand.s24,
            ),
            sliver: SliverList.separated(
              itemCount: shop.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
              itemBuilder: (context, index) => _ProductCard(
                product: shop.products[index],
                money: _money,
              ).entrance(delayMs: math.min(index, 8) * 50),
            ),
          ),
      ],
    );
  }

  Widget _emptyStateContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Brand.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diamond_outlined,
            size: 56,
            color: Brand.gold.withValues(alpha: 0.7),
          ).entrance(),
          const SizedBox(height: Brand.s16),
          Center(
            child: Text(
              "No products available yet",
              textAlign: TextAlign.center,
              style: Brand.sans(15, color: Brand.textMuted),
            ),
          ).entrance(delayMs: 70),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _loadingSkeleton(ShopProvider shop) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _categoryChips(shop)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Brand.s12,
            Brand.s4,
            Brand.s12,
            Brand.s24,
          ),
          sliver: SliverList.separated(
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
            itemBuilder: (context, index) =>
                const _SkeletonCard().entrance(delayMs: 0),
          ),
        ),
      ],
    );
  }

  Widget _categoryChips(ShopProvider shop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        Brand.s12,
        Brand.s12,
        Brand.s12,
        Brand.s8,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: Brand.s8),
            child: _CategoryChip(
              label: "All",
              selected: shop.selectedCategorySlug == null,
              onTap: () => shop.selectCategory(null),
            ),
          ),
          for (final c in shop.categories)
            Padding(
              padding: const EdgeInsets.only(right: Brand.s8),
              child: _CategoryChip(
                label: c.name,
                selected: shop.selectedCategorySlug == c.slug,
                onTap: () => shop.selectCategory(c.slug),
              ),
            ),
        ],
      ),
    );
  }
}

ButtonStyle _goldButtonStyle() => FilledButton.styleFrom(
  backgroundColor: Brand.gold,
  foregroundColor: const Color(0xFF1A1207),
  disabledBackgroundColor: Brand.gold.withValues(alpha: 0.25),
  disabledForegroundColor: Brand.text.withValues(alpha: 0.4),
  textStyle: Brand.sans(13, weight: FontWeight.w800),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rSm)),
);

/// Gold pill chip for category filtering. Selected = gold fill + dark text;
/// unselected = gold hairline outline.
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: Brand.base,
          curve: Brand.easeOut,
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Brand.s16),
          decoration: BoxDecoration(
            gradient: selected ? Brand.goldGradient : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : Brand.hairline,
            ),
            boxShadow: selected ? Brand.goldGlow : null,
          ),
          child: Text(
            label,
            style: Brand.sans(
              13,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? const Color(0xFF1A1207) : Brand.textMuted,
            ),
          ),
        ),
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
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: Brand.gold,
        textColor: const Color(0xFF1A1207),
        label: Text("$count"),
        child: const Icon(Icons.shopping_cart_outlined, color: Brand.text),
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
    final price = product.currentPrice;

    return BrandCard(
      padding: const EdgeInsets.all(Brand.s12),
      radius: Brand.rMd,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Brand.rSm),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Brand.rSm),
                border: Border.all(color: Brand.hairlineSoft),
              ),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: Brand.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Brand.sans(
                    15,
                    weight: FontWeight.w600,
                    color: Brand.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.weight.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      product.weight,
                      style: Brand.sans(12, color: Brand.textMuted),
                    ),
                  ),
                const SizedBox(height: Brand.s4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        price != null
                            ? "Rs ${money.format(price)}"
                            : "Price on request",
                        style: price != null
                            ? Brand.number(17, color: Brand.gold)
                            : Brand.sans(
                                13,
                                color: Brand.textMuted,
                                weight: FontWeight.w600,
                              ),
                      ),
                    ),
                    if (product.discountLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Brand.gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Brand.hairline),
                        ),
                        child: Text(
                          product.discountLabel!,
                          style: Brand.label(
                            10,
                            color: Brand.goldBright,
                            spacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Brand.s8),
          FilledButton.icon(
            style: _goldButtonStyle().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
            ),
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
    );
  }

  Widget _placeholder() => Container(
    decoration: BoxDecoration(gradient: Brand.cardGradient),
    child: Icon(
      product.metal == "silver" ? Icons.circle_outlined : Icons.toll,
      color: Brand.gold.withValues(alpha: 0.6),
    ),
  );
}

/// Shimmer skeleton mirroring the [_ProductCard] layout for the loading state.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      padding: const EdgeInsets.all(Brand.s12),
      radius: Brand.rMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 68, height: 68, radius: Brand.rSm),
          const SizedBox(width: Brand.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: Brand.s8),
                ShimmerBox(width: 90, height: 11),
                SizedBox(height: Brand.s12),
                ShimmerBox(width: 120, height: 16),
              ],
            ),
          ),
          const SizedBox(width: Brand.s8),
          const ShimmerBox(width: 64, height: 44, radius: Brand.rSm),
        ],
      ),
    );
  }
}
