import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";

import "brand.dart";

/// App theme — a single dark, luxury teal + gold look used in both "light" and
/// "dark" system modes (the app is intentionally always dark-teal). Built on the
/// [Brand] design tokens.
class AppTheme {
  static ThemeData light() => _build();
  static ThemeData dark() => _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Brand.gold,
      onPrimary: const Color(0xFF1A1207),
      secondary: Brand.goldBright,
      onSecondary: const Color(0xFF1A1207),
      surface: Brand.card,
      onSurface: Brand.text,
      surfaceContainerHighest: Brand.cardHigh,
      error: Brand.down,
      outline: Brand.gold.withValues(alpha: 0.35),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: Brand.text, displayColor: Brand.text)
        .copyWith(
          displayLarge: Brand.display(40),
          displayMedium: Brand.display(32),
          displaySmall: Brand.display(26),
          headlineMedium: Brand.display(24),
          headlineSmall: Brand.display(22),
          titleLarge: Brand.display(20, weight: FontWeight.w700),
          titleMedium: Brand.sans(16, weight: FontWeight.w700),
          bodyLarge: Brand.sans(15, weight: FontWeight.w500, color: Brand.text),
          bodyMedium: Brand.sans(14, weight: FontWeight.w500, color: Brand.textMuted),
          labelLarge: Brand.sans(14, weight: FontWeight.w700),
        );

    return base.copyWith(
      scaffoldBackgroundColor: Brand.teal,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Brand.text,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: Brand.display(20, weight: FontWeight.w700),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: Brand.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rLg)),
      ),
      dividerTheme: DividerThemeData(color: Brand.hairlineSoft, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.gold,
          foregroundColor: const Color(0xFF1A1207),
          textStyle: Brand.sans(15, weight: FontWeight.w800, color: const Color(0xFF1A1207)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rMd)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Brand.gold,
          side: BorderSide(color: Brand.gold.withValues(alpha: 0.5)),
          textStyle: Brand.sans(15, weight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rMd)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Brand.gold,
          textStyle: Brand.sans(14, weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Brand.card.withValues(alpha: 0.55),
        hintStyle: Brand.sans(14, color: Brand.textFaint, weight: FontWeight.w500),
        labelStyle: Brand.sans(14, color: Brand.textMuted, weight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brand.rMd),
          borderSide: BorderSide(color: Brand.hairlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brand.rMd),
          borderSide: const BorderSide(color: Brand.gold, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brand.rMd),
          borderSide: BorderSide(color: Brand.hairlineSoft),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Brand.card,
        selectedColor: Brand.gold,
        side: BorderSide(color: Brand.hairline),
        labelStyle: Brand.sans(13, weight: FontWeight.w600),
        secondaryLabelStyle: Brand.sans(13, weight: FontWeight.w700, color: const Color(0xFF1A1207)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rMd)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Brand.cardHigh,
        contentTextStyle: Brand.sans(14, color: Brand.text, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rMd)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Brand.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.rLg)),
        titleTextStyle: Brand.display(20, weight: FontWeight.w700),
        contentTextStyle: Brand.sans(14, color: Brand.textMuted, weight: FontWeight.w500),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Brand.card,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.gold),
      iconTheme: const IconThemeData(color: Brand.gold),
    );
  }
}
