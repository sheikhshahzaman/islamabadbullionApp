import "package:flutter_test/flutter_test.dart";
import "package:legacy_ibe/screens/shop/order_tracking_screen.dart";

/// Mirrors gold-website's OrderNumberTest so the app and the site agree on
/// exactly what a typed order number becomes.
void main() {
  group("OrderNumberFormatter", () {
    const expected = "IBE-26249-40571836";

    test("accepts however the customer types it", () {
      const inputs = <String, String>{
        "canonical": "IBE-26249-40571836",
        "lower case": "ibe-26249-40571836",
        "mixed case": "Ibe-26249-40571836",
        "no prefix": "26249-40571836",
        "no hyphens": "IBE2624940571836",
        "digits only": "2624940571836",
        "spaces": "ibe 26249 40571836",
        "extra digits trimmed": "IBE-26249-4057183699",
      };

      inputs.forEach((label, input) {
        expect(
          OrderNumberFormatter.format(input),
          expected,
          reason: "Failed for input style: $label",
        );
      });
    });

    test("adds the IBE prefix while typing", () {
      expect(OrderNumberFormatter.format("2"), "IBE-2");
      expect(OrderNumberFormatter.format("26249"), "IBE-26249");
      expect(OrderNumberFormatter.format("262494"), "IBE-26249-4");
    });

    test("keeps legacy ORD numbers working", () {
      expect(
        OrderNumberFormatter.format("ord-ab12cd34-1712345678"),
        "ORD-AB12CD34-1712345678",
      );
    });

    test("empty input stays empty", () {
      expect(OrderNumberFormatter.format(""), "");
      expect(OrderNumberFormatter.format("---"), "");
    });
  });
}
