import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'api_client.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Single-user login against tm-server (`/api/v1/auth`). The bearer token is
/// kept in memory and persisted so a restart does not force a new login.
class AuthService {
  AuthService({
    ApiClient? api,
    Future<SharedPreferences> Function()? prefs,
    DateTime Function()? now,
  }) : _api = api ?? ApiClient.shared,
       _prefs = prefs ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now {
    _api.tokenProvider = () => _token;
  }

  static final AuthService shared = AuthService();

  static const _tokenKey = 'auth.token';
  static const _expiresKey = 'auth.expiresAt';

  final ApiClient _api;
  final Future<SharedPreferences> Function() _prefs;
  final DateTime Function() _now;
  String? _token;

  String? get token => _token;

  /// Loads a stored token and checks it with the server. A rejected or
  /// expired token is discarded; an unreachable server keeps it (offline).
  Future<bool> restore() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_tokenKey);
    final expires = DateTime.tryParse(prefs.getString(_expiresKey) ?? '');
    if (stored == null || expires == null || !expires.isAfter(_now())) {
      await _clear();
      return false;
    }
    _token = stored;
    try {
      final response = await _api
          .get(Uri.parse('${ApiConstants.authURL}/me'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 401) {
        await _clear();
        return false;
      }
    } catch (_) {
      // Server unreachable: trust the unexpired token until a call says otherwise.
    }
    return true;
  }

  Future<void> login(String password) async {
    final response = await _api.post(
      Uri.parse('${ApiConstants.authURL}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        throw const AuthException('Incorrect password', statusCode: 401);
      case 429:
        throw const AuthException(
          'Too many attempts. Try again later.',
          statusCode: 429,
        );
      case 503:
        throw const AuthException(
          'Login is not configured on the server',
          statusCode: 503,
        );
      default:
        throw AuthException(
          'Login failed (${response.statusCode})',
          statusCode: response.statusCode,
        );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['token'] as String;
    final expiresAt = _parseExpiry(json['expiresAt']);
    final prefs = await _prefs();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_expiresKey, expiresAt.toIso8601String());
    _token = token;
    _api.clear();
  }

  Future<void> logout() => _clear();

  Future<void> _clear() async {
    _token = null;
    _api.clear();
    final prefs = await _prefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresKey);
  }

  // Jackson may emit an ISO string or epoch seconds depending on server config.
  static DateTime _parseExpiry(Object? value) {
    if (value is String) return DateTime.parse(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).round(),
        isUtc: true,
      );
    }
    throw const AuthException('Server sent an invalid token expiry');
  }
}
