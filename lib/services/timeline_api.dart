import 'dart:convert';
import '../config/api_config.dart';
import '../models/timeline_models.dart';
import '../models/extracted_report_data.dart';
import 'api_client.dart';

class TimelineApi {
  static final ApiClient _client = ApiClient.instance;

  static Future<List<TimelineReport>> getTimeline() async {
    final response = await _client.get(ApiConfig.reportsTimeline, auth: true);

    if (response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      final timelineList = data['timeline'] as List;
      return timelineList.map((item) => TimelineReport.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load timeline: ${response.statusCode}');
    }
  }

  static Future<TimelineStats> getStats() async {
    final response = await _client.get(ApiConfig.reportsStats, auth: true);

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

  static Future<ExtractedReportData> getReport(int reportId) async {
    final response = await _client.get(
      '${ApiConfig.reports}/$reportId',
      auth: true,
    );

    if (response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      // Map backend response to ExtractedReportData
      // This mapping depends on your backend response structure for a single report
      // Assuming a structure similar to what ExtractedReportData expects

      final reportData = data['report_data'] ?? {};
      final patientData = reportData['patient_info'] ?? {};
      final doctorData = reportData['doctor_info'] ?? {};

      return ExtractedReportData(
        reportType: data['report_type'] ?? 'General',
        patientInfo: PatientInfo(
          name: patientData['name'] ?? 'Unknown',
          age: patientData['age'] ?? 0,
          gender: patientData['gender'] ?? 'Unknown',
          id: patientData['id'],
        ),
        reportDate: data['date'] ?? '',
        doctorInfo: DoctorInfo(
          name: doctorData['name'] ?? 'Unknown',
          specialty: doctorData['specialty'] ?? 'General',
          hospital: doctorData['hospital'],
        ),
        testResults: (reportData['test_results'] as List?)
            ?.map(
              (t) => TestResult(
                name: t['test_name'] ?? '',
                value: t['value']?.toString() ?? '',
                unit: t['unit'] ?? '',
                normalRange: t['reference_range'] ?? '',
                status: t['flag']?.toLowerCase() ?? 'normal',
              ),
            )
            .toList(),
        // Add other fields mapping as needed based on your backend response
        diagnosis: reportData['diagnosis'],
        observations: reportData['summary'],
      );
    } else {
      throw Exception('Failed to load report: ${response.statusCode}');
    }
  }
}
