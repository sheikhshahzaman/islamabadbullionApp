// lib/screens/terms_conditions_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  // Match About Us screen color scheme
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  bool _isUrdu(BuildContext context) => context.watch<AppSettings>().isUrdu;

  String _t(BuildContext context, String en, String ur) => _isUrdu(context) ? ur : en;

  @override
  Widget build(BuildContext context) {
    final isUrdu = _isUrdu(context);

    final title = _t(context, "Terms & Conditions", "شرائط و ضوابط");
    final subtitle = _t(
      context,
      "Terms for using the Islamabad Bullion Exchange app and services",
      "اسلام آباد بُلین ایکسچینج ایپ اور خدمات استعمال کرنے کی شرائط",
    );

    // Keep consistent with your Privacy Policy screen style
    final lastUpdated = _t(context, "Last updated: 28 Dec 2025", "آخری اپ ڈیٹ: 28 دسمبر 2025");

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
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
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _accent.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.description_outlined, size: 22, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: _accent,
                            ),
                            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lastUpdated,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content card
              Container(
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section(
                        title: _t(context, "1) Acceptance of terms", "1) شرائط کی قبولیت"),
                        body: _t(
                          context,
                          "By downloading, accessing, or using this app, you agree to these Terms & Conditions. If you do not agree, please discontinue use of the app.",
                          "اس ایپ کو ڈاؤن لوڈ کرنے، کھولنے یا استعمال کرنے کے ذریعے آپ ان شرائط و ضوابط سے اتفاق کرتے ہیں۔ اگر آپ متفق نہیں ہیں تو براہِ کرم ایپ کا استعمال بند کر دیں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "2) Informational purpose only", "2) صرف معلوماتی مقصد"),
                        body: _t(
                          context,
                          "Rates and content provided in this app are for general informational purposes only. They may be indicative and may not be suitable for trading, investment, or decision-making. Islamabad Bullion Exchange does not provide financial, investment, tax, or legal advice.",
                          "ایپ میں فراہم کردہ ریٹس اور مواد صرف عمومی معلومات کے لیے ہیں۔ یہ اشاریاتی ہو سکتے ہیں اور ٹریڈنگ، سرمایہ کاری یا فیصلہ سازی کے لیے موزوں نہ ہوں۔ اسلام آباد بُلین ایکسچینج مالی، سرمایہ کاری، ٹیکس یا قانونی مشورہ فراہم نہیں کرتا۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "3) Accuracy and availability", "3) درستگی اور دستیابی"),
                        body: _t(
                          context,
                          "We strive to keep the information accurate and updated, but we do not guarantee accuracy, completeness, timeliness, or real-time availability. We may modify, suspend, or discontinue any part of the app at any time without notice.",
                          "ہم معلومات کو درست اور اپ ڈیٹ رکھنے کی کوشش کرتے ہیں، لیکن ہم درستگی، مکمل ہونے، بروقت ہونے یا ریئل ٹائم دستیابی کی ضمانت نہیں دیتے۔ ہم ایپ کے کسی بھی حصے میں کسی بھی وقت بغیر اطلاع تبدیلی، معطلی یا بندش کر سکتے ہیں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "4) User responsibilities", "4) صارف کی ذمہ داریاں"),
                        bodyWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bullet(
                              text: _t(
                                context,
                                "Use the app lawfully and responsibly.",
                                "ایپ کو قانونی اور ذمہ دارانہ طریقے سے استعمال کریں۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Verify important information independently before making decisions.",
                                "اہم فیصلوں سے پہلے معلومات کی خود تصدیق کریں۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Do not misuse the app, attempt to disrupt services, or access restricted areas.",
                                "ایپ کا غلط استعمال نہ کریں، سروس میں خلل ڈالنے کی کوشش نہ کریں، یا محدود حصوں تک رسائی کی کوشش نہ کریں۔",
                              ),
                              accentColor: _accent,
                            ),
                          ],
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "5) Prohibited activities", "5) ممنوع سرگرمیاں"),
                        bodyWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bullet(
                              text: _t(
                                context,
                                "Reverse engineering, decompiling, or attempting to extract source code except where permitted by law.",
                                "قانونی اجازت کے بغیر ریورس انجینئرنگ، ڈی کمپائلنگ، یا سورس کوڈ نکالنے کی کوشش۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Using automated systems to scrape, overload, or interfere with app services.",
                                "خودکار سسٹمز کے ذریعے ڈیٹا اسکریپ کرنا، اوور لوڈ کرنا، یا سروس میں مداخلت کرنا۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Posting or transmitting harmful, unlawful, or misleading content.",
                                "نقصان دہ، غیر قانونی یا گمراہ کن مواد پوسٹ یا منتقل کرنا۔",
                              ),
                              accentColor: _accent,
                            ),
                          ],
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "6) Intellectual property", "6) دانشورانہ ملکیت"),
                        body: _t(
                          context,
                          "All trademarks, logos, text, layout, and app design are the property of Islamabad Bullion Exchange or its licensors. You may not copy, reproduce, distribute, or create derivative works without prior written permission.",
                          "تمام ٹریڈ مارکس، لوگوز، متن، لے آؤٹ اور ایپ ڈیزائن اسلام آباد بُلین ایکسچینج یا اس کے لائسنس دہندگان کی ملکیت ہیں۔ پیشگی تحریری اجازت کے بغیر آپ نقل، دوبارہ شائع، تقسیم یا مشتق کام نہیں بنا سکتے۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "7) Third-party links and services", "7) تھرڈ پارٹی لنکس اور سروسز"),
                        body: _t(
                          context,
                          "The app may reference third-party websites, APIs, or services. We are not responsible for third-party content, policies, pricing, or availability. Use of third-party services is at your own risk and subject to their terms.",
                          "ایپ میں تھرڈ پارٹی ویب سائٹس، APIs یا سروسز کا حوالہ ہو سکتا ہے۔ تھرڈ پارٹی مواد، پالیسیز، قیمتوں یا دستیابی کی ذمہ داری ہماری نہیں۔ تھرڈ پارٹی سروسز کا استعمال آپ کی ذمہ داری پر ہے اور ان کی شرائط کے تابع ہے۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "8) Disclaimers", "8) دستبرداری"),
                        body: _t(
                          context,
                          "You acknowledge that metal trading involves risk. Islamabad Bullion Exchange is not liable for any losses or damages arising from reliance on app information, including rate inaccuracies, delays, or service interruptions.",
                          "آپ تسلیم کرتے ہیں کہ دھاتوں کی ٹریڈنگ میں رسک شامل ہے۔ ایپ کی معلومات پر انحصار کے نتیجے میں ہونے والے کسی بھی نقصان یا خرابی کے لیے اسلام آباد بُلین ایکسچینج ذمہ دار نہیں، بشمول ریٹس کی غلطی، تاخیر یا سروس میں رکاوٹ۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "9) Limitation of liability", "9) ذمہ داری کی حد"),
                        body: _t(
                          context,
                          "To the maximum extent permitted by law, Islamabad Bullion Exchange and its affiliates will not be liable for indirect, incidental, special, consequential, or punitive damages, or any loss of profits, data, or goodwill.",
                          "قانون کے تحت زیادہ سے زیادہ حد تک، اسلام آباد بُلین ایکسچینج اور اس کے وابستہ ادارے بالواسطہ، حادثاتی، خصوصی، نتیجتاً یا تعزیری نقصانات، یا منافع/ڈیٹا/گڈوِل کے نقصان کے ذمہ دار نہیں ہوں گے۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "10) Changes to terms", "10) شرائط میں تبدیلی"),
                        body: _t(
                          context,
                          "We may update these Terms & Conditions from time to time. Any updates will be reflected in the \"Last updated\" date. Continued use after changes means you accept the updated terms.",
                          "ہم وقتاً فوقتاً ان شرائط و ضوابط میں تبدیلی کر سکتے ہیں۔ اپ ڈیٹس \"آخری اپ ڈیٹ\" کی تاریخ میں ظاہر ہوں گی۔ تبدیلی کے بعد استعمال جاری رکھنے کا مطلب ہے کہ آپ اپ ڈیٹ شدہ شرائط قبول کرتے ہیں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "11) Governing law", "11) نافذ قانون"),
                        body: _t(
                          context,
                          "These terms are governed by applicable local laws. Where permitted, disputes will be handled by the competent courts having jurisdiction.",
                          "یہ شرائط متعلقہ مقامی قوانین کے تحت ہیں۔ جہاں اجازت ہو، تنازعات متعلقہ دائرہ اختیار رکھنے والی عدالتوں میں نمٹائے جائیں گے۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "12) Contact", "12) رابطہ"),
                        body: _t(
                          context,
                          "If you have questions about these Terms & Conditions, please contact us at: thelegacyjewellers@gmail.com",
                          "اگر آپ کے پاس ان شرائط و ضوابط سے متعلق کوئی سوال ہو تو براہِ کرم ہم سے رابطہ کریں: thelegacyjewellers@gmail.com",
                        ),
                        accentColor: _accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 18,
    thickness: 1,
    color: Colors.white.withOpacity(0.12),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? bodyWidget;
  final Color accentColor;

  const _Section({
    required this.title,
    required this.accentColor,
    this.body,
    this.bodyWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;

    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: accentColor,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.92),
      height: 1.45,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle,
          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 8),
        if (bodyWidget != null) bodyWidget!,
        if (bodyWidget == null && body != null)
          SelectableText(
            body!,
            style: bodyStyle,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color accentColor;
  const _Bullet({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;

    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.92),
      height: 1.45,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUrdu) ...[
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SelectableText(
              text,
              style: style,
              textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            ),
          ),
          if (isUrdu) ...[
            const SizedBox(width: 10),
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}