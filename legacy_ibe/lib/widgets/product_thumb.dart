import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

import "../models/shop_models.dart";
import "../theme/brand.dart";

/// Product picture for list tiles.
///
/// Uses the server's small thumbnail and a disk-backed cache. `Image.network`
/// only caches in memory, so every cold start re-downloaded ~500 KB per product
/// and pictures appeared seconds late. Now they download once and stay cached.
class ProductThumb extends StatelessWidget {
  final ShopProduct product;
  final double size;

  const ProductThumb({super.key, required this.product, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = product.thumbUrl ?? product.imageUrl;

    if (url == null || url.isEmpty) {
      return _Placeholder(size: size);
    }

    // Decode at roughly the drawn size to keep memory small on long lists.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: pixels,
      memCacheHeight: pixels,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => _Placeholder(size: size, shimmer: true),
      errorWidget: (_, _, _) => _Placeholder(size: size),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
  final bool shimmer;

  const _Placeholder({required this.size, this.shimmer = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.black.withValues(alpha: shimmer ? 0.06 : 0.10),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: size * 0.4,
        color: Brand.textMuted.withValues(alpha: shimmer ? 0.25 : 0.45),
      ),
    );
  }
}
