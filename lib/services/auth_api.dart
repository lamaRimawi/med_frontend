import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'api_client.dart';

class AuthApi {
  static Future<(bool success, String? message)> login({
    required String email,
    required String password,
  }) async {
    final client = ApiClient.instance;

    final res = await client.post(
      ApiConfig.login,
      body: json.encode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        return (false, 'No access token in response');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Login failed');
    } catch (_) {
      return (false, 'Login failed (${res.statusCode})');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<(bool success, String? message)> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.register,
      body: json.encode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Registration failed');
    } catch (_) {
      return (false, 'Registration failed (${res.statusCode})');
    }
  }

  static Future<(bool success, String? message, String? code)> forgotPassword({
    required String email,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.forgotPassword,
      body: json.encode({'email': email}),
    );

    if (res.statusCode == 200) {
      // Check if code is returned in response (for dev/testing without email)
      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final code = data['code']?.toString();
        return (true, data['message']?.toString(), code);
      } catch (_) {
        return (true, null, null);
      }
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Request failed', null);
    } catch (_) {
      return (false, 'Request failed (${res.statusCode})', null);
    }
  }

  static Future<(bool success, String? message)> verifyEmail({
    required String email,
    required String code,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.verifyEmail,
      body: json.encode({
        'email': email,
        'code': code,
      }),
    );

    if (res.statusCode == 200) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Verification failed');
    } catch (_) {
      return (false, 'Verification failed (${res.statusCode})');
    }
  }

  static Future<(bool success, String? message)> resendVerification({
    required String email,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.resendVerification,
      body: json.encode({'email': email}),
    );

    if (res.statusCode == 200) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Resend failed');
    } catch (_) {
      return (false, 'Resend failed (${res.statusCode})');
    }
  }

  static Future<(bool success, String? message)> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.resetPassword,
      body: json.encode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );

    if (res.statusCode == 200) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Reset failed');
    } catch (_) {
      return (false, 'Reset failed (${res.statusCode})');
    }
  }
}
