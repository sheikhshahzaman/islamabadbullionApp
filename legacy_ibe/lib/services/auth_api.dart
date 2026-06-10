import "dart:convert";

import "../config/api_config.dart";
import "../models/app_user.dart";
import "api_client.dart";

class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult({
    required this.token,
    required this.user,
  });
}

class AuthApi {
  final ApiClient _client;

  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  String _apiMessage(Object error) {
    final text = error.toString();
    final start = text.indexOf("{");

    if (start >= 0) {
      final rawJson = text.substring(start);
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map && decoded["message"] != null) {
          return "${decoded["message"]}";
        }
      } catch (_) {}
    }

    if (text.toLowerCase().contains("socketexception") ||
        text.toLowerCase().contains("failed host lookup") ||
        text.toLowerCase().contains("connection timed out") ||
        text.toLowerCase().contains("network is unreachable")) {
      return "Please check your internet connection.";
    }

    return "Something went wrong. Please try again.";
  }

  Uri _uri(String path) => Uri.parse("${ApiConfig.authBaseUrl}/$path");

  Future<AuthResult> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final json = await _client.postJson(
        _uri("signup.php"),
        body: {
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "phone": phone,
          "password": password,
        },
      );

      return AuthResult(
        token: "${json["token"] ?? ""}",
        user: AppUser.fromJson(Map<String, dynamic>.from(json["user"] ?? {})),
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final json = await _client.postJson(
        _uri("login.php"),
        body: {
          "email": email,
          "password": password,
        },
      );

      return AuthResult(
        token: "${json["token"] ?? ""}",
        user: AppUser.fromJson(Map<String, dynamic>.from(json["user"] ?? {})),
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<AppUser> me(String token) async {
    try {
      final json = await _client.getJson(
        _uri("me.php"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      return AppUser.fromJson(Map<String, dynamic>.from(json["user"] ?? {}));
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<AppUser> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      final json = await _client.postJson(
        _uri("update_profile.php"),
        headers: {
          "Authorization": "Bearer $token",
        },
        body: {
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "phone": phone,
        },
      );

      return AppUser.fromJson(Map<String, dynamic>.from(json["user"] ?? {}));
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.postJson(
        _uri("change_password.php"),
        headers: {
          "Authorization": "Bearer $token",
        },
        body: {
          "current_password": currentPassword,
          "new_password": newPassword,
        },
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.postJson(
        _uri("verify_reset_code.php"),
        body: {
          "email": email,
          "code": code,
        },
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }


  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      await _client.postJson(
        _uri("forgot_password.php"),
        body: {
          "email": email,
        },
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _client.postJson(
        _uri("reset_password.php"),
        body: {
          "email": email,
          "code": code,
          "new_password": newPassword,
        },
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<void> deleteAccount({
    required String token,
    required String currentPassword,
  }) async {
    try {
      await _client.postJson(
        _uri("delete_account.php"),
        headers: {
          "Authorization": "Bearer $token",
        },
        body: {
          "current_password": currentPassword,
        },
      );
    } catch (e) {
      throw Exception(_apiMessage(e));
    }
  }

  Future<void> logout(String token) async {
    try {
      await _client.postJson(
        _uri("logout.php"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
    } catch (_) {
      // Local logout should still continue even if server logout fails.
    }
  }

  void dispose() => _client.dispose();
}