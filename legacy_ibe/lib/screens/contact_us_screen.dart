// lib/screens/contact_us_screen.dart
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../providers/app_settings.dart";

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
        return isUrdu ? "خریدیں" : "Buy";
      case 2:
        return isUrdu ? "اسپاٹ" : "Spot";
      case 3:
        return isUrdu ? "بیچیں" : "Sell";
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

    const address =
        "Shop No 1, Ground Floor, Trade Center, F-7 Markaz Block 20-B F-7, Islamabad, 44210";
    const phone = "+92-340-2786222";
    const whatsapp = "+923409786111";
    const email = "thelegacyjewellers@gmail.com";

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          children: [
            // Header card (matching About Us style)
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
                    child: const Icon(Icons.support_agent, size: 22, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(context, "Contact Us", "ہم سے رابطہ"),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _accent,
                          ),
                          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _t(
                            context,
                            "Call, WhatsApp or email us anytime",
                            "کال، واٹس ایپ یا ای میل کے ذریعے رابطہ کریں",
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
                ],
              ),
            ),

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
            ),

            const SizedBox(height: 12),

            // Details list card
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
                  Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.12)),
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
                  Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.12)),
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
                  Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.12)),
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
            ),

            const SizedBox(height: 12),

            // Opening hours card
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
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _accent.withOpacity(0.25)),
                          ),
                          child: const Icon(Icons.access_time, size: 22, color: _accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _t(context, "Opening Hours", "اوقاتِ کار"),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: _accent,
                            ),
                            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _HoursRow(day: _t(context, "Mon–Thu", "پیر–جمعرات"), time: "10AM - 8PM", isUrdu: isUrdu),
                    const SizedBox(height: 8),
                    _HoursRow(day: _t(context, "Fri", "جمعہ"), time: "3PM - 9:30PM", isUrdu: isUrdu),
                    const SizedBox(height: 8),
                    _HoursRow(day: _t(context, "Sat", "ہفتہ"), time: "12PM - 9:30PM", isUrdu: isUrdu),
                    const SizedBox(height: 8),
                    _HoursRow(day: _t(context, "Sun", "اتوار"), time: "2PM - 9:30PM", isUrdu: isUrdu),
                    const SizedBox(height: 10),
                    Text(
                      _t(
                        context,
                        "Tip: For urgent assistance, WhatsApp is the fastest option.",
                        "ٹپ: فوری مدد کے لیے واٹس ایپ سب سے تیز ذریعہ ہے۔",
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
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

      // ✅ EXACT same BottomNavigationBar style/format as Home + More
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _bg,
        unselectedItemColor: Colors.white70,
        selectedItemColor: Colors.white,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: onBottomNavTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.contact_mail_outlined),
            label: _navLabel(context, 0),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: _navLabel(context, 1),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: _navLabel(context, 2),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sell_outlined),
            label: _navLabel(context, 3),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0A3C30),
          border: Border.all(color: accentColor.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.25)),
              ),
              child: Icon(icon, size: 22, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.35)),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: onSecondary,
                          child: Text(
                            secondaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: onPrimary,
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
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
              color: accentColor.withOpacity(0.8),
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
      children: [
        Expanded(
          child: Text(
            day,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.92),
            ),
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          time,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}