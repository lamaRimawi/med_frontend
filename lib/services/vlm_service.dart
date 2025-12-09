import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/extracted_report_data.dart';
import 'api_client.dart';

class VlmService {
  static Future<ExtractedReportData> extractFromImages(
    List<String> filePaths,
  ) async {
    final client = ApiClient.instance;

    print('VlmService: Uploading ${filePaths.length} files: $filePaths');
    final http.Response res = await client.postMultipartMultiple(
      ApiConfig.vlmChat,
      auth: true,
      filePaths: filePaths,
    );

    print('VlmService: Response status: ${res.statusCode}');
    print('VlmService: Response body: ${res.body}');

    // Handle duplicate report (409 Conflict)
    if (res.statusCode == 409) {
      final msg = _safeErr(res);
      throw Exception('DUPLICATE_REPORT: $msg');
    }
    
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
    
    print('VlmService: Medical data entries (in report): $entries');
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
    print('VlmService: _parseReportData processing ${entries.length} entries: $entries');

    final tests = <TestResult>[];
    for (final e in entries) {
      if (e is Map<String, dynamic>) {
        print('VlmService: Processing entry: $e');
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

    // Parse age and gender from backend response
    int age = 0;
    String gender = 'Unknown';
    
    // Try to get age and gender from separate fields if available
    if (reportData.containsKey('patient_age')) {
      age = int.tryParse(reportData['patient_age'].toString()) ?? 0;
    }
    if (reportData.containsKey('patient_gender')) {
      gender = reportData['patient_gender'].toString();
    }
    
    // Improved logic: Look in entries if not found
    if (age == 0) {
        for (final e in entries) {
            if (e is Map<String, dynamic>) {
                 final name = (e['field_name'] ?? '').toString().toLowerCase();
                 // Check for loose matches
                 if (name == 'age' || name.contains('patient age') || name == 'years') {
                      // Extract number from string like "25 Years"
                      final val = e['field_value'].toString();
                      final match = RegExp(r'(\d+)').firstMatch(val);
                      if (match != null) {
                        age = int.tryParse(match.group(1)!) ?? 0;
                      }
                 }
            }
        }
    }
    if (gender == 'Unknown') {
         for (final e in entries) {
            if (e is Map<String, dynamic>) {
                 final name = (e['field_name'] ?? '').toString().toLowerCase();
                 if (name == 'gender' || name == 'sex' || name.contains('patient gender')) {
                      gender = e['field_value'].toString();
                 }
            }
        }
    }
    
    // If not found, try to extract from patient_name or other fields
    // The backend might include "Female/20 Years" in the response
    if (age == 0 || gender == 'Unknown') {
      // Check if there's a gender_age field
      final genderAge = reportData['gender_age']?.toString() ?? '';
      if (genderAge.isNotEmpty) {
        final parts = genderAge.split('/');
        if (parts.length >= 2) {
          gender = parts[0].trim();
          final ageMatch = RegExp(r'(\d+)').firstMatch(parts[1]);
          if (ageMatch != null) {
            age = int.tryParse(ageMatch.group(1) ?? '0') ?? 0;
          }
        }
      }
    }
    
    print('VlmService: Parsed patient info - Age: $age, Gender: $gender');

    final patientInfo = PatientInfo(
      name: patientName.isEmpty ? 'Unknown' : patientName,
      age: age,
      gender: gender,
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
      debugRawJson: jsonEncode(reportData),
    );
  }

  static Future<void> uploadAndStream(
      String filePath, {
      required Function(String status, double percent) onProgress,
      required Function(ExtractedReportData data) onComplete,
      required Function(String error) onError,
    }) async {
    final client = ApiClient.instance;
    final token = await client.getToken();
    
    if (token == null) {
      onError('Unauthorized: No token found');
      return;
    }

    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.vlmChat}');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();

      streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) {
          if (line.trim().isEmpty) return;

          try {
            print('VlmStream: $line');
            final data = jsonDecode(line);

            if (data['type'] == 'progress') {
              final message = data['message'] as String? ?? 'Processing...';
              final percent = (data['percent'] as num?)?.toDouble() ?? 0.0;
              onProgress(message, percent);
            } else if (data['type'] == 'result') {
              // Parse the final result using existing logic
               // Backend returns data nested under 'report' key or 'data' key based on the snippet
               // The snippet says data['data']['report_id']
               // Let's assume the structure is similar to the non-streaming one or adapt
               
               // Based on user snippet: data['type'] == 'result'
               // We need to inspect `data['data']`
               final resultData = data['data'];
               if (resultData != null) {
                 final report = _parseReportData(resultData);
                 onComplete(report);
               } else {
                 // Fallback if structure is different
                 final report = _parseReportData(data);
                 onComplete(report);
               }
            } else if (data['error'] != null) {
               onError(data['error'].toString());
            }
          } catch (e) {
            print("Error parsing update: $e");
          }
        },
        onError: (error) {
          print("Network Error: $error");
          onError(error.toString());
        },
        onDone: () {
          print("Stream closed.");
        },
      );
    } catch (e) {
      onError(e.toString());
    }
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
