// lib/screens/about_us_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";
import "../l10n/app_localizations.dart";

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Match app theme (Home/Buy/Sell)
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  String _t(BuildContext context, String en, String ur) {
    final isUrdu = context.read<AppSettings>().isUrdu;
    return isUrdu ? ur : en;
  }

  @override
  Widget build(BuildContext context) {
    // kept for consistency with your localization setup
    AppLocalizations.of(context);

    final isUrdu = context.watch<AppSettings>().isUrdu;

    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: _accent,
    );

    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.92),
    );

    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      height: 1.45,
      color: Colors.white70,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _t(context, "About Us", "ہمارے بارے میں"),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: _card,
                border: Border.all(color: _accent.withOpacity(0.30)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    color: Colors.black.withOpacity(0.20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(context, "Legacy Jewellers", "لیگیسی جیولرز"),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(context, "Timeless craftsmanship since 2015", "2015 سے لازوال کاریگری"),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t(
                      context,
                      "Established in 2015 with a vision to create timeless jewelry that transcends generations. For nearly a decade, we have blended traditional techniques with contemporary design—focused on quality, authenticity, and customer satisfaction.",
                      "لیگیسی جیولرز 2015 میں اس وژن کے ساتھ قائم ہوا کہ ایسی زیورات تیار کیے جائیں جو نسلوں تک اپنی خوبصورتی برقرار رکھیں۔ تقریباً ایک دہائی سے ہم روایتی کاریگری کو جدید ڈیزائن کے ساتھ ملا کر معیار، اصلیت اور صارفین کی تسکین کو اولین ترجیح دیتے ہیں۔",
                    ),
                    style: bodyStyle,
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _SectionTitle(
              title: _t(context, "Our Premium Services", "ہماری پریمیم سروسز"),
              subtitle: _t(
                context,
                "Exceptional services that make us your perfect jewelry partner",
                "ایسی خدمات جو ہمیں آپ کا بہترین انتخاب بناتی ہیں",
              ),
              accentColor: _accent,
            ),
            const SizedBox(height: 10),

            // Premium Services (cards)
            _Grid(
              children: [
                _FeatureCard(
                  icon: Icons.receipt_long,
                  title: _t(context, "Complete Transparency", "مکمل شفافیت"),
                  desc: _t(
                    context,
                    "Transparent pricing with detailed invoices showing gold and stone weights, making charges, and taxes.",
                    "شفاف قیمتیں اور تفصیلی رسیدیں جن میں سونے اور پتھروں کے وزن، میکنگ چارجز اور ٹیکس واضح ہوں۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.verified,
                  title: _t(context, "Assured Lifetime Maintenance", "لائف ٹائم مینٹیننس"),
                  desc: _t(
                    context,
                    "Complimentary lifetime maintenance across all our stores for lasting beauty and peace of mind.",
                    "تمام اسٹورز پر مفت لائف ٹائم مینٹیننس تاکہ آپ کے زیورات ہمیشہ خوبصورت رہیں۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.balance,
                  title: _t(context, "Fair Price Policy", "منصفانہ قیمت پالیسی"),
                  desc: _t(
                    context,
                    "Impeccable gold designs at reasonable making charges, ensuring best value for your purchase.",
                    "بہترین ڈیزائن، مناسب میکنگ چارجز، اور آپ کی خریداری کے لیے بہترین ویلیو۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.public,
                  title: _t(context, "Responsibly Sourced Products", "ذمہ دارانہ سورسنگ"),
                  desc: _t(
                    context,
                    "Responsible acquisition standards and manufacturing in compliance with local laws.",
                    "ذمہ دارانہ معیار کے مطابق حصول اور مقامی قوانین کے مطابق تیاری۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.diamond,
                  title: _t(context, "Tested & Certified Diamonds", "تصدیق شدہ ہیرے"),
                  desc: _t(
                    context,
                    "Every diamond is rigorously tested and certified by international laboratories.",
                    "ہر ہیرے کی سخت جانچ اور بین الاقوامی لیبز سے سرٹیفیکیشن۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.shield_outlined,
                  title: _t(context, "Complimentary Insurance", "مفت انشورنس"),
                  desc: _t(
                    context,
                    "One year complimentary coverage for repairs if jewelry breaks or stones become loose.",
                    "ایک سال کی مفت کوریج—اگر زیور ٹوٹ جائے یا پتھر ڈھیلے ہوں تو مرمت شامل۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.verified_user,
                  title: _t(context, "100% BIS Hallmarked Gold", "100% BIS ہال مارکڈ گولڈ"),
                  desc: _t(
                    context,
                    "BIS 916 hallmark certification to guarantee purity and authenticity.",
                    "BIS 916 ہال مارک—خالص پن اور اصلیت کی ضمانت۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.swap_horiz,
                  title: _t(context, "Zero Deduction Gold Exchange", "زیرو ڈیڈکشن ایکسچینج"),
                  desc: _t(
                    context,
                    "100% value assurance without deductions when you exchange 22K gold jewelry with us.",
                    "22K زیورات کے ایکسچینج پر بغیر کسی کٹوتی کے 100% ویلیو کی یقین دہانی۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.currency_exchange,
                  title: _t(context, "Guaranteed Buyback", "گارنٹیڈ بائے بیک"),
                  desc: _t(
                    context,
                    "Buyback guarantee for all gold and diamond jewelry for maximum return.",
                    "تمام گولڈ اور ڈائمنڈ زیورات پر بائے بیک گارنٹی—بہترین ریٹرن۔",
                  ),
                ),
                _FeatureCard(
                  icon: Icons.handshake,
                  title: _t(context, "Fair Labour Practices", "منصفانہ لیبر پریکٹسز"),
                  desc: _t(
                    context,
                    "Fair wages, benefits, and working conditions for artisans and craftsmen.",
                    "ہمارے کاریگروں کے لیے منصفانہ اجرت، سہولتیں اور کام کی بہتر شرائط۔",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _SectionTitle(
              title: _t(context, "Special Offers & Benefits", "خصوصی آفرز اور فوائد"),
              subtitle: _t(
                context,
                "Exclusive benefits that make your shopping experience even more special",
                "ایسے فوائد جو آپ کی خریداری کو مزید خاص بناتے ہیں",
              ),
              accentColor: _accent,
            ),
            const SizedBox(height: 10),

            _ListCard(
              children: [
                _ListTileRow(
                  icon: Icons.lock_clock,
                  title: _t(context, "Gold Rate Protection", "گولڈ ریٹ پروٹیکشن"),
                  desc: _t(
                    context,
                    "Pay 35% in advance and get protection against rising gold rates.",
                    "35% ایڈوانس دیں اور گولڈ ریٹ بڑھنے سے تحفظ حاصل کریں۔",
                  ),
                ),
                _DividerLine(),
                _ListTileRow(
                  icon: Icons.card_giftcard,
                  title: _t(context, "Free Gold Coins", "مفت گولڈ کوائنز"),
                  desc: _t(
                    context,
                    "Free gold coins on diamond & precious gem jewelry above selected values.",
                    "ڈائمنڈ/جیم جیولری پر مخصوص ویلیو سے زائد خریداری پر مفت گولڈ کوائنز۔",
                  ),
                ),
                _DividerLine(),
                _ListTileRow(
                  icon: Icons.percent,
                  title: _t(context, "Special Discounts", "خصوصی ڈسکاؤنٹس"),
                  desc: _t(
                    context,
                    "Attractive discounts and special offers available throughout the year.",
                    "پورا سال شو رومز پر پرکشش ڈسکاؤنٹس اور خصوصی آفرز۔",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _SectionTitle(
              title: _t(context, "Why Choose Legacy Jewellers?", "لیگیسی جیولرز کیوں؟"),
              subtitle: _t(context, "The difference that comes with trust and excellence", "اعتماد اور معیار کا فرق"),
              accentColor: _accent,
            ),
            const SizedBox(height: 10),

            _ChecklistCard(
              items: [
                _t(context, "Decade of Trusted Excellence since 2015", "2015 سے دہائی بھر کا اعتماد"),
                _t(context, "100% BIS Hallmarked Pure Gold", "100% BIS ہال مارکڈ خالص سونا"),
                _t(context, "Internationally Certified Diamonds", "بین الاقوامی سرٹیفائیڈ ہیرے"),
                _t(context, "Zero Deduction Exchange Policy", "زیرو ڈیڈکشن ایکسچینج پالیسی"),
                _t(context, "Transparent Pricing & Detailed Invoices", "شفاف قیمتیں اور تفصیلی رسیدیں"),
                _t(context, "Lifetime Maintenance Assurance", "لائف ٹائم مینٹیننس"),
                _t(context, "Guaranteed Buyback Policy", "گارنٹیڈ بائے بیک پالیسی"),
                _t(context, "Complimentary Insurance Coverage", "مفت انشورنس کوریج"),
                _t(context, "Responsible Sourcing Practices", "ذمہ دارانہ سورسنگ"),
                _t(context, "Fair Wages for Artisans & Craftsmen", "کاریگروں کے لیے منصفانہ اجرت"),
              ],
              accentColor: _accent,
            ),

            const SizedBox(height: 18),

            Text(
              _t(
                context,
                "Note: Product policies may vary by location and product type. Please contact your nearest store for exact details.",
                "نوٹ: پالیسیز مقام اور پروڈکٹ کے مطابق مختلف ہو سکتی ہیں۔ درست معلومات کے لیے قریبی اسٹور سے رابطہ کریں۔",
              ),
              style: mutedStyle,
              textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- UI helpers ----------------------------- */

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) {
    // Responsive 1 column on small phones, 2 columns on larger screens.
    final w = MediaQuery.of(context).size.width;
    final int cols = w >= 700 ? 2 : 1;

    if (cols == 1) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    // 2-column layout
    final left = <Widget>[];
    final right = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      (i.isEven ? left : right).add(children[i]);
    }

    Widget col(List<Widget> list) {
      return Expanded(
        child: Column(
          children: [
            for (int i = 0; i < list.length; i++) ...[
              list[i],
              if (i != list.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        col(left),
        const SizedBox(width: 10),
        col(right),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withOpacity(0.25)),
            ),
            child: Icon(icon, size: 22, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  final List<Widget> children;
  const _ListCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _accent.withOpacity(0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: children),
      ),
    );
  }
}

class _ListTileRow extends StatelessWidget {
  static const Color _accent = Color(0xFFdfa273);

  final IconData icon;
  final String title;
  final String desc;

  const _ListTileRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.25)),
            ),
            child: Icon(icon, size: 20, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.12), height: 1);
  }
}

class _ChecklistCard extends StatelessWidget {
  static const Color _card = Color(0xFF0A3C30);

  final List<String> items;
  final Color accentColor;
  const _ChecklistCard({required this.items, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accentColor.withOpacity(0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != items.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
