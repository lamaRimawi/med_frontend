import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/report_model.dart';
import 'api_client.dart';

class ReportsService {
  // Singleton pattern
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  final ApiClient _client = ApiClient.instance;

  // In-memory cache
  List<Report>? _cachedReports;
  DateTime? _lastFetchTime;

  List<Report>? get cachedReports => _cachedReports;

  Future<List<Report>> getReports({bool forceRefresh = false, int? profileId}) async {
    // Return cache only if no profile filter is applied and not forcing refresh
    if (!forceRefresh && profileId == null && _cachedReports != null) {
      // Small optimization: if cache is very fresh, return it immediately
      if (_lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!).inSeconds < 10) {
        return _cachedReports!;
      }
    }

    int retries = 3;
    while (retries > 0) {
      try {
        String path = ApiConfig.reports;
        if (profileId != null) {
          path = '$path?profile_id=$profileId';
        }
        
        final response = await _client.get(path, auth: true);

        if (response.statusCode == 200) {
          final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
          final reportsList = data['reports'] as List<dynamic>;
          final parsedReports = reportsList
              .map((e) => Report.fromJson(e as Map<String, dynamic>))
              .toList();

          // Only update cache if it's for the main "Self" profile (profileId is null or matches self)
          if (profileId == null) {
            _cachedReports = parsedReports;
            _lastFetchTime = DateTime.now();
          }

          return parsedReports;
        } else {
          throw Exception('Failed to load reports: ${response.statusCode}');
        }
      } catch (e) {
        // Don't retry if unauthorized (token expired)
        if (e.toString().contains('Unauthorized')) {
          rethrow;
        }

        retries--;
        if (retries == 0) {
          // If we have cache even after failure, maybe return it?
          // For now, let's just rethrow if all retries fail.
          throw Exception('Error fetching reports after retries: $e');
        }
        // Wait briefly before retrying
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return []; // Should not be reached
  }

  Future<Report> getReport(int reportId) => getReportDetail(reportId);

  Future<Report> getReportDetail(int reportId) async {
    try {
      final response = await _client.get(
        '${ApiConfig.reports}/$reportId',
        auth: true,
      );

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
        return Report.fromJson(data['report'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load report detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching report detail: $e');
    }
  }

  Future<void> deleteReport(int reportId) async {
    try {
      final response = await _client.delete(
        '${ApiConfig.reports}/$reportId',
        auth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting report: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReportImages(int reportId) async {
    try {
      final response = await _client.get(
        '${ApiConfig.reports}/$reportId/images',
        auth: true,
      );

      if (response.statusCode == 200) {
        final String rawBody = utf8.decode(response.bodyBytes);
        final dynamic decoded = json.decode(rawBody);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('files')) {
            final files = decoded['files'] as List<dynamic>;
            return files.map((f) => f is Map<String, dynamic> ? f : {'filename': f.toString()}).toList();
          } else if (decoded.containsKey('images')) {
            final images = decoded['images'] as List<dynamic>;
            return images.map((img) => img is Map<String, dynamic> ? img : {'filename': img.toString()}).toList();
          }
        } else if (decoded is List) {
          return decoded.map((item) {
            if (item is Map<String, dynamic>) return item;
            return {'filename': item.toString(), 'index': decoded.indexOf(item) + 1};
          }).toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load report images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching report images: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTimeline() async {
    try {
      final response = await _client.get(
        '${ApiConfig.reports}/timeline',
        auth: true,
      );

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
        return List<Map<String, dynamic>>.from(data['timeline']);
      } else {
        throw Exception('Failed to load timeline: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching timeline: $e');
    }
  }
}
