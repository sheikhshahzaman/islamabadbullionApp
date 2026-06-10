// lib/screens/disclaimer_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  // Match About Us screen color scheme
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  bool _isUrdu(BuildContext context) => context.watch<AppSettings>().isUrdu;

  String _t(BuildContext context, String en, String ur) => _isUrdu(context) ? ur : en;

  List<String> _lines(BuildContext context) {
    final ur = _isUrdu(context);

    if (!ur) {
      return const [
        "Avoid speculating in gold. This is an illegal and unnatural practice. It can disrupt the balance of the gold market, so invest only in cash.",
        "Islamabad Bullion Exchange does not guarantee the accuracy of the data on this Application, nor do we guarantee that the data is real-time.",
        "The price data provided is indicative and may not be suitable for trading or decision-making purposes.",
        "Islamabad Bullion Exchange does not accept responsibility for any loss resulting from the use of the data provided.",
        "Islamabad Bullion Exchange does not endorse or promote any broker or financial services.",
        "The Islamabad Bullion Exchange website can be accessed worldwide. However, the information provided on its website is intended only for use by recipients located in countries where such use does not violate applicable laws or regulations.",
        "None of the services offered on this website are available to recipients located in countries where the provision of such offers would be in violation of applicable law or regulation.",
        "Trading gold and silver carries a high level of risk and is not suitable for all investors. Past performance is not an indicator of future results. In this case, at the same time, the high degree of leverage can work against you as well as for you. Before deciding to invest in gold and silver, you should carefully consider your investment objectives, experience, financial capabilities and risk appetite. It is possible that you will lose some or all of your initial investment. Therefore, you should not invest in funds that you cannot afford to lose completely in a worst-case scenario.",
      ];
    }

    return const [
      "سونے میں قیاس آرائی سے گریز کریں۔ یہ ایک غیر قانونی اور غیر فطری عمل ہے۔ یہ سونے کی منڈی کا توازن بگاڑ سکتا ہے، لہٰذا صرف نقد رقم میں سرمایہ کاری کریں۔",
      "اسلام آباد بُلین ایکسچینج اس اپلیکیشن پر موجود ڈیٹا کی درستگی کی ضمانت نہیں دیتا، اور نہ ہی ہم یہ ضمانت دیتے ہیں کہ یہ ڈیٹا حقیقی وقت (ریئل ٹائم) میں ہے۔",
      "فراہم کردہ قیمتوں کا ڈیٹا محض رہنمائی کے لیے ہے اور ٹریڈنگ یا فیصلہ سازی کے لیے موزوں نہیں ہو سکتا۔",
      "اسلام آباد بُلین ایکسچینج فراہم کردہ ڈیٹا کے استعمال کے نتیجے میں ہونے والے کسی بھی نقصان کی ذمہ داری قبول نہیں کرتا۔",
      "اسلام آباد بُلین ایکسچینج کسی بھی بروکر یا مالیاتی خدمات کی تائید یا تشہیر نہیں کرتا۔",
      "اسلام آباد بُلین ایکسچینج کی ویب سائٹ دنیا بھر میں دیکھی جا سکتی ہے۔ تاہم، اس پر فراہم کردہ معلومات صرف اُن ممالک کے صارفین کے لیے ہیں جہاں اس کا استعمال قابلِ اطلاق قوانین و ضوابط کی خلاف ورزی نہ کرتا ہو۔",
      "اس ویب سائٹ پر پیش کی جانے والی کوئی بھی سروس اُن ممالک کے صارفین کے لیے دستیاب نہیں جہاں ایسی پیشکشیں قابلِ اطلاق قانون یا ضابطے کی خلاف ورزی ہوں۔",
      "سونے اور چاندی کی ٹریڈنگ میں بلند سطح کا خطرہ ہوتا ہے اور یہ ہر سرمایہ کار کے لیے موزوں نہیں۔ ماضی کی کارکردگی مستقبل کے نتائج کی ضمانت نہیں۔ اس کے ساتھ ساتھ، زیادہ لیوریج (Leverage) آپ کے خلاف بھی جا سکتی ہے اور آپ کے حق میں بھی۔ سونے اور چاندی میں سرمایہ کاری کا فیصلہ کرنے سے پہلے اپنے سرمایہ کاری کے مقاصد، تجربے، مالی استطاعت اور رسک برداشت کرنے کی صلاحیت کا بغور جائزہ لیں۔ ممکن ہے کہ آپ اپنی ابتدائی سرمایہ کاری کا کچھ حصہ یا پوری سرمایہ کاری بھی کھو دیں۔ لہٰذا ایسے فنڈز میں سرمایہ کاری نہ کریں جنہیں آپ بدترین صورتِ حال میں مکمل طور پر کھونے کے متحمل نہ ہوں۔",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = _isUrdu(context);

    final title = _t(context, "Disclaimer", "دستبرداری");
    final subtitle = _t(
      context,
      "Important notes about rates, accuracy and risk",
      "ریٹس، درستگی اور رسک سے متعلق اہم نوٹس",
    );

    final lines = _lines(context);

    return Scaffold(
      backgroundColor: _bg, // Keep original background color
      appBar: AppBar(
        backgroundColor: _bg, // Keep original AppBar background
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
                      child: const Icon(Icons.report_gmailerrorred_outlined, size: 22, color: _accent),
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
                      Text(
                        _t(context, "Please read carefully", "براہِ کرم غور سے پڑھیں"),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _accent,
                        ),
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 10),

                      for (int i = 0; i < lines.length; i++) ...[
                        _BulletLine(text: lines[i], accentColor: _accent),
                        if (i != lines.length - 1)
                          Divider(
                            height: 16,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.12),
                          ),
                      ],

                      const SizedBox(height: 6),
                      Text(
                        _t(
                          context,
                          "Note: This information is provided for general awareness only.",
                          "نوٹ: یہ معلومات صرف عمومی آگاہی کے لیے فراہم کی گئی ہیں۔",
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
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
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color accentColor;
  const _BulletLine({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Expanded(
          child: SelectableText(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          ),
        ),
      ],
    );
  }
}