import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/extracted_report_data.dart';
import 'api_client.dart';

class VlmService {
  static Future<ExtractedReportData> extractFromImageFile(
    String filePath,
  ) async {
    final client = ApiClient.instance;

    print('VlmService: Uploading file: $filePath');
    final http.Response res = await client.postMultipart(
      ApiConfig.vlmChat,
      auth: true,
      filePath: filePath,
    );

    print('VlmService: Response status: ${res.statusCode}');
    print('VlmService: Response body: ${res.body}');

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _safeErr(res);
      throw Exception('Backend error ${res.statusCode}: $msg');
    }

    final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
    
    // Backend returns data nested under 'report' key
    final reportData = data['report'] as Map<String, dynamic>? ?? data;
    
    print('VlmService: Parsing report data...');
    print('VlmService: Report data keys: ${reportData.keys}');
    
    // Expected response keys from the 'report' object
    final String patientName = (reportData['patient_name'] ?? '') as String;
    final String reportType =
        (reportData['report_type'] ?? 'General Medical Report') as String;
    final String reportDate = (reportData['report_date'] ?? '') as String;
    final String doctorNames = (reportData['doctor_names'] ?? '') as String;

    final List<dynamic> entries = (reportData['medical_data'] ?? []) as List<dynamic>;
    
    print('VlmService: Medical data entries count: ${entries.length}');
    
    // WORKAROUND: If medical_data is empty but we have a report_id, fetch the full report
    if (entries.isEmpty && reportData['report_id'] != null) {
      final reportId = reportData['report_id'] as int;
      print('VlmService: medical_data is empty, fetching full report #$reportId...');
      
      try {
        final detailRes = await client.get(
          '${ApiConfig.reports}/$reportId',
          auth: true,
        );
        
        if (detailRes.statusCode == 200) {
          final detailData = ApiClient.decodeJson<Map<String, dynamic>>(detailRes);
          final fullReport = detailData['report'] as Map<String, dynamic>? ?? detailData;
          final fullEntries = (fullReport['medical_data'] ?? []) as List<dynamic>;
          print('VlmService: Fetched ${fullEntries.length} entries from report details');
          
          // Use the full data if available
          if (fullEntries.isNotEmpty) {
            return _parseReportData(fullReport);
          }
        }
      } catch (e) {
        print('VlmService: Failed to fetch full report: $e');
      }
    }
    
    return _parseReportData(reportData);
  }
  
  static ExtractedReportData _parseReportData(Map<String, dynamic> reportData) {
    final String patientName = (reportData['patient_name'] ?? '') as String;
    final String reportType =
        (reportData['report_type'] ?? 'General Medical Report') as String;
    final String reportDate = (reportData['report_date'] ?? '') as String;
    final String doctorNames = (reportData['doctor_names'] ?? '') as String;

    final List<dynamic> entries = (reportData['medical_data'] ?? []) as List<dynamic>;

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
    
    print('VlmService: Parsed ${tests.length} test results');

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
