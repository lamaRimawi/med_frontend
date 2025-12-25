import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthApi {
  static Future<(bool success, String? message)> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.verifyResetCode,
      body: json.encode({'email': email, 'code': code}),
    );

    if (res.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      if (data['code_valid'] == true) {
        return (true, null);
      } else {
        return (false, data['message']?.toString() ?? 'Invalid reset code');
      }
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Invalid reset code');
    } catch (_) {
      return (false, 'Invalid reset code ({res.statusCode})');
    }
  }

  static Future<(bool success, String? message)> login({
    required String email,
    required String password,
  }) async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    
    // Clear any old token before attempting new login
    await prefs.remove('jwt_token');
    
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
      await prefs.setString('jwt_token', token);
      
      // Save the password locally after successful login
      await prefs.setString('user_password', password);
      // Save the email locally for biometric login
      await prefs.setString('user_email', email);
      
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
    required DateTime dateOfBirth,
    required String password,
  }) async {
    final client = ApiClient.instance;

    // Split name into first and last name
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Format date as YYYY-MM-DD
    final dobString =
        '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';

    final res = await client.post(
      ApiConfig.register,
      body: json.encode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'password': password,
        'date_of_birth': dobString,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      final msg =
          data['message']?.toString() ??
          data['detail']?.toString() ??
          data['error']?.toString() ??
          'Registration failed';
      print('Registration error: $data'); // Debug log
      return (false, msg);
    } catch (e) {
      print('Registration error (parse failed): ${res.body}'); // Debug log
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
      body: json.encode({'email': email, 'code': code}),
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

  static Future<(bool success, String? message)> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.changePassword,
      body: json.encode({
        'email': email,
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
      auth: true,
      skipGlobalLogoutOn401: true,
    );

    if (res.statusCode == 200) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Password change failed');
    } catch (_) {
      return (false, 'Password change failed (${res.statusCode})');
    }
  }

  static Future<(bool success, User? user, String? message)>
  getUserProfile() async {
    final client = ApiClient.instance;
    final res = await client.get(ApiConfig.userProfile, auth: true);

    if (res.statusCode == 200) {
      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final user = User.fromJson(data);
        await User.saveToPrefs(user);
        return (true, user, null);
      } catch (e) {
        print('Profile parse error: $e');
        return (false, null, 'Failed to parse profile data');
      }
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (
        false,
        null,
        data['message']?.toString() ?? 'Failed to fetch profile',
      );
    } catch (_) {
      return (false, null, 'Failed to fetch profile (${res.statusCode})');
    }
  }

  static Future<(bool success, String? message)> updateUserProfile(
    User user,
  ) async {
    final client = ApiClient.instance;
    final res = await client.put(
      ApiConfig.userProfile,
      body: json.encode(user.toJson()),
      auth: true,
    );

    if (res.statusCode == 200) {
      await User.saveToPrefs(user);
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Update failed');
    } catch (_) {
      return (false, 'Update failed (${res.statusCode})');
    }
  }
}
