import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/extracted_report_data.dart';
import 'api_client.dart';

class VlmService {
  static Future<ExtractedReportData> extractFromImageUrl(
    String imageUrl,
  ) async {
    final client = ApiClient.instance;

    final http.Response res = await client.post(
      ApiConfig.vlmChat,
      auth: true,
      body: json.encode({'image_url': imageUrl}),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _safeErr(res);
      throw Exception('Backend error ${res.statusCode}: $msg');
    }

    final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
    // Expected response keys
    final String patientName = (data['patient_name'] ?? '') as String;
    final String reportType =
        (data['report_type'] ?? 'General Medical Report') as String;
    final String reportDate = (data['report_date'] ?? '') as String;
    final String doctorNames = (data['doctor_names'] ?? '') as String;

    final List<dynamic> entries = (data['medical_data'] ?? []) as List<dynamic>;

    final tests = <TestResult>[];
    for (final e in entries) {
      if (e is Map<String, dynamic>) {
        final name = (e['field_name'] ?? '') as String;
        final value = (e['field_value'] ?? '') as String;
        final unit = (e['field_unit'] ?? '') as String;
        final range = (e['normal_range'] ?? '') as String;
        final isNormal = (e['is_normal'] ?? true) as bool;
        tests.add(
          TestResult(
            name: name,
            value: value,
            unit: unit,
            normalRange: range,
            status: isNormal ? 'normal' : 'abnormal',
          ),
        );
      }
    }

    final doctorInfo = doctorNames.trim().isEmpty
        ? null
        : DoctorInfo(name: doctorNames, specialty: 'Referring Physician');

    // We don't have age/gender in response; fill placeholders
    final patientInfo = PatientInfo(
      name: patientName.isEmpty ? 'Unknown' : patientName,
      age: 0,
      gender: 'Unknown',
    );

    return ExtractedReportData(
      reportType: reportType,
      patientInfo: patientInfo,
      reportDate: reportDate.isEmpty
          ? DateTime.now().toLocal().toString().split(' ').first
          : reportDate,
      doctorInfo: doctorInfo,
      testResults: tests.isEmpty ? null : tests,
      vitals: null,
      medications: null,
      diagnosis: null,
      observations: null,
      recommendations: null,
      nextVisit: null,
      warnings: null,
    );
  }

  static String _safeErr(http.Response res) {
    try {
      final m = ApiClient.decodeJson<Map<String, dynamic>>(res);
      return m['message']?.toString() ?? res.body;
    } catch (_) {
      return res.body;
    }
  }
}
