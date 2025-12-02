import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

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
    return http.post(_uri(path, query), headers: mergedHeaders, body: body);
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
    return http.get(_uri(path, query), headers: mergedHeaders);
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
    return http.put(_uri(path, query), headers: mergedHeaders, body: body);
  }

  static T decodeJson<T>(http.Response res) {
    return json.decode(utf8.decode(res.bodyBytes)) as T;
  }
}
