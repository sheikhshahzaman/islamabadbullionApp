import "package:flutter/material.dart";

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF2D6CDF),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0.8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF2D6CDF),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0.8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
