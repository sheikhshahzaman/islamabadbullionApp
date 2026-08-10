import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";
import "../theme/brand.dart";
import "../widgets/brand_kit.dart";
import "buy_screen.dart";
import "sell_screen.dart";
import "legal_page_screen.dart";
import "zakat_screen.dart";
import "shop/products_screen.dart";
import "shop/order_tracking_screen.dart";
import "shop/verify_screen.dart";

/// "More" hub. Buy, Sell and tools live here; Shop, Spot, WhatsApp and Contact
/// are on the bottom navigation bar.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const Color _bg = Color(0xFF1A5249);

  String _t(BuildContext context, String en, String ur) =>
      context.watch<AppSettings>().isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;

    final quickLinks = <_MoreItem>[
      _MoreItem(
        icon: Icons.shopping_bag_outlined,
        title: _t(context, "Buy Gold / Silver", "سونا / چاندی خریدیں"),
        subtitle: _t(
          context,
          "Pick metal, karat and weight — see the buy price",
          "دھات، کیرٹ اور وزن منتخب کریں — خرید قیمت دیکھیں",
        ),
        onTap: () {
          final title = isUrdu ? "سونا / چاندی خریدیں" : "Buy Gold / Silver";
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Brand.teal,
                appBar: AppBar(title: Text(title)),
                body: const BuyScreen(),
              ),
            ),
          );
        },
      ),
      _MoreItem(
        icon: Icons.sell_outlined,
        title: _t(context, "Sell Gold / Silver", "سونا / چاندی بیچیں"),
        subtitle: _t(
          context,
          "Pick metal, karat and weight — see the sell price",
          "دھات، کیرٹ اور وزن منتخب کریں — فروخت قیمت دیکھیں",
        ),
        onTap: () {
          final title = isUrdu ? "سونا / چاندی بیچیں" : "Sell Gold / Silver";
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Brand.teal,
                appBar: AppBar(title: Text(title)),
                body: const SellScreen(),
              ),
            ),
          );
        },
      ),
      _MoreItem(
        icon: Icons.storefront_outlined,
        title: _t(context, "Products", "پروڈکٹس"),
        subtitle: _t(
          context,
          "Browse bars and coins, order with delivery",
          "بارز اور سکے دیکھیں، ڈیلیوری کے ساتھ آرڈر کریں",
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProductsScreen())),
      ),
      _MoreItem(
        icon: Icons.local_shipping_outlined,
        title: _t(context, "Track Order", "آرڈر ٹریک کریں"),
        subtitle: _t(
          context,
          "Enter your order number to see the latest status",
          "اپنا آرڈر نمبر درج کر کے تازہ اسٹیٹس دیکھیں",
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OrderTrackingScreen())),
      ),
      _MoreItem(
        icon: Icons.qr_code_scanner,
        title: _t(context, "Scan QR Code", "کیو آر کوڈ اسکین کریں"),
        subtitle: _t(
          context,
          "Scan the sticker on your item to check authenticity",
          "اپنی چیز پر لگے اسٹیکر کو اسکین کر کے اصلیت جانچیں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VerifyScreen(autoScan: true)),
        ),
      ),
      _MoreItem(
        icon: Icons.verified_outlined,
        title: _t(context, "Verify Serial Number", "سیریل نمبر کی تصدیق کریں"),
        subtitle: _t(
          context,
          "Enter the serial printed on your item to verify it",
          "اپنی چیز پر درج سیریل نمبر سے تصدیق کریں",
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VerifyScreen())),
      ),
      _MoreItem(
        icon: Icons.calculate_outlined,
        title: _t(context, "Zakat Calculator", "زکوٰۃ کیلکولیٹر"),
        subtitle: _t(
          context,
          "Estimate your zakat based on current rates",
          "موجودہ ریٹ کے مطابق زکوٰۃ کا حساب لگائیں",
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ZakatScreen())),
      ),
    ];

    final legal = <_MoreItem>[
      _MoreItem(
        icon: Icons.info_outline,
        title: _t(context, "About Us", "ہمارے بارے میں"),
        subtitle: _t(
          context,
          "Learn more about our company",
          "ہماری کمپنی کے بارے میں مزید جانیں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LegalPageScreen(
              slug: "about-us",
              title: _t(context, "About Us", "ہمارے بارے میں"),
            ),
          ),
        ),
      ),
      _MoreItem(
        icon: Icons.report_gmailerrorred_outlined,
        title: _t(context, "Disclaimer", "دستبرداری"),
        subtitle: _t(
          context,
          "Important notes about rates and information",
          "ریٹس اور معلومات سے متعلق اہم نوٹس",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LegalPageScreen(
              slug: "disclaimer",
              title: _t(context, "Disclaimer", "دستبرداری"),
            ),
          ),
        ),
      ),
      _MoreItem(
        icon: Icons.privacy_tip_outlined,
        title: _t(context, "Privacy Policy", "پرائیویسی پالیسی"),
        subtitle: _t(
          context,
          "How we handle your data",
          "ہم آپ کے ڈیٹا کو کیسے ہینڈل کرتے ہیں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LegalPageScreen(
              slug: "privacy-policy",
              title: _t(context, "Privacy Policy", "پرائیویسی پالیسی"),
            ),
          ),
        ),
      ),
      _MoreItem(
        icon: Icons.description_outlined,
        title: _t(context, "Terms & Conditions", "شرائط و ضوابط"),
        subtitle: _t(
          context,
          "Read our terms of use",
          "استعمال کی شرائط پڑھیں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LegalPageScreen(
              slug: "terms-and-conditions",
              title: _t(context, "Terms & Conditions", "شرائط و ضوابط"),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: BrandBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s16,
              Brand.s16,
              Brand.s24,
            ),
            children: [
              _headerCard(context, isUrdu).entrance(),
              const SizedBox(height: Brand.s24),
              SectionHeader(
                title: _t(context, "Quick Links", "فوری لنکس"),
              ).entrance(delayMs: 60),
              const SizedBox(height: Brand.s12),
              _groupCard(quickLinks).entrance(delayMs: 120),
              const SizedBox(height: Brand.s24),
              SectionHeader(
                title: _t(context, "Legal", "قانونی"),
              ).entrance(delayMs: 180),
              const SizedBox(height: Brand.s12),
              _groupCard(legal).entrance(delayMs: 240),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context, bool isUrdu) {
    return BrandCard(
      gold: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: Brand.goldGradient,
              borderRadius: BorderRadius.circular(Brand.rMd),
              boxShadow: Brand.goldGlow,
            ),
            child: const Icon(Icons.menu, size: 24, color: Color(0xFF1A1207)),
          ),
          const SizedBox(width: Brand.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: isUrdu
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  _t(context, "More", "مزید"),
                  style: Brand.display(22, color: Brand.gold),
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: Brand.s4),
                Text(
                  _t(
                    context,
                    "Shop, verify your item, tools & legal information",
                    "شاپ، تصدیق، ٹولز اور قانونی معلومات",
                  ),
                  style: Brand.sans(13, color: Brand.textMuted, height: 1.35),
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(List<_MoreItem> items) {
    return BrandCard(
      padding: EdgeInsets.zero,
      radius: Brand.rLg,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Brand.rLg),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _MoreTile(item: items[i]),
              if (i != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: Brand.s16,
                  endIndent: Brand.s16,
                  color: Brand.hairlineSoft,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _MoreTile extends StatelessWidget {
  static const Color _accent = Color(0xFFdfa273);

  final _MoreItem item;

  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: item.onTap,
        splashColor: Brand.gold.withValues(alpha: 0.12),
        highlightColor: Brand.gold.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Brand.s16,
            vertical: Brand.s16,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Brand.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Brand.rSm),
                  border: Border.all(color: Brand.gold.withValues(alpha: 0.30)),
                ),
                child: Icon(item.icon, size: 22, color: Brand.gold),
              ),
              const SizedBox(width: Brand.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: isUrdu
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Brand.sans(
                        15.5,
                        color: Brand.text,
                        weight: FontWeight.w700,
                      ),
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: Brand.s4),
                    Text(
                      item.subtitle,
                      style: Brand.sans(
                        12.5,
                        color: Brand.textMuted,
                        height: 1.35,
                      ),
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Brand.s12),
              Icon(Icons.chevron_right, color: _accent.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}
