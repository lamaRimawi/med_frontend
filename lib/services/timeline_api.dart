import 'dart:convert';
import '../config/api_config.dart';
import '../models/timeline_models.dart';
import 'api_client.dart';

class TimelineApi {
  static final ApiClient _client = ApiClient.instance;

  static Future<List<TimelineReport>> getTimeline() async {
    final response = await _client.get(
      ApiConfig.reportsTimeline,
      auth: true,
    );

    if (response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      final timelineList = data['timeline'] as List;
      return timelineList
          .map((item) => TimelineReport.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load timeline: ${response.statusCode}');
    }
  }

  static Future<TimelineStats> getStats() async {
    final response = await _client.get(
      ApiConfig.reportsStats,
      auth: true,
    );

    if (response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      return TimelineStats.fromJson(data);
    } else {
      throw Exception('Failed to load stats: ${response.statusCode}');
    }
  }

  static Future<HealthTrends> getTrends(List<String> fieldNames) async {
    final fieldNamesParam = fieldNames.join(',');
    final response = await _client.get(
      ApiConfig.reportsTrends,
      query: {'field_name': fieldNamesParam},
      auth: true,
    );

    if (response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      return HealthTrends.fromJson(data);
    } else {
      throw Exception('Failed to load trends: ${response.statusCode}');
    }
  }
}
