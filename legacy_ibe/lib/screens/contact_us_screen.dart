// lib/screens/contact_us_screen.dart
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../providers/app_settings.dart";
import "../providers/shop_provider.dart";
import "../providers/site_config_provider.dart";
import "../theme/brand.dart";
import "../widgets/brand_kit.dart";

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // Match About Us screen color scheme
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  String _t(BuildContext context, String en, String ur) {
    final isUrdu = context.read<AppSettings>().isUrdu;
    return isUrdu ? ur : en;
  }

  String _navLabel(BuildContext context, int i) {
    final isUrdu = context.read<AppSettings>().isUrdu;
    switch (i) {
      case 0:
        return isUrdu ? "ہم سے رابطہ" : "Contact Us";
      case 1:
        return isUrdu ? "شاپ" : "Shop";
      case 2:
        return isUrdu ? "اسپاٹ" : "Spot";
      case 3:
        return isUrdu ? "واٹس ایپ" : "WhatsApp";
      default:
        return isUrdu ? "مزید" : "More";
    }
  }

  Future<void> _copy(BuildContext context, String text, String toast) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _card,
        content: Text(toast, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri, String failMsg) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _card,
            content: Text(failMsg, style: const TextStyle(color: Colors.white)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(failMsg, style: const TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;

    // Admin-managed contact details (GET /api/app-config). Falls back to the
    // built-in defaults when offline / before the first fetch.
    final config = context.watch<SiteConfigProvider>().config;
    final address = config.contactAddress;
    final phone = config.contactPhone;
    final whatsapp = config.contactWhatsapp;
    final email = config.contactEmail;

    final mapsUri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}",
    );

    final callUri = Uri(scheme: "tel", path: phone);
    final mailUri = Uri(
      scheme: "mailto",
      path: email,
      query: Uri(queryParameters: {"subject": "Inquiry - Legacy Jewellers"}).query,
    );

    final waUri = Uri.parse("https://wa.me/${whatsapp.replaceAll("+", "")}");

    // ✅ Same behavior pattern you already use: return desired tab index to HomeScreen
    void onBottomNavTap(int i) {
      if (i == 0) return; // already on Contact
      Navigator.of(context).pop(i);
    }

    return Scaffold(
      backgroundColor: _bg,

      // ✅ NO AppBar (MoreScreen also has no appbar)
      body: BrandBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            children: [
            // Header card (matching About Us style)
            BrandCard(
              gold: true,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: Brand.goldGradient,
                      borderRadius: BorderRadius.circular(Brand.rMd),
                      boxShadow: Brand.goldGlow,
                    ),
                    child: const Icon(Icons.support_agent, size: 24, color: Color(0xFF1A1207)),
                  ),
                  const SizedBox(width: Brand.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(context, "Contact Us", "ہم سے رابطہ"),
                          style: Brand.display(20, color: Brand.gold, weight: FontWeight.w700),
                          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _t(
                            context,
                            "Call, WhatsApp or email us anytime",
                            "کال، واٹس ایپ یا ای میل کے ذریعے رابطہ کریں",
                          ),
                          style: Brand.sans(12.5, color: Brand.textMuted, weight: FontWeight.w500, height: 1.3),
                          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).entrance(),

            const SizedBox(height: 12),

            // Quick actions row
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.call,
                    label: _t(context, "Call", "کال کریں"),
                    onTap: () => _launch(
                      context,
                      callUri,
                      _t(context, "Could not open phone dialer.", "فون ڈائلر نہیں کھل سکا۔"),
                    ),
                    accentColor: _accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.chat_bubble,
                    label: _t(context, "WhatsApp", "واٹس ایپ"),
                    onTap: () => _launch(
                      context,
                      waUri,
                      _t(context, "Could not open WhatsApp.", "واٹس ایپ نہیں کھل سکا۔"),
                    ),
                    accentColor: _accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.email,
                    label: _t(context, "Email", "ای میل"),
                    onTap: () => _launch(
                      context,
                      mailUri,
                      _t(context, "Could not open email app.", "ای میل ایپ نہیں کھل سکی۔"),
                    ),
                    accentColor: _accent,
                  ),
                ),
              ],
            ).entrance(delayMs: 80),

            const SizedBox(height: 14),

            SectionHeader(
              eyebrow: _t(context, "Reach us", "رابطہ"),
              title: _t(context, "Get in touch", "ہم سے رابطہ کریں"),
            ).entrance(delayMs: 120),

            const SizedBox(height: 12),

            // Details list card
            BrandCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.location_on,
                    title: _t(context, "Our Location", "ہمارا پتہ"),
                    subtitle: address,
                    isUrdu: isUrdu,
                    primaryLabel: _t(context, "Open", "میپس میں کھولیں"),
                    onPrimary: () => _launch(
                      context,
                      mapsUri,
                      _t(context, "Could not open maps.", "میپس نہیں کھل سکے۔"),
                    ),
                    secondaryLabel: _t(context, "Copy", "کاپی"),
                    onSecondary: () => _copy(
                      context,
                      address,
                      _t(context, "Address copied.", "پتہ کاپی ہو گیا۔"),
                    ),
                    accentColor: _accent,
                  ),
                  Divider(height: 1, thickness: 1, color: Brand.hairlineSoft, indent: 14, endIndent: 14),
                  _InfoTile(
                    icon: Icons.phone_in_talk,
                    title: _t(context, "Phone Number", "فون نمبر"),
                    subtitle: phone,
                    isUrdu: isUrdu,
                    primaryLabel: _t(context, "Call", "کال"),
                    onPrimary: () => _launch(
                      context,
                      callUri,
                      _t(context, "Could not open phone dialer.", "فون ڈائلر نہیں کھل سکا۔"),
                    ),
                    secondaryLabel: _t(context, "Copy", "کاپی"),
                    onSecondary: () => _copy(
                      context,
                      phone,
                      _t(context, "Phone number copied.", "فون نمبر کاپی ہو گیا۔"),
                    ),
                    accentColor: _accent,
                  ),
                  Divider(height: 1, thickness: 1, color: Brand.hairlineSoft, indent: 14, endIndent: 14),
                  _InfoTile(
                    icon: Icons.chat,
                    title: _t(context, "WhatsApp", "واٹس ایپ"),
                    subtitle: whatsapp,
                    isUrdu: isUrdu,
                    primaryLabel: _t(context, "Message", "میسج"),
                    onPrimary: () => _launch(
                      context,
                      waUri,
                      _t(context, "Could not open WhatsApp.", "واٹس ایپ نہیں کھل سکا۔"),
                    ),
                    secondaryLabel: _t(context, "Copy", "کاپی"),
                    onSecondary: () => _copy(
                      context,
                      whatsapp,
                      _t(context, "WhatsApp number copied.", "واٹس ایپ نمبر کاپی ہو گیا۔"),
                    ),
                    accentColor: _accent,
                  ),
                  Divider(height: 1, thickness: 1, color: Brand.hairlineSoft, indent: 14, endIndent: 14),
                  _InfoTile(
                    icon: Icons.alternate_email,
                    title: _t(context, "Email Address", "ای میل"),
                    subtitle: email,
                    isUrdu: isUrdu,
                    primaryLabel: _t(context, "Email", "ای میل"),
                    onPrimary: () => _launch(
                      context,
                      mailUri,
                      _t(context, "Could not open email app.", "ای میل ایپ نہیں کھل سکی۔"),
                    ),
                    secondaryLabel: _t(context, "Copy", "کاپی"),
                    onSecondary: () => _copy(
                      context,
                      email,
                      _t(context, "Email copied.", "ای میل کاپی ہو گئی۔"),
                    ),
                    accentColor: _accent,
                  ),
                ],
              ),
            ).entrance(delayMs: 140),

            const SizedBox(height: 16),

            SectionHeader(
              eyebrow: _t(context, "Inquiry", "استفسار"),
              title: _t(context, "Send us a message", "ہمیں پیغام بھیجیں"),
            ).entrance(delayMs: 160),

            const SizedBox(height: 12),

            // Send us a message (saves to the website's contacts inbox)
            _ContactForm(isUrdu: isUrdu, card: _card, accent: _accent).entrance(delayMs: 200),

            const SizedBox(height: 16),

            SectionHeader(
              eyebrow: _t(context, "When we're open", "ہمارے اوقات"),
              title: _t(context, "Business Hours", "اوقاتِ کار"),
            ).entrance(delayMs: 240),

            const SizedBox(height: 12),

            // Opening hours card
            BrandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HoursRow(day: _t(context, "Mon–Thu", "پیر–جمعرات"), time: config.hoursMonThu, isUrdu: isUrdu),
                  const SizedBox(height: 8),
                  _HoursRow(day: _t(context, "Fri", "جمعہ"), time: config.hoursFri, isUrdu: isUrdu),
                  const SizedBox(height: 8),
                  _HoursRow(day: _t(context, "Sat", "ہفتہ"), time: config.hoursSat, isUrdu: isUrdu),
                  const SizedBox(height: 8),
                  _HoursRow(day: _t(context, "Sun", "اتوار"), time: config.hoursSun, isUrdu: isUrdu),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(Brand.s12),
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Brand.rSm),
                      border: Border.all(color: Brand.hairline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(Icons.bolt, size: 18, color: Brand.gold),
                        const SizedBox(width: Brand.s8),
                        Expanded(
                          child: Text(
                            _t(
                              context,
                              "Tip: For urgent assistance, WhatsApp is the fastest option.",
                              "ٹپ: فوری مدد کے لیے واٹس ایپ سب سے تیز ذریعہ ہے۔",
                            ),
                            style: Brand.sans(12, color: Brand.textMuted, weight: FontWeight.w500, height: 1.35),
                            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).entrance(delayMs: 280),
            ],
          ),
        ),
      ),

      // Premium bottom nav — identical layout to Home:
      // Contact · Shop · Spot · WhatsApp · More
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 0,
        onTap: onBottomNavTap,
        items: [
          BrandNavItem(
            icon: Icons.call_outlined,
            activeIcon: Icons.call,
            label: _navLabel(context, 0),
          ),
          BrandNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
            label: _navLabel(context, 1),
          ),
          BrandNavItem(
            icon: Icons.show_chart_rounded,
            activeIcon: Icons.insights_rounded,
            label: _navLabel(context, 2),
          ),
          BrandNavItem(
            icon: Icons.chat_outlined,
            activeIcon: Icons.chat,
            label: _navLabel(context, 3),
            customIcon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                gradient: Brand.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  size: 13, color: Brand.teal),
            ),
          ),
          BrandNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: _navLabel(context, 4),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Widgets ----------------------------- */

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Brand.rMd),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Brand.rMd),
            gradient: Brand.cardGradient,
            border: Border.all(color: Brand.hairline),
            boxShadow: Brand.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Brand.rSm),
                  border: Border.all(color: accentColor.withValues(alpha: 0.30)),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Brand.label(11, color: accentColor, spacing: 0.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUrdu;

  final String primaryLabel;
  final VoidCallback onPrimary;

  final String secondaryLabel;
  final VoidCallback onSecondary;
  final Color accentColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUrdu,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Brand.rMd),
                border: Border.all(color: accentColor.withValues(alpha: 0.30)),
              ),
              child: Icon(icon, size: 22, color: accentColor),
            ),
            const SizedBox(width: Brand.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Brand.label(11, color: Brand.textMuted, spacing: 1.0),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Brand.sans(14.5, color: Brand.text, weight: FontWeight.w600, height: 1.3),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Brand.text,
                            side: BorderSide(color: Brand.hairline),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: onSecondary,
                          child: Text(
                            secondaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: const Color(0xFF1A1207),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: onPrimary,
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------- Contact form ----------------------- */

class _ContactForm extends StatefulWidget {
  final bool isUrdu;
  final Color card;
  final Color accent;

  const _ContactForm({
    required this.isUrdu,
    required this.card,
    required this.accent,
  });

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  String _t(String en, String ur) => widget.isUrdu ? ur : en;

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: widget.accent.withOpacity(0.85)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.accent.withOpacity(0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.accent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.accent.withOpacity(0.45)),
        ),
      );

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = context.read<ShopProvider>().api;
      await api.submitContact(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        subject: _subject.text,
        message: _message.text,
      );
      if (!mounted) return;
      _name.clear();
      _email.clear();
      _phone.clear();
      _subject.clear();
      _message.clear();
      _formKey.currentState?.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: widget.card,
          behavior: SnackBarBehavior.floating,
          content: Text(
            _t("Message sent. Our team will get back to you soon.",
                "پیغام بھیج دیا گیا۔ ہماری ٹیم جلد رابطہ کرے گی۔"),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = _t(
            "Could not send your message. Please check your connection and try again.",
            "پیغام نہیں بھیجا جا سکا۔ براہِ کرم اپنا انٹرنیٹ کنکشن چیک کر کے دوبارہ کوشش کریں۔",
          ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;
    final accent = widget.accent;

    return BrandCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Brand.rMd),
                      border: Border.all(color: accent.withValues(alpha: 0.30)),
                    ),
                    child: Icon(Icons.send_outlined, size: 22, color: accent),
                  ),
                  const SizedBox(width: Brand.s12),
                  Expanded(
                    child: Text(
                      _t("Send us a message", "ہمیں پیغام بھیجیں"),
                      style: Brand.display(17, color: accent, weight: FontWeight.w700),
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: _dec(_t("Your name", "آپ کا نام")),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? _t("Please enter your name", "براہِ کرم اپنا نام درج کریں")
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _dec(_t("Email", "ای میل")),
                validator: (v) {
                  final s = (v ?? "").trim();
                  if (s.isEmpty) {
                    return _t("Please enter your email",
                        "براہِ کرم اپنی ای میل درج کریں");
                  }
                  if (!s.contains("@") || !s.contains(".")) {
                    return _t("Please enter a valid email",
                        "براہِ کرم درست ای میل درج کریں");
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: _dec(_t("Phone (optional)", "فون (اختیاری)")),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subject,
                style: const TextStyle(color: Colors.white),
                decoration: _dec(_t("Subject (optional)", "موضوع (اختیاری)")),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _dec(_t("Message", "پیغام")),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? _t("Please enter your message",
                        "براہِ کرم اپنا پیغام درج کریں")
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: Brand.sans(13, color: Brand.down, weight: FontWeight.w600, height: 1.3),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF1A1207),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF1A1207)),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _t("Send message", "پیغام بھیجیں"),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final String time;
  final bool isUrdu;

  const _HoursRow({
    required this.day,
    required this.time,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Expanded(
          child: Text(
            day,
            style: Brand.sans(13.5, color: Brand.textMuted, weight: FontWeight.w600),
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          time,
          style: Brand.number(13.5, color: Brand.text, weight: FontWeight.w700, height: 1.3),
          textAlign: isUrdu ? TextAlign.left : TextAlign.right,
        ),
      ],
    );
  }
}