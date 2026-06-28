import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

import "../theme/brand.dart";

/// Reusable luxury UI building blocks (background, cards, shimmer, headers,
/// entrance animations, premium bottom nav). Import this one file to access the
/// whole kit.

/// Full-bleed luxury gradient background with subtle gold glows. Wrap a screen
/// body in this and place your scrollable content as [child].
class BrandBackground extends StatelessWidget {
  final Widget child;
  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Brand.pageGradient),
      child: Stack(
        children: [
          Positioned(top: -130, right: -90, child: _glow(Brand.gold.withValues(alpha: 0.12), 260)),
          Positioned(bottom: -150, left: -80, child: _glow(Brand.goldDeep.withValues(alpha: 0.10), 240)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _glow(Color c, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
          ),
        ),
      );
}

/// Premium surface card: gradient fill, gold hairline, soft shadow, optional tap
/// with a subtle press-scale.
class BrandCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool gold;
  final double radius;
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Brand.s16),
    this.onTap,
    this.gold = false,
    this.radius = Brand.rLg,
  });

  @override
  State<BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<BrandCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _down ? 0.98 : 1.0,
      duration: Brand.fast,
      curve: Brand.easeOut,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          gradient: Brand.cardGradient,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: widget.gold ? Brand.gold.withValues(alpha: 0.45) : Brand.hairline,
          ),
          boxShadow: Brand.cardShadow,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}

/// Skeleton shimmer block for loading states (>300ms).
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1300.ms,
          color: Brand.gold.withValues(alpha: 0.18),
        );
  }
}

/// Eyebrow + serif title with a gold accent bar.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.eyebrow, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: Brand.goldGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: Brand.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(eyebrow!.toUpperCase(), style: Brand.label(10, color: Brand.gold, spacing: 1.4)),
              Text(title, style: Brand.display(19, weight: FontWeight.w700)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Pulsing status dot (e.g. "LIVE").
class LiveDot extends StatelessWidget {
  final Color color;
  final double size;
  const LiveDot({super.key, this.color = Brand.up, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
          begin: 0.35,
          end: 1.0,
          duration: 850.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Entrance animation helper: fade + gentle rise. Use [delayMs] to stagger lists.
extension BrandEntrance on Widget {
  Widget entrance({int delayMs = 0}) => animate(delay: delayMs.ms)
      .fadeIn(duration: Brand.base, curve: Brand.easeOut)
      .slideY(begin: 0.10, end: 0, duration: Brand.base, curve: Brand.easeOut);
}

/// A single item in [PremiumBottomNav].
class BrandNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Optional custom icon widget (e.g. a brand glyph). When set, it replaces
  /// the [icon]/[activeIcon] glyph inside the nav cell.
  final Widget? customIcon;

  const BrandNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.customIcon,
  });
}

/// Animated, gold-accented bottom navigation bar. Stateless — owner supplies
/// [currentIndex] and handles [onTap].
class PremiumBottomNav extends StatelessWidget {
  final List<BrandNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const PremiumBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Brand.card.withValues(alpha: 0.97),
        border: Border(top: BorderSide(color: Brand.hairline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavCell(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  final BrandNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavCell({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Brand.rMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Brand.base,
              curve: Brand.easeOut,
              padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected ? Brand.goldGradient : null,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected ? Brand.goldGlow : null,
              ),
              child: item.customIcon ??
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color: selected ? const Color(0xFF1A1207) : Brand.textMuted,
                  ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: Brand.base,
              style: Brand.sans(
                10.5,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Brand.gold : Brand.textFaint,
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
