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
      final rootData = ApiClient.decodeJson<Map<String, dynamic>>(response);
      final data = rootData['report'] as Map<String, dynamic>;
      
      // Map backend response to ExtractedReportData
      // Correcting mapping to match Report.fromJson structure
      
      final fieldsList = (data['fields'] ?? data['medical_data']) as List<dynamic>?;
      final patientName = data['patient_name'] as String? ?? 'Unknown';
      
      // Parse Age
      int? age;
      if (data.containsKey('patient_age')) {
          final ageStr = data['patient_age'].toString();
          age = int.tryParse(ageStr);
          if (age == null) {
            final match = RegExp(r'(\d+)').firstMatch(ageStr);
            if (match != null) {
              age = int.tryParse(match.group(1)!);
            }
          }
      }

      return ExtractedReportData(
        reportType: data['report_type'] ?? 'General',
        patientInfo: PatientInfo(
          name: patientName,
          age: age ?? 0,
          gender: data['patient_gender'] ?? 'Unknown',
          id: null,
        ),
        reportDate: data['report_date'] ?? data['date'] ?? '',
        doctorInfo: DoctorInfo(
          name: 'Unknown', // Not typically in top-level response based on Report model
          specialty: 'General', 
        ),
        testResults: fieldsList
            ?.map(
              (f) => TestResult(
                name: f['field_name'] ?? '',
                value: f['field_value']?.toString() ?? '',
                unit: f['field_unit'] ?? '',
                normalRange: f['normal_range'] ?? '',
                status: (f['is_normal'] == false) ? 'abnormal' : 'normal',
              ),
            )
            .toList(),
        diagnosis: null, // Not in Report model
        observations: null, // Not in Report model
      );
    } else {
      throw Exception('Failed to load report: ${response.statusCode}');
    }
  }
}
