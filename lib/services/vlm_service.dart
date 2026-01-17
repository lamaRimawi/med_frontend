import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/extracted_report_data.dart';
import 'api_client.dart';

class VlmService {
  static Future<ExtractedReportData> extractFromImages(
    List<String> filePaths, {
    int? profileId,
  }) async {
    final client = ApiClient.instance;

    print('VlmService: Uploading ${filePaths.length} files: $filePaths for profile: $profileId');
    final http.Response res = await client.postMultipartMultiple(
      ApiConfig.vlmChat,
      auth: true,
      filePaths: filePaths,
      fields: profileId != null ? {'profile_id': profileId.toString()} : null,
    );

    print('VlmService: Response status: ${res.statusCode}');
    print('VlmService: Response body: ${res.body}');

    // Handle specialized errors (403 Permission / 409 Duplicate)
    if (res.statusCode == 403 || res.statusCode == 409) {
      try {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(res);
        final code = data['code'];
        final reportId = data['report_id'] ?? data['existing_report_id'];
        final msg = data['error'] ?? data['message'] ?? _safeErr(res);
        
        if (code == 'ACCESS_DENIED') {
          throw Exception('ACCESS_DENIED: $msg');
        }
        if (code == 'DUPLICATE_FILE' || res.statusCode == 409) {
          throw Exception('DUPLICATE_REPORT: $msg (report_id: $reportId)');
        }
      } catch (e) {
        if (e.toString().contains('ACCESS_DENIED') || e.toString().contains('DUPLICATE_REPORT')) rethrow;
      }
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
    String patientName = (reportData['patient_name'] ?? '') as String;
    String reportType =
        (reportData['report_type'] ?? 'General Medical Report') as String;
    // Prefer report_name if available as it is usually more specific
    String? explicitReportName;
    if (reportData['report_name'] != null && reportData['report_name'].toString().isNotEmpty) {
      explicitReportName = reportData['report_name'].toString();
      reportType = explicitReportName;
    }
    final String reportDate = (reportData['report_date'] ?? '') as String;
    final String doctorNames = (reportData['doctor_names'] ?? '') as String;

    print('VlmService: _parseReportData keys: ${reportData.keys}');
    
    // Support multiple keys for the data list
    List<dynamic> entries = [];
    if (reportData['medical_data'] != null) {
      entries = (reportData['medical_data'] as List<dynamic>);
    } else if (reportData['fields'] != null) {
      entries = (reportData['fields'] as List<dynamic>);
    } else if (reportData['results'] != null) {
      entries = (reportData['results'] as List<dynamic>);
    } else if (reportData['tests'] != null) {
      entries = (reportData['tests'] as List<dynamic>);
    } else if (reportData['data'] != null && reportData['data'] is List) {
      entries = (reportData['data'] as List<dynamic>);
    } else if (reportData.containsKey('0')) {
       // Handle case where it might be an indexed map (rare but possible in some phps)
       // entries = reportData.values.toList();
    }
    
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
        final category = (e['category'] ?? 'General Results') as String;
        tests.add(
          TestResult(
            name: name,
            value: value,
            unit: unit,
            normalRange: range,
            status: isNormal ? 'normal' : 'abnormal',
            category: category,
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
      final ageStr = reportData['patient_age'].toString();
      // Try direct parse first
      age = int.tryParse(ageStr) ?? 0;
      // If that fails, try to extract number from string like "20 Years"
      if (age == 0) {
        final match = RegExp(r'(\d+)').firstMatch(ageStr);
        if (match != null) {
          age = int.tryParse(match.group(1)!) ?? 0;
        }
      }
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

    // EXTRACTION OVERRIDES: Check entries for better patient name
    // The top-level patient_name might be the user's name if the AI failed to extract it.
    // We trust explicit fields in the data more.
    if (patientName.isEmpty || patientName == 'Unknown') {
       for (final e in entries) {
          if (e is Map<String, dynamic>) {
               final name = (e['field_name'] ?? '').toString().toLowerCase();
               if (name == 'patient name' || name == 'patient' || name == 'name') {
                    final val = e['field_value']?.toString() ?? '';
                    if (val.isNotEmpty && val.toLowerCase() != 'unknown') {
                       patientName = val;
                    }
               }
          }
       }
    }
    
    // FORMAT REPORT TYPE
    // Only format if we didn't get an explicit report name from the backend
    if (explicitReportName == null) {
      if (reportType.toLowerCase() == 'cbc') {
        reportType = 'Complete Blood Count';
      } else {
        // Title Case the report type
        try {
          if (reportType.trim().isNotEmpty) {
            reportType = reportType.trim().split(' ').map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            }).join(' ');
          }
        } catch (_) {} // Fallback to original if anything fails
      }
    }
    
    print('VlmService: Parsed patient info - Name: $patientName, Age: $age, Gender: $gender');

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
      int? profileId,
      bool allowDuplicate = false,
    }) async {
    await extractFromImagesStreamed(
      [filePath],
      onProgress: onProgress,
      onComplete: onComplete,
      onError: onError,
      profileId: profileId,
      allowDuplicate: allowDuplicate,
    );
  }

