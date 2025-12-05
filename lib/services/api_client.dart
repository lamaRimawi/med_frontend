import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

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
    final response = await http.post(_uri(path, query), headers: mergedHeaders, body: body);
    
    // Only throw exception for 401 if this was an authenticated request
    if (response.statusCode == 401 && auth) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      throw Exception('Unauthorized: Token expired');
    }
    
    return response;
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
    final response = await http.get(_uri(path, query), headers: mergedHeaders)
        .timeout(const Duration(seconds: 30));
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
    final response = await http.put(_uri(path, query), headers: mergedHeaders, body: body);
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
    final response = await http.delete(_uri(path, query), headers: mergedHeaders);
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

  static T decodeJson<T>(http.Response res) {
    return json.decode(utf8.decode(res.bodyBytes)) as T;
  }
}
