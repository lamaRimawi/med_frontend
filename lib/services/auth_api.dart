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
}
