import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AccessVerificationException implements Exception {
  final String message;
  final bool requiresVerification;
  final int? verificationId;
  final String? instructions;

  AccessVerificationException({
    required this.message,
    this.requiresVerification = true,
    this.verificationId,
    this.instructions,
  });

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> _getToken() => getToken();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl;
    return Uri.parse(base + path).replace(queryParameters: query);
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? query,
    bool auth = false,
    bool skipGlobalLogoutOn401 = false,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        mergedHeaders['Authorization'] = 'Bearer $token';
      }
    }
    final response = await http
        .post(_uri(path, query), headers: mergedHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    // Handle Access Verification (403)
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['requires_verification'] == true) {
          throw AccessVerificationException(
            message: body['message'] ?? 'Access verification required',
            verificationId: body['verification_id'],
            instructions: body['instructions'],
          );
        }
      } catch (e) {
        if (e is AccessVerificationException) rethrow;
        // If parsing fails or it's a different 403, standard error handling applies
      }
    }

    // Only throw exception for 401 if this was an authenticated request AND we don't want to skip global logout
    if (response.statusCode == 401 && auth && !skipGlobalLogoutOn401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }

    return response;
  }

  Future<bool> registerFcmToken(String token, String deviceType) async {
    try {
      final response = await post(
        '/users/register-token',
        body: {
          'fcm_token': token,
          'device_type': deviceType,
        },
        auth: true,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await get('/users/notifications', auth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await post(
        '/users/notifications/$notificationId/read',
        auth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };
    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        mergedHeaders['Authorization'] = 'Bearer $token';
      }
    }
    final response = await http
        .get(_uri(path, query), headers: mergedHeaders)
        .timeout(const Duration(seconds: 60));

    // Handle Access Verification (403)
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['requires_verification'] == true) {
          throw AccessVerificationException(
            message: body['message'] ?? 'Access verification required',
            verificationId: body['verification_id'],
            instructions: body['instructions'],
          );
        }
      } catch (e) {
        if (e is AccessVerificationException) rethrow;
      }
    }
    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }
    return response;
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        mergedHeaders['Authorization'] = 'Bearer $token';
      }
    }
    final response = await http
        .put(_uri(path, query), headers: mergedHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

     // Handle Access Verification (403)
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['requires_verification'] == true) {
          throw AccessVerificationException(
            message: body['message'] ?? 'Access verification required',
            verificationId: body['verification_id'],
            instructions: body['instructions'],
          );
        }
      } catch (e) {
        if (e is AccessVerificationException) rethrow;
      }
    }
    if (response.statusCode == 401) {
      // Token expired or invalid
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      // You might want to trigger a navigation to login here or throw a specific exception
      throw Exception('Unauthorized: Token expired');
    }
    return response;
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
    Object? body,
    bool auth = false,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        mergedHeaders['Authorization'] = 'Bearer $token';
      }
    }
    final response = await http
        .delete(_uri(path, query), headers: mergedHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    // Handle Access Verification (403)
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['requires_verification'] == true) {
          throw AccessVerificationException(
            message: body['message'] ?? 'Access verification required',
            verificationId: body['verification_id'],
            instructions: body['instructions'],
          );
        }
      } catch (e) {
        if (e is AccessVerificationException) rethrow;
      }
    }
    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }
    return response;
  }

  Future<http.Response> postMultipart(
    String path, {
    required String filePath,
    Map<String, String>? fields,
    bool auth = false,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));

    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }
    return response;
  }

  Future<http.Response> putMultipart(
    String path, {
    String? filePath,
    Map<String, String>? fields,
    bool auth = false,
  }) async {
    final request = http.MultipartRequest('PUT', _uri(path));

    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_image', filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }
    return response;
  }

  Future<http.Response> postMultipartMultiple(
    String path, {
    required List<String> filePaths,
    Map<String, String>? fields,
    bool auth = false,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    
    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    for (var filePath in filePaths) {
      // Using 'file' key repeatedly. If backend expects 'files', this might need adjustment.
      // But typically arrays are handled by repeating the key or 'file[]'.
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }
    return response;
  }

  static T decodeJson<T>(http.Response res) {
    return json.decode(utf8.decode(res.bodyBytes)) as T;
  }

  // Session Token Management
  Future<void> saveSessionToken(String resourceType, String resourceId, String token, int expiresInMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'session_token_${resourceType}_$resourceId';
    final expiry = DateTime.now().add(Duration(minutes: expiresInMinutes)).toIso8601String();
    print('Saving Session Token Key: $key, Expiry: $expiry (Minutes: $expiresInMinutes)');
    await prefs.setString(key, jsonEncode({'token': token, 'expiry': expiry}));
  }

  Future<bool> hasValidSession(String resourceType, String resourceId) async {
    try {
      final token = await getSessionToken(resourceType, resourceId);
      return token != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSessionToken(String resourceType, String resourceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload to ensure we have the latest token
      final key = 'session_token_${resourceType}_$resourceId';
      final dataStr = prefs.getString(key);
      if (dataStr == null) {
        print('Get Session Token: No token found for key $key');
        return null;
      }
      
      final data = jsonDecode(dataStr);
      final expiry = DateTime.parse(data['expiry']);
      if (DateTime.now().isAfter(expiry)) {
        print('Get Session Token: Token expired for key $key (Expired at $expiry)');
        await prefs.remove(key);
        return null;
      }
      print('Get Session Token: Found valid token for key $key');
      return data['token'];
    } catch (e) {
      print('Get Session Token Error: $e');
      return null;
    }
  }

  // Verification API Calls
  Future<Map<String, dynamic>> requestAccessVerification({
    required String resourceType, 
    required String resourceId,
    String method = 'otp'
  }) async {
    final response = await post(
       '/auth/request-access-verification', // Adjust if ApiConfig has a prefix or specific path constant
       auth: true,
       body: {
         'resource_type': resourceType,
         'resource_id': int.tryParse(resourceId) ?? resourceId, // Backend likely expects int for ID if it's numeric
         'method': method,
       },
    );

    if (response.statusCode == 200) {
      return decodeJson(response);
    } else {
       throw Exception('Failed to request verification: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> verifyAccessCode({
    required String resourceType,
    required String resourceId,
    required String code,
  }) async {
     try {
       // Debugging: Ensure we send exactly what is expected. 
       // Reverting to int for resource_id to match request endpoint.
       final body = {
         'resource_type': resourceType,
         'resource_id': int.tryParse(resourceId) ?? resourceId, 
         'code': code,
       };
       
       print('Verifying with body: $body');

       final response = await post(
         '/auth/verify-access-code',
         auth: true,
         body: body,
       );

       print('Verify response [${response.statusCode}]: ${response.body}');

       if (response.statusCode == 200) {
         return decodeJson(response);
       } else {
         // Try to parse specific error message
         try {
           // Using direct jsonDecode to avoid generic type issues
           final respBody = jsonDecode(response.body);
           throw Exception(respBody['message'] ?? 'Verification failed (Status ${response.statusCode})');
         } catch (e) {
           if (e is Exception && !e.toString().contains('Verification failed (Status')) {
              rethrow; // It was the exception we just threw
           }
           throw Exception('Verification failed (Status ${response.statusCode})');
         }
       }
     } catch (e) {
       // Catch specific 500s or network errors
       if (e.toString().contains('500')) {
         throw Exception('Server error (500). Please try again later.');
       }
       rethrow;
     }
  }
}
