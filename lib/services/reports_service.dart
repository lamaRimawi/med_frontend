import 'dart:convert';
import '../config/api_config.dart';
import '../models/report_model.dart';
import 'api_client.dart';

class ReportsService {
  final ApiClient _client = ApiClient.instance;

  Future<List<Report>> getReports() async {
    try {
      final response = await _client.get(
        ApiConfig.reports,
        auth: true,
      );

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
        final reportsList = data['reports'] as List<dynamic>;
        return reportsList
            .map((e) => Report.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
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
