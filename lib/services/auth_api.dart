import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthApi {
  // Keys for storing social accounts
  static const String _googleAccountsKey = 'google_accounts';
  static const String _facebookAccountsKey = 'facebook_accounts';

  // Save a Google account email to the list of registered accounts
  static Future<void> _saveGoogleAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_googleAccountsKey);
    Set<String> accounts = {};

    if (accountsJson != null) {
      try {
        final List<dynamic> accountsList = json.decode(accountsJson);
        accounts = accountsList.map((e) => e.toString()).toSet();
      } catch (e) {
        print('Error parsing Google accounts: $e');
      }
    }

    accounts.add(email.toLowerCase().trim());
    await prefs.setString(_googleAccountsKey, json.encode(accounts.toList()));
    print('✅ Saved Google account: $email');
  }

  // Save a Facebook account email to the list of registered accounts
  static Future<void> _saveFacebookAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_facebookAccountsKey);
    Set<String> accounts = {};

    if (accountsJson != null) {
      try {
        final List<dynamic> accountsList = json.decode(accountsJson);
        accounts = accountsList.map((e) => e.toString()).toSet();
      } catch (e) {
        print('Error parsing Facebook accounts: $e');
      }
    }

    accounts.add(email.toLowerCase().trim());
    await prefs.setString(_facebookAccountsKey, json.encode(accounts.toList()));
    print('✅ Saved Facebook account: $email');
  }

  // Check if a Google account exists in saved accounts
  static Future<bool> hasGoogleAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_googleAccountsKey);

    if (accountsJson == null) return false;

    try {
      final List<dynamic> accountsList = json.decode(accountsJson);
      final accounts = accountsList
          .map((e) => e.toString().toLowerCase().trim())
          .toSet();
      return accounts.contains(email.toLowerCase().trim());
    } catch (e) {
      print('Error checking Google account: $e');
      return false;
    }
  }

  // Check if a Facebook account exists in saved accounts
  static Future<bool> hasFacebookAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_facebookAccountsKey);

    if (accountsJson == null) return false;

    try {
      final List<dynamic> accountsList = json.decode(accountsJson);
      final accounts = accountsList
          .map((e) => e.toString().toLowerCase().trim())
          .toSet();
      return accounts.contains(email.toLowerCase().trim());
    } catch (e) {
      print('Error checking Facebook account: $e');
      return false;
    }
  }

  // Get all saved Google accounts
  static Future<List<String>> getGoogleAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_googleAccountsKey);

    if (accountsJson == null) return [];

    try {
      final List<dynamic> accountsList = json.decode(accountsJson);
      return accountsList.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error getting Google accounts: $e');
      return [];
    }
  }

  // Get all saved Facebook accounts
  static Future<List<String>> getFacebookAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString(_facebookAccountsKey);

    if (accountsJson == null) return [];

    try {
      final List<dynamic> accountsList = json.decode(accountsJson);
      return accountsList.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error getting Facebook accounts: $e');
      return [];
    }
  }

  static Future<(bool success, String? message)> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.verifyResetCode,
      body: {'email': email, 'code': code},
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

  static Future<(bool success, String? message, {bool requires2FA})> login({
    required String email,
    required String password,
    String? code,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    final client = ApiClient.instance;
    final Map<String, dynamic> body = {'email': email, 'password': password};
    if (code != null) {
      body['code'] = code;
    }

    final res = await client.post(ApiConfig.login, body: body);

    if (res.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        return (false, 'No access token in response', requires2FA: false);
      }
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_password', password);
      await prefs.setString('user_email', email);
      return (true, null, requires2FA: false);
    }

    if (res.statusCode == 202) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      final requires2fa = data['requires_2fa'] == true;
      return (false, data['message']?.toString(), requires2FA: requires2fa);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Login failed', requires2FA: false);
    } catch (_) {
      return (false, 'Login failed (${res.statusCode})', requires2FA: false);
    }
  }

  static Future<(bool success, String? message)> loginWithGoogle(
    String idToken, {
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    final client = ApiClient.instance;

    try {
      print(
        '🔵 Sending Google authentication to backend: ${ApiConfig.baseUrl}${ApiConfig.googleLogin}',
      );
      print('📋 Google Data Being Sent:');
      print('   - ID Token: ${idToken.substring(0, 50)}...');
      if (accessToken != null && accessToken.isNotEmpty) {
        print(
          '   - Access Token: ${accessToken.substring(0, 50)}... ✅ (for birthday & phone)',
        );
      } else {
        print(
          '   - Access Token: ❌ Not available (birthday & phone may not be retrieved)',
        );
      }

      // Send both id_token and access_token if available
      final body = <String, dynamic>{'id_token': idToken};
      if (accessToken != null && accessToken.isNotEmpty) {
        body['access_token'] = accessToken;
      }

      final res = await client.post(
        ApiConfig.googleLogin,
        body: body, // Pass Map directly, ApiClient will encode it
      );

      print('🔵 Backend response status: ${res.statusCode}');
      print('🔵 Backend response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final token = data['access_token'] as String?;
        if (token == null || token.isEmpty) {
          print('❌ No access token in response');
          return (false, 'No access token in response');
        }
        await prefs.setString('jwt_token', token);
        await prefs.setString('last_login_method', 'google');

        // Save email for session persistence/biometrics if available
        final user = data['user'] as Map<String, dynamic>?;
        final email = user?['email'] as String? ?? data['email'] as String?;
        if (email != null) {
          await prefs.setString('user_email', email);
          // Save this Google account to prevent duplicate account creation
          await _saveGoogleAccount(email);
        }

        print('✅ Google login successful for email: $email');
        return (true, null);
      }

      // Handle error responses
      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final errorMessage =
            data['message']?.toString() ??
            data['detail']?.toString() ??
            'Google login failed';
        print('❌ Google login failed: $errorMessage');
        return (false, errorMessage);
      } catch (e) {
        print('❌ Failed to parse error response: $e');
        return (false, 'Google login failed (${res.statusCode})');
      }
    } catch (e) {
      print('❌ Google login exception: $e');
      return (false, 'Network error: ${e.toString()}');
    }
  }

  static Future<(bool success, String? message)> loginWithFacebook(
    String accessToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    final client = ApiClient.instance;

    try {
      print(
        '🔵 Sending Facebook access token to backend: ${ApiConfig.baseUrl}${ApiConfig.facebookLogin}',
      );
      print('📋 Facebook Data Being Sent:');
      print('   - Access Token: ${accessToken.substring(0, 50)}...');
      print(
        '   - Permissions requested: email, public_profile, user_birthday, user_phone_number',
      );

      final res = await client.post(
        ApiConfig.facebookLogin,
        body: {
          'access_token': accessToken,
        }, // Pass Map directly, ApiClient will encode it
      );

      print('🔵 Backend response status: ${res.statusCode}');
      print('🔵 Backend response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final token = data['access_token'] as String?;
        if (token == null || token.isEmpty) {
          print('❌ No access token in response');
          return (false, 'No access token in response');
        }
        await prefs.setString('jwt_token', token);
        await prefs.setString('last_login_method', 'facebook');

        // Save email for session persistence/biometrics if available
        final user = data['user'] as Map<String, dynamic>?;
        final email = user?['email'] as String? ?? data['email'] as String?;
        if (email != null) {
          await prefs.setString('user_email', email);
          // Save this Facebook account to prevent duplicate account creation
          await _saveFacebookAccount(email);
        }

        print('✅ Facebook login successful for email: $email');
        return (true, null);
      }

      // Handle error responses
      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final errorMessage =
            data['message']?.toString() ??
            data['detail']?.toString() ??
            'Facebook login failed';
        print('❌ Facebook login failed: $errorMessage');
        return (false, errorMessage);
      } catch (e) {
        print('❌ Failed to parse error response: $e');
        return (false, 'Facebook login failed (${res.statusCode})');
      }
    } catch (e) {
      print('❌ Facebook login exception: $e');
      return (false, 'Network error: ${e.toString()}');
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
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'password': password,
        'date_of_birth': dobString,
      },
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
      body: {'email': email},
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
      body: {'email': email, 'code': code},
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
      body: {'email': email},
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
      body: {'email': email, 'code': code, 'new_password': newPassword},
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
      body: {
        'email': email,
        'old_password': oldPassword,
        'new_password': newPassword,
      },
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
      body: user.toJson(),
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

  // 2FA Methods
  static Future<(bool success, String? message)> enable2FA() async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.enable2FA,
      auth: true,
    );

    if (res.statusCode == 200) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Failed to enable 2FA');
    } catch (_) {
      return (false, 'Failed to enable 2FA (${res.statusCode})');
    }
  }

  static Future<(bool success, String? message)> disable2FA() async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.disable2FA, // Ensure this exists in ApiConfig, or use a specific endpoint
      auth: true,
    );

    if (res.statusCode == 200) {
      return (true, null);
    }

    try {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return (false, data['message']?.toString() ?? 'Failed to disable 2FA');
    } catch (_) {
      return (false, 'Failed to disable 2FA (${res.statusCode})');
    }
  }

  static Future<(bool success, String? message)> verify2FA(String code) async {
    final client = ApiClient.instance;
    final res = await client.post(
      ApiConfig.verify2FA,
      body: {'code': code},
      auth: true,
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

  // WebAuthn (Passkeys) Methods

  static Future<(bool success, Map<String, dynamic>? options, String? message)>
  getWebAuthnRegistrationOptions() async {
    final client = ApiClient.instance;

    try {
      print(
        '🔵 Requesting WebAuthn registration options from backend: ${ApiConfig.baseUrl}${ApiConfig.webauthnRegOptions}',
      );

      final res = await client.post(ApiConfig.webauthnRegOptions, auth: true);

      print('🔵 Backend response status: ${res.statusCode}');
      print('🔵 Backend response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        print('✅ WebAuthn registration options received successfully');
        return (true, data, null);
      }

      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final errorMessage =
            data['message']?.toString() ?? 'Failed to get registration options';
        print('❌ WebAuthn registration options failed: $errorMessage');
        return (false, null, errorMessage);
      } catch (e) {
        print('❌ Failed to parse error response: $e');
        return (
          false,
          null,
          'Failed to get registration options (${res.statusCode})',
        );
      }
    } catch (e) {
      print('❌ WebAuthn registration options exception: $e');
      return (false, null, 'Network error: ${e.toString()}');
    }
  }

  static Future<(bool success, String? message)> verifyWebAuthnRegistration(
    Map<String, dynamic> credential,
  ) async {
    final client = ApiClient.instance;

    try {
      print(
        '🔵 Verifying WebAuthn registration with backend: ${ApiConfig.baseUrl}${ApiConfig.webauthnRegVerify}',
      );

      final res = await client.post(
        ApiConfig.webauthnRegVerify,
        body: credential,
        auth: true,
      );

      print('🔵 Backend response status: ${res.statusCode}');
      print('🔵 Backend response body: ${res.body}');

      if (res.statusCode == 200) {
        print('✅ WebAuthn registration verified successfully');
        return (true, 'Biometric login enabled successfully');
      }

      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final errorMessage =
            data['message']?.toString() ?? 'Failed to verify registration';
        print('❌ WebAuthn registration verification failed: $errorMessage');
        return (false, errorMessage);
      } catch (e) {
        print('❌ Failed to parse error response: $e');
        return (false, 'Failed to verify registration (${res.statusCode})');
      }
    } catch (e) {
      print('❌ WebAuthn registration verification exception: $e');
      return (false, 'Network error: ${e.toString()}');
    }
  }

  static Future<(bool success, Map<String, dynamic>? options, String? message)>
  getWebAuthnLoginOptions(String email) async {
    final client = ApiClient.instance;

    try {
      print(
        '🔵 Requesting WebAuthn login options from backend: ${ApiConfig.baseUrl}${ApiConfig.webauthnLoginOptions}',
      );
      print('🔵 Email: $email');

      final res = await client.post(
        ApiConfig.webauthnLoginOptions,
        body: {'email': email},
      );

      print('🔵 Backend response status: ${res.statusCode}');
      print('🔵 Backend response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        print('✅ WebAuthn login options received successfully');
        return (true, data, null);
      }

      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final errorMessage =
            data['message']?.toString() ?? 'Failed to get login options';
        print('❌ WebAuthn login options failed: $errorMessage');
        return (false, null, errorMessage);
      } catch (e) {
        print('❌ Failed to parse error response: $e');
        return (false, null, 'Failed to get login options (${res.statusCode})');
      }
    } catch (e) {
      print('❌ WebAuthn login options exception: $e');
      return (false, null, 'Network error: ${e.toString()}');
    }
  }

  static Future<(bool success, String? message)> verifyWebAuthnLogin({
    required String email,
    required Map<String, dynamic> assertion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    final client = ApiClient.instance;

    try {
      print(
        '🔵 Verifying WebAuthn login with backend: ${ApiConfig.baseUrl}${ApiConfig.webauthnLoginVerify}',
      );
      print('🔵 Email: $email');

      final res = await client.post(
        ApiConfig.webauthnLoginVerify,
        body: {'email': email, ...assertion},
      );

      print('🔵 Backend response status: ${res.statusCode}');
      print('🔵 Backend response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final token = data['access_token'] as String?;
        if (token == null || token.isEmpty) {
          print('❌ No access token in response');
          return (false, 'No access token in response');
        }
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_email', email);
        print('✅ WebAuthn login successful');
        return (true, null);
      }

      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final errorMessage = data['message']?.toString() ?? 'Login failed';
        print('❌ WebAuthn login failed: $errorMessage');
        return (false, errorMessage);
      } catch (e) {
        print('❌ Failed to parse error response: $e');
        return (false, 'Login failed (${res.statusCode})');
      }
    } catch (e) {
      print('❌ WebAuthn login verification exception: $e');
      return (false, 'Network error: ${e.toString()}');
    }
  }


}
