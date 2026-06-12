import "dart:convert";

import "package:http/http.dart" as http;

import "../config.dart";
import "../models/shop_models.dart";
import "api_client.dart";

/// Client for the Laravel shop endpoints (catalog, orders, verification).
class ShopApi {
  final ApiClient _client;
  ShopApi(this._client);

  Uri _uri(String path) => Uri.parse("${AppConfig.apiBase}$path");

  Future<List<ShopCategory>> fetchCategories() async {
    final json = await _client.getJson(_uri("/categories"));
    return (json["categories"] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ShopCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ShopProduct>> fetchProducts({String? categorySlug}) async {
    final query = categorySlug == null ? "" : "?category=$categorySlug";
    final json = await _client.getJson(_uri("/products$query"));
    return (json["products"] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ShopProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Creates the order from the local cart. Prices are recalculated
  /// server-side; the response carries the final total.
  Future<CreatedOrder> createOrder({
    required String customerName,
    required String customerPhone,
    required Map<int, int> productQuantities,
  }) async {
    final json = await _client.postJson(
      _uri("/orders"),
      body: {
        "customer_name": customerName,
        "customer_phone": customerPhone,
        "items": productQuantities.entries
            .map((e) => {"product_id": e.key, "quantity": e.value})
            .toList(),
      },
    );
    return CreatedOrder.fromJson(json);
  }

  Future<CreatedOrder> fetchOrder(String orderNumber) async {
    final json = await _client.getJson(_uri("/orders/$orderNumber"));
    return CreatedOrder.fromJson(json);
  }

  /// Uploads the payment proof screenshot (multipart).
  Future<ShopOrder> submitPayment({
    required String orderNumber,
    required String method,
    required String proofImagePath,
    String? referenceNumber,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      _uri("/orders/$orderNumber/payment"),
    );
    request.headers["Accept"] = "application/json";
    request.fields["method"] = method;
    if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
      request.fields["reference_number"] = referenceNumber.trim();
    }
    request.files.add(
      await http.MultipartFile.fromPath("proof_image", proofImagePath),
    );

    final streamed =
        await request.send().timeout(const Duration(seconds: 60));
    final body = utf8.decode(await streamed.stream.toBytes());

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      String message = "Upload failed (HTTP ${streamed.statusCode})";
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded["message"] != null) {
          message = decoded["message"].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    final decoded = jsonDecode(body);
    return ShopOrder.fromJson(
      Map<String, dynamic>.from((decoded as Map)["order"] as Map),
    );
  }

  /// Verify by printed serial number or by QR token (from /v/{token} URLs).
  Future<VerifyResult> verify({
    String? serial,
    String? token,
    String? customerName,
    String? customerPhone,
  }) async {
    final json = await _client.postJson(
      _uri("/verify"),
      body: {
        if (serial != null && serial.trim().isNotEmpty) "serial": serial.trim(),
        if (token != null && token.trim().isNotEmpty) "token": token.trim(),
        if (customerName != null && customerName.trim().isNotEmpty)
          "customer_name": customerName.trim(),
        if (customerPhone != null && customerPhone.trim().isNotEmpty)
          "customer_phone": customerPhone.trim(),
      },
    );
    return VerifyResult.fromJson(json);
  }
}
