import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../models/app_user.dart";
import "../services/auth_api.dart";

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = "app_auth_token";

  final AuthApi _api;

  AuthProvider({AuthApi? api}) : _api = api ?? AuthApi();

  AppUser? _user;
  String? _token;
  bool _loading = false;
  bool _sessionChecked = false;
  String? _error;

  AppUser? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get sessionChecked => _sessionChecked;
  String? get error => _error;
  bool get isLoggedIn => _user != null && (_token ?? "").isNotEmpty;

  Future<void> loadSession() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);

      if (savedToken == null || savedToken.isEmpty) {
        _token = null;
        _user = null;
        return;
      }

      _token = savedToken;
      _user = await _api.me(savedToken);
    } catch (_) {
      _token = null;
      _user = null;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      } catch (_) {}
    } finally {
      _loading = false;
      _sessionChecked = true;
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.signup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );

      await _saveSession(result.token, result.user);
      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.login(
        email: email,
        password: password,
      );

      await _saveSession(result.token, result.user);
      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final currentToken = _token;

    _loading = true;
    notifyListeners();

    try {
      if (currentToken != null && currentToken.isNotEmpty) {
        await _api.logout(currentToken);
      }
    } finally {
      await _clearLocalSession();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, AppUser user) async {
    _token = token;
    _user = user;
    _error = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {
      // Account/login succeeded, but local storage failed.
      // This prevents showing a false signup/login failure.
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final currentToken = _token;

    if (currentToken == null || currentToken.isEmpty) {
      _error = "Please login again.";
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _api.updateProfile(
        token: currentToken,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      _user = updatedUser;
      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentToken = _token;

    if (currentToken == null || currentToken.isEmpty) {
      _error = "Please login again.";
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.changePassword(
        token: currentToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.forgotPassword(email: email);
      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.verifyResetCode(
        email: email,
        code: code,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount({
    required String currentPassword,
  }) async {
    final currentToken = _token;

    if (currentToken == null || currentToken.isEmpty) {
      _error = "Please login again.";
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteAccount(
        token: currentToken,
        currentPassword: currentPassword,
      );

      await _clearLocalSession();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    _token = null;
    _user = null;
  }

  String _cleanError(Object e) {
    final text = e.toString();
    return text.replaceFirst("Exception: ", "").trim();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}