  static Future<void> extractFromImagesStreamed(
      List<String> filePaths, {
      required Function(String status, double percent) onProgress,
      required Function(ExtractedReportData data) onComplete,
      required Function(String error) onError,
      int? profileId,
      bool allowDuplicate = false,
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

      for (var path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('file', path));
      }
      
      if (profileId != null) {
        request.fields['profile_id'] = profileId.toString();
      }
      if (allowDuplicate) {
        request.fields['allow_duplicate'] = 'true';
      }
      
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();

      // Check for immediate errors (403 Forbidden / 409 Conflict)
      if (streamedResponse.statusCode != 200 && streamedResponse.statusCode != 201) {
        final body = await streamedResponse.stream.bytesToString();
        try {
          final data = jsonDecode(body);
          final code = data['code'];
          final msg = data['error'] ?? data['message'] ?? body;
          final reportId = data['report_id'] ?? data['existing_report_id'];
          
          if (code == 'ACCESS_DENIED') {
            onError('ACCESS_DENIED: $msg');
          } else if (code == 'DUPLICATE_FILE' || streamedResponse.statusCode == 409) {
            onError('DUPLICATE_REPORT: $msg (report_id: $reportId)');
          } else {
            onError('Backend Error ${streamedResponse.statusCode}: $msg');
          }
        } catch (e) {
          onError('Backend ${streamedResponse.statusCode}: $body');
        }
        return;
      }

      bool wasCompleted = false;

      streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) async {
          if (line.trim().isEmpty) return;
          if (wasCompleted) return;

          try {
            debugPrint('VlmStream: $line');
            
            // Handle SSE format: strip "data: " prefix if present
            String jsonStr = line;
            if (line.startsWith('data: ')) {
              jsonStr = line.substring(6); // Remove "data: " prefix
            }
            
            final data = jsonDecode(jsonStr);

            // Handle progress updates (with or without 'type' field)
            if (data['type'] == 'progress' || data.containsKey('percent')) {
              final message = data['message'] as String? ?? 'Processing...';
              final percent = (data['percent'] as num?)?.toDouble() ?? 0.0;
              onProgress(message, percent);
              
              // Check if this is the final completion message
              if (percent >= 100 && data.containsKey('report_id')) {
                debugPrint('VlmStream: Completion detected with report_id: ${data['report_id']}');
                wasCompleted = true;
                // Fetch the full report using the report_id
                try {
                  final reportId = data['report_id'] as int;
                  debugPrint('VlmStream: Fetching full report details for ID: $reportId');
                  
                  final client = ApiClient.instance;
                  final detailRes = await client.get(
                    '${ApiConfig.reports}/$reportId',
                    auth: true,
                  );
                  
                  debugPrint('VlmStream: Fetch status: ${detailRes.statusCode}');
                  
                  if (detailRes.statusCode == 200) {
                    final detailData = ApiClient.decodeJson<Map<String, dynamic>>(detailRes);
                    // Handle wrapped response { "report": { ... } } or flat { ... }
                    final fullReport = detailData['report'] as Map<String, dynamic>? ?? detailData;
                    
                    debugPrint('VlmStream: Report keys: ${fullReport.keys.toList()}');
                    
                    // Parsing with fallbacks
                    final report = _parseReportData(fullReport);
                    onComplete(report);
                  } else {
                    onError('Failed to fetch report details: ${detailRes.statusCode}');
                  }
                } catch (e) {
                  debugPrint('Error fetching report: $e');
                  onError('Failed to load report: $e');
                }
              }
            } else if (data['type'] == 'result') {
               wasCompleted = true;
               final resultData = data['data'];
               if (resultData != null) {
                 final report = _parseReportData(resultData);
                 onComplete(report);
               } else {
                 final report = _parseReportData(data);
                 onComplete(report);
               }
            } else if (data['error'] != null) {
               if (!wasCompleted) {
                 onError(data['error'].toString());
               }
            }
          } catch (e) {
            debugPrint('Error parsing update: $e');
          }
        },
        onError: (error) {
          debugPrint('Network Error: $error');
          if (!wasCompleted) onError(error.toString());
        },
        onDone: () {
          debugPrint('Stream closed.');
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
