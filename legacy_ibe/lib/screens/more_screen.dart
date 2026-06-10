import "package:flutter/material.dart";
import "package:legacy_ibe/screens/privacy_policy_screen.dart";
import "package:legacy_ibe/screens/terms_conditions_screen.dart";
import "package:legacy_ibe/screens/zakat_screen.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";
import "../providers/auth_provider.dart";
import "about_us_screen.dart";
import "change_password_screen.dart";
import "delete_account_screen.dart";
import "disclaimer_screen.dart";
import "edit_profile_screen.dart";
import "login_screen.dart";
import "signup_screen.dart";

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  String _t(BuildContext context, String en, String ur) {
    final isUrdu = context.watch<AppSettings>().isUrdu;
    return isUrdu ? ur : en;
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _accent.withOpacity(0.30)),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Logout",
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await auth.logout();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<AppSettings>().isUrdu;
    final auth = context.watch<AuthProvider>();

    final items = <_MoreItem>[
      if (!auth.isLoggedIn) ...[
        _MoreItem(
          icon: Icons.login_outlined,
          title: _t(context, "Login", "لاگ اِن"),
          subtitle: _t(
            context,
            "Access your account",
            "اپنے اکاؤنٹ تک رسائی حاصل کریں",
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
        _MoreItem(
          icon: Icons.person_add_alt_1_outlined,
          title: _t(context, "Create Account", "اکاؤنٹ بنائیں"),
          subtitle: _t(
            context,
            "Signup with your details",
            "اپنی معلومات کے ساتھ سائن اپ کریں",
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          ),
        ),
      ],
      _MoreItem(
        icon: Icons.calculate_outlined,
        title: _t(context, "Calculate Zakat", "زکوٰۃ کیلکولیٹر"),
        subtitle: _t(
          context,
          "Estimate your zakat based on current rates",
          "موجودہ ریٹ کے مطابق زکوٰۃ کا حساب لگائیں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ZakatScreen()),
        ),
      ),
      _MoreItem(
        icon: Icons.info_outline,
        title: _t(context, "About Us", "ہمارے بارے میں"),
        subtitle: _t(
          context,
          "Learn more about our company",
          "ہماری کمپنی کے بارے میں مزید جانیں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
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
          MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
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
          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
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
          MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
        ),
      ),
      if (auth.isLoggedIn)
        _MoreItem(
          icon: Icons.lock_reset_outlined,
          title: _t(context, "Change Password", "پاس ورڈ تبدیل کریں"),
          subtitle: _t(
            context,
            "Update your account password",
            "اپنے اکاؤنٹ کا پاس ورڈ اپ ڈیٹ کریں",
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          ),
        ),
      _MoreItem(
        icon: Icons.logout_rounded,
        title: _t(context, "Logout", "لاگ آؤٹ"),
        subtitle: _t(
          context,
          "Sign out from this device",
          "اس ڈیوائس سے سائن آؤٹ کریں",
        ),
        onTap: () => _confirmLogout(context),
      ),
      _MoreItem(
        icon: Icons.delete_forever_outlined,
        title: _t(context, "Delete Account", "اکاؤنٹ حذف کریں"),
        subtitle: _t(
          context,
          "Permanently remove your account",
          "اپنا اکاؤنٹ مستقل طور پر حذف کریں",
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
        ),
      ),
        _MoreItem(
          icon: Icons.manage_accounts_outlined,
          title: _t(context, "Edit Profile", "پروفائل تبدیل کریں"),
          subtitle: _t(
            context,
            "Change your name, email and contact number",
            "اپنا نام، ای میل اور رابطہ نمبر تبدیل کریں",
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          children: [
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
                    child: const Icon(Icons.menu, size: 22, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(context, "More", "مزید"),
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
                            "Tools, account & legal information",
                            "ٹولز، اکاؤنٹ اور قانونی معلومات",
                          ),
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
            _AccountCard(
              isUrdu: isUrdu,
              auth: auth,
              onLogin: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              onSignup: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              ),
            ),
            const SizedBox(height: 12),
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
                  for (int i = 0; i < items.length; i++) ...[
                    _MoreTile(item: items[i]),
                    if (i != items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withOpacity(0.12),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  final bool isUrdu;
  final AuthProvider auth;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const _AccountCard({
    required this.isUrdu,
    required this.auth,
    required this.onLogin,
    required this.onSignup,
  });

  String _t(String en, String ur) => isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;

    return Container(
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withOpacity(0.35)),
            ),
            child: Icon(
              auth.isLoggedIn ? Icons.verified_user_outlined : Icons.person_outline,
              color: _accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isLoggedIn
                      ? user?.fullName ?? _t("My Account", "میرا اکاؤنٹ")
                      : _t("Guest User", "گیسٹ صارف"),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isLoggedIn
                      ? "${user?.email ?? ""}\n${user?.phone ?? ""}"
                      : _t(
                    "Login or create an account to continue",
                    "جاری رکھنے کے لیے لاگ اِن یا اکاؤنٹ بنائیں",
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                ),
                if (!auth.isLoggedIn) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: BorderSide(color: _accent.withOpacity(0.55)),
                          ),
                          child: Text(
                            _t("Login", "لاگ اِن"),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _t("Signup", "سائن اپ"),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
              child: Icon(item.icon, size: 22, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _accent,
                    ),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
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
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: _accent.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }
}