import "package:flutter_test/flutter_test.dart";
import "package:legacy_ibe/widgets/animated_price_text.dart";

/// The cosmetic tick must never change how a price reads at a glance:
/// everything above the moving digits stays exactly as the admin set it.
void main() {
  group("lastTwoDigits", () {
    test("moves only the two digits before the decimal point", () {
      // Real board values from the rate cards.
      for (final base in [456999.0, 454000.0, 391810.0, 39181.0, 8500.0]) {
        for (var lastTwo = 0; lastTwo < 100; lastTwo++) {
          final shown = applyPriceFluctuation(
            value: base,
            mode: PriceFluctuation.lastTwoDigits,
            lastTwo: lastTwo,
          );

          expect(
            shown ~/ 100,
            base ~/ 100,
            reason: "digits above the last two moved for $base",
          );
          expect(shown, inInclusiveRange(base - base % 100, base - base % 100 + 99));
        }
      }
    });

    test("covers the whole range of the last two digits", () {
      final seen = <int>{};
      for (var lastTwo = 0; lastTwo < 100; lastTwo++) {
        seen.add(applyPriceFluctuation(
          value: 456999,
          mode: PriceFluctuation.lastTwoDigits,
          lastTwo: lastTwo,
        ).toInt() % 100);
      }
      expect(seen.length, 100);
    });

    test("the admin value itself is reachable", () {
      final shown = applyPriceFluctuation(
        value: 456999,
        mode: PriceFluctuation.lastTwoDigits,
        lastTwo: 99,
      );
      expect(shown, 456999);
    });

    test("small values fall back so they are not distorted", () {
      // A USD/PKR style rate: moving the last two digits would swing it wildly.
      expect(
        effectivePriceFluctuation(284, PriceFluctuation.lastTwoDigits),
        PriceFluctuation.decimals,
      );

      final shown = applyPriceFluctuation(
        value: 284,
        mode: PriceFluctuation.lastTwoDigits,
        lastTwo: 42,
      );
      expect(shown.toInt(), 284, reason: "rupee figure must not move");
    });

    test("keeps the fractional part of the real value", () {
      final shown = applyPriceFluctuation(
        value: 39311.63,
        mode: PriceFluctuation.lastTwoDigits,
        lastTwo: 7,
      );
      expect(shown, closeTo(39307.63, 0.001));
    });
  });

  group("decimals (international spot)", () {
    test("locks the integer part and moves only the decimals", () {
      final shown = applyPriceFluctuation(
        value: 4123.45,
        mode: PriceFluctuation.decimals,
        lastTwo: 88,
      );
      expect(shown, closeTo(4123.88, 0.001));
      expect(shown.floor(), 4123, reason: "dollar figure must stay locked");
    });
  });

  group("none", () {
    test("returns the value untouched", () {
      expect(
        applyPriceFluctuation(
          value: 456999,
          mode: PriceFluctuation.none,
          lastTwo: 42,
        ),
        456999,
      );
    });
  });
}
