// lib/screens/privacy_policy_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Match About Us screen color scheme
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  bool _isUrdu(BuildContext context) => context.watch<AppSettings>().isUrdu;

  String _t(BuildContext context, String en, String ur) => _isUrdu(context) ? ur : en;

  @override
  Widget build(BuildContext context) {
    final isUrdu = _isUrdu(context);

    final title = _t(context, "Privacy Policy", "پرائیویسی پالیسی");
    final subtitle = _t(
      context,
      "How Islamabad Bullion Exchange handles your information",
      "اسلام آباد بُلین ایکسچینج آپ کی معلومات کو کیسے ہینڈل کرتا ہے",
    );

    final lastUpdated = _t(context, "Last updated: 20 January 2026", "آخری اپ ڈیٹ: 1 جنوری 2026");

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
                      child: const Icon(Icons.privacy_tip_outlined, size: 22, color: _accent),
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
                        title: _t(context, "1) Overview", "1) تعارف"),
                        body: _t(
                          context,
                          "This Privacy Policy explains what information we collect, why we collect it, how we use it, and the choices you have. Islamabad Bullion Exchange is focused on providing metal rate information and related tools in a transparent and responsible manner.",
                          "یہ پرائیویسی پالیسی وضاحت کرتی ہے کہ ہم کون سی معلومات جمع کرتے ہیں، کیوں جمع کرتے ہیں، کیسے استعمال کرتے ہیں، اور آپ کے پاس کیا اختیارات ہیں۔ اسلام آباد بُلین ایکسچینج کا مقصد دھاتوں کے ریٹس اور متعلقہ ٹولز شفاف اور ذمہ دارانہ انداز میں فراہم کرنا ہے۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "2) Information we may collect", "2) ممکنہ طور پر جمع کی جانے والی معلومات"),
                        bodyWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bullet(
                              text: _t(
                                context,
                                "App preferences: selected language and currency settings to improve your experience.",
                                "ایپ ترجیحات: آپ کی سہولت کے لیے منتخب زبان اور کرنسی سیٹنگز۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Usage data (non-sensitive): basic interaction signals (e.g., screens visited, feature taps) to understand app performance and improve stability.",
                                "استعمال کا ڈیٹا (غیر حساس): بنیادی انٹرایکشن سگنلز (مثلاً کون سی اسکرین دیکھی گئی) تاکہ کارکردگی بہتر اور ایپ زیادہ مستحکم ہو سکے۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Device/technical data: device model, OS version, app version, and crash logs (when a crash occurs) for troubleshooting.",
                                "ڈیوائس/تکنیکی ڈیٹا: ڈیوائس ماڈل، OS ورژن، ایپ ورژن، اور کریش لاگز (اگر کریش ہو) تاکہ مسئلہ حل کیا جا سکے۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "Contact data (only if you provide it): if you email or message us, we receive the details you choose to share.",
                                "رابطہ معلومات (صرف آپ کی فراہم کردہ): اگر آپ ہمیں ای میل یا میسج کریں تو وہ معلومات ہمیں موصول ہوتی ہیں جو آپ خود شیئر کرتے ہیں۔",
                              ),
                              accentColor: _accent,
                            ),
                          ],
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "3) Metal rates and third-party sources", "3) دھاتوں کے ریٹس اور تھرڈ پارٹی ذرائع"),
                        body: _t(
                          context,
                          "Metal rates shown in the app may come from third-party data sources or APIs. We display these rates for informational purposes. We do not guarantee real-time accuracy and you should not rely on app rates as the sole basis for trading or investment decisions.",
                          "ایپ میں دکھائے گئے دھاتوں کے ریٹس ممکن ہے تھرڈ پارٹی سورسز یا APIs سے آئیں۔ یہ ریٹس صرف معلوماتی مقصد کے لیے دکھائے جاتے ہیں۔ ہم ریئل ٹائم درستگی کی ضمانت نہیں دیتے، اور آپ کو ٹریڈنگ یا سرمایہ کاری کے فیصلوں کے لیے صرف ایپ ریٹس پر انحصار نہیں کرنا چاہیے۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "4) How we use information", "4) ہم معلومات کیسے استعمال کرتے ہیں"),
                        bodyWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bullet(
                              text: _t(
                                context,
                                "To provide core functionality (rates display, currency conversion, and calculators).",
                                "بنیادی فیچرز فراہم کرنے کے لیے (ریٹس، کرنسی کنورژن، اور کیلکولیٹرز)۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "To maintain and improve app reliability, security, and performance.",
                                "ایپ کی کارکردگی، سکیورٹی اور استحکام بہتر بنانے کے لیے۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "To respond to your requests and support messages.",
                                "آپ کی درخواستوں اور سپورٹ میسجز کا جواب دینے کے لیے۔",
                              ),
                              accentColor: _accent,
                            ),
                          ],
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "5) Sharing and disclosure", "5) معلومات کا اشتراک"),
                        body: _t(
                          context,
                          "We do not sell your personal information. We may share limited technical data with service providers (such as crash reporting or analytics tools) strictly to operate and improve the app. We may also disclose information if required by law, regulation, or a valid legal request.",
                          "ہم آپ کی ذاتی معلومات فروخت نہیں کرتے۔ ہم صرف ایپ چلانے اور بہتر بنانے کے لیے محدود تکنیکی ڈیٹا سروس پرووائیڈرز (جیسے کریش رپورٹنگ یا اینالیٹکس) کے ساتھ شیئر کر سکتے ہیں۔ قانون، ضابطہ، یا کسی درست قانونی درخواست کی صورت میں معلومات فراہم کرنا ضروری ہو تو ہم ایسا کر سکتے ہیں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "6) Data security", "6) ڈیٹا سکیورٹی"),
                        body: _t(
                          context,
                          "We use reasonable administrative and technical safeguards to protect information. However, no system can be guaranteed 100% secure. Please use the app responsibly and avoid sharing sensitive personal information through messages.",
                          "ہم معلومات کے تحفظ کے لیے مناسب انتظامی اور تکنیکی اقدامات کرتے ہیں، تاہم کوئی بھی سسٹم 100% محفوظ ہونے کی ضمانت نہیں دے سکتا۔ براہِ کرم ایپ ذمہ داری سے استعمال کریں اور میسجز کے ذریعے حساس ذاتی معلومات شیئر نہ کریں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "7) Data retention", "7) ڈیٹا کب تک رکھا جاتا ہے"),
                        body: _t(
                          context,
                          "We retain information only as long as necessary for the purposes described in this policy, including compliance, dispute resolution, and enforcing our agreements. Crash logs and technical diagnostics may be retained for a limited period to analyze and fix issues.",
                          "ہم معلومات صرف اتنی مدت کے لیے رکھتے ہیں جتنی اس پالیسی میں بیان کردہ مقاصد کے لیے ضروری ہو، بشمول کمپلائنس، تنازعات کے حل، اور معاہدوں کے نفاذ کے۔ کریش لاگز اور تکنیکی ڈائیگناسٹکس عموماً مسائل کی جانچ اور درستگی کے لیے محدود مدت تک رکھے جا سکتے ہیں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "8) Your choices and rights", "8) آپ کے اختیارات اور حقوق"),
                        bodyWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bullet(
                              text: _t(
                                context,
                                "You can change language and currency settings anytime from the app.",
                                "آپ ایپ میں کسی بھی وقت زبان اور کرنسی کی سیٹنگز تبدیل کر سکتے ہیں۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "You may request clarification or deletion of any information you directly provided to us (e.g., via email).",
                                "آپ ہم سے براہِ راست فراہم کردہ معلومات (مثلاً ای میل کے ذریعے) کے بارے میں وضاحت یا حذف کرنے کی درخواست کر سکتے ہیں۔",
                              ),
                              accentColor: _accent,
                            ),
                            _Bullet(
                              text: _t(
                                context,
                                "You can stop data collection by uninstalling the app.",
                                "آپ ایپ اَن انسٹال کر کے ڈیٹا کلیکشن روک سکتے ہیں۔",
                              ),
                              accentColor: _accent,
                            ),
                          ],
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "9) Children's privacy", "9) بچوں کی پرائیویسی"),
                        body: _t(
                          context,
                          "This app is not intended for children under 13. We do not knowingly collect personal information from children. If you believe a child has provided personal information, please contact us to request deletion.",
                          "یہ ایپ 13 سال سے کم عمر بچوں کے لیے نہیں ہے۔ ہم جان بوجھ کر بچوں کی ذاتی معلومات جمع نہیں کرتے۔ اگر آپ سمجھتے ہیں کہ کسی بچے نے ذاتی معلومات فراہم کی ہیں تو براہِ کرم حذف کرنے کے لیے ہم سے رابطہ کریں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "10) Changes to this policy", "10) پالیسی میں تبدیلیاں"),
                        body: _t(
                          context,
                          "We may update this Privacy Policy from time to time. Any updates will be reflected in the \"Last updated\" date. Continued use of the app after changes means you accept the updated policy.",
                          "ہم وقتاً فوقتاً اس پرائیویسی پالیسی کو اپ ڈیٹ کر سکتے ہیں۔ کوئی بھی تبدیلی \"آخری اپ ڈیٹ\" کی تاریخ میں ظاہر کر دی جائے گی۔ تبدیلی کے بعد ایپ کا استعمال جاری رکھنے کا مطلب ہے کہ آپ اپ ڈیٹ شدہ پالیسی کو قبول کرتے ہیں۔",
                        ),
                        accentColor: _accent,
                      ),
                      _divider(),

                      _Section(
                        title: _t(context, "11) Contact us", "11) ہم سے رابطہ کریں"),
                        body: _t(
                          context,
                          "If you have questions about this Privacy Policy, please contact us at: thelegacyjewellers@gmail.com",
                          "اگر آپ کے پاس اس پرائیویسی پالیسی سے متعلق کوئی سوال ہو تو براہِ کرم ہم سے رابطہ کریں: thelegacyjewellers@gmail.com",
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