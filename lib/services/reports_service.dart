import 'dart:convert';
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

  Future<List<Report>> getReports({bool forceRefresh = false}) async {
    // Return cache if available and not forcing refresh (optional logic, 
    // but for now we always fetch to be safe, but we expose cache for UI to show instantly)
    
    int retries = 3;
    while (retries > 0) {
      try {
        final response = await _client.get(
          ApiConfig.reports,
          auth: true,
        );

        if (response.statusCode == 200) {
          final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
          final reportsList = data['reports'] as List<dynamic>;
          final parsedReports = reportsList
              .map((e) => Report.fromJson(e as Map<String, dynamic>))
              .toList();
          
          // Update cache
          _cachedReports = parsedReports;
          _lastFetchTime = DateTime.now();
          
          return parsedReports;
        } else {
          throw Exception('Failed to load reports: ${response.statusCode}');
        }
      } catch (e) {
        retries--;
        if (retries == 0) {
          // If we have cache even after failure, maybe return it? 
          // For now, let's just rethrow if all retries fail.
          throw Exception('Error fetching reports after retries: $e');
        }
        // Wait briefly before retrying
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return []; // Should not be reached
  }

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

  Future<List<String>> getReportImages(int reportId) async {
    try {
      final response = await _client.get(
        '${ApiConfig.reports}/$reportId/images',
        auth: true,
      );

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
        return List<String>.from(data['images'] ?? []);
      } else {
        throw Exception('Failed to load report images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching report images: $e');
    }
  }
}
