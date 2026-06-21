import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

/// Central design system for Islamabad Bullion — a dark, luxury teal + gold
/// theme. These tokens are the single source of truth for colour, spacing,
/// radius, elevation, motion and typography. Prefer them over ad-hoc hex values.
class Brand {
  Brand._();

  // ---- Brand identity (kept from the existing app) ----
  static const Color teal = Color(0xFF1A5249); // canonical background
  static const Color tealDeep = Color(0xFF0B3128); // deep edge for gradients
  static const Color card = Color(0xFF0A3C30); // base surface
  static const Color cardHigh = Color(0xFF0F4A3B); // raised surface
  static const Color gold = Color(0xFFDFA273); // accent
  static const Color goldBright = Color(0xFFF0CBA3); // gold highlight
  static const Color goldDeep = Color(0xFFC0814F); // gold shadow

  // ---- Text ----
  static const Color text = Color(0xFFF5EFE8); // warm near-white
  static const Color textMuted = Color(0xFFBFD0C8); // muted teal-white
  static const Color textFaint = Color(0x8CFFFFFF); // ~55% white

  // ---- Semantic (price movement / status) ----
  static const Color up = Color(0xFF53D08A);
  static const Color down = Color(0xFFFF6B6B);
  static const Color warn = Color(0xFFFFC857);

  // ---- Lines / overlays ----
  static Color get hairline => gold.withValues(alpha: 0.22);
  static Color get hairlineSoft => Colors.white.withValues(alpha: 0.08);
  static Color get scrim => Colors.black.withValues(alpha: 0.55);

  // ---- Gradients ----
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C5C4F), Color(0xFF114539), Color(0xFF0A2F26)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F4A3B), Color(0xFF093528)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3D8BC), Color(0xFFDFA273), Color(0xFFC0814F)],
  );

  // ---- Spacing (4 / 8 rhythm) ----
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16, s20 = 20, s24 = 24, s32 = 32;

  // ---- Radii ----
  static const double rSm = 12, rMd = 16, rLg = 20, rXl = 26;

  // ---- Motion ----
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 440);
  static const Curve easeOut = Curves.easeOutCubic;

  // ---- Elevation ----
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: gold.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ---- Typography helpers ----
  /// Serif display (Playfair Display) — brand wordmark, hero headings.
  static TextStyle display(
    double size, {
    Color color = text,
    FontWeight weight = FontWeight.w700,
    double height = 1.1,
    double spacing = 0.2,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
      );

  /// Body / UI sans (Inter).
  static TextStyle sans(
    double size, {
    Color color = text,
    FontWeight weight = FontWeight.w500,
    double height = 1.3,
    double spacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
      );

  /// Inter with tabular figures — for prices and aligned numeric columns.
  static TextStyle number(
    double size, {
    Color color = text,
    FontWeight weight = FontWeight.w700,
    double height = 1.0,
    double spacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Small uppercase label / eyebrow.
  static TextStyle label(
    double size, {
    Color color = textMuted,
    FontWeight weight = FontWeight.w700,
    double spacing = 0.8,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
      );
}
