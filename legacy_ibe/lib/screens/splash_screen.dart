import "dart:async";
import "package:flutter/material.dart";
import "home_screen.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF1a5249);

  late final AnimationController _c;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _ringFade;
  late final Animation<double> _ringScale;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    _logoFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.10, 0.65, curve: Curves.easeOutBack)),
    );

    _ringFade = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.15, 0.75, curve: Curves.easeOut)),
    );

    _ringScale = Tween<double>(begin: 0.55, end: 1.25).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.15, 0.95, curve: Curves.easeOut)),
    );

    _c.forward();

    // ✅ Keep splash at least 3 seconds
    _navTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle expanding ring behind the logo
                  Opacity(
                    opacity: _ringFade.value,
                    child: Transform.scale(
                      scale: _ringScale.value,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.55),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Logo card (modern)
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a3c30),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _LogoOrFallback(cs: cs),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoOrFallback extends StatelessWidget {
  final ColorScheme cs;
  const _LogoOrFallback({required this.cs});

  @override
  Widget build(BuildContext context) {
    // Preferred: show your actual logo asset
    // Make sure this exists in pubspec.yaml:
    // assets/images/splash.png
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        "assets/images/splash.png",
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          // Fallback icon if asset missing
          return Center(
            child: Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.92),
            ),
          );
        },
      ),
    );
  }
}