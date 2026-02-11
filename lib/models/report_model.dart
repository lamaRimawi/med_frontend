class Report {
  final int reportId;
  final String reportDate;
  final String createdAt;
  final int totalFields;
  final String? reportType;
  final String? reportName;
  final String? reportCategory; // New field
  final List<ReportField> fields;
  final List<AdditionalField> additionalFields;
  final String? patientName;
  final int? profileId; // Added for filtering
  final int? patientAge;
  final String? patientGender;

  Report({
    required this.reportId,
    required this.reportDate,
    required this.createdAt,
    required this.totalFields,
    this.reportType,
    this.reportName,
    this.reportCategory,
    required this.fields,
    required this.additionalFields,
    this.patientName,
    this.profileId,
    this.patientAge,
    this.patientGender,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    // Handle both 'fields' and 'medical_data' keys
    final fieldsList =
        (json['fields'] ?? json['medical_data']) as List<dynamic>?;

    // Parse fields first to enable smart date discovery
    final parsedFields = fieldsList
            ?.map((e) => ReportField.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    
    final parsedAdditionalFields = (json['additional_fields'] as List<dynamic>?)
            ?.map((e) => AdditionalField.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Smart date discovery: prioritize extracted "Report Date" fields
    String reportDate = json['report_date'] as String;
    final dateKeywords = [
      'report date', 'test date', 'collection date', 'date of test',
      'investigation date', 'date', 'reported', 'received date',
      'date printed', 'sampling date'
    ];
    final datePattern = RegExp(r'\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}');
    String? bestGuess;

    // Check parsed fields for explicit date
    for (var f in parsedFields) {
      final name = f.fieldName.toLowerCase().replaceAll('_', ' ');
      final value = f.fieldValue.trim();
      if (value.isEmpty || value.toLowerCase() == 'n/a' || value.toLowerCase() == 'null') continue;

      if (dateKeywords.any((k) => name == k || name.contains(k))) {
        reportDate = value.split('T')[0].split(' ')[0];
        break;
      }
      if (bestGuess == null && datePattern.hasMatch(value)) {
        bestGuess = value.split('T')[0].split(' ')[0];
      }
    }

    // Check additional fields if no match found
    if (reportDate == json['report_date'] as String) {
      for (var f in parsedAdditionalFields) {
        final name = f.fieldName.toLowerCase().replaceAll('_', ' ');
        final value = f.fieldValue.trim();
        if (value.isEmpty || value.toLowerCase() == 'n/a' || value.toLowerCase() == 'null') continue;

        if (dateKeywords.any((k) => name == k || name.contains(k))) {
          reportDate = value.split('T')[0].split(' ')[0];
          break;
        }
        if (bestGuess == null && datePattern.hasMatch(value)) {
          bestGuess = value.split('T')[0].split(' ')[0];
        }
      }
    }

    // Use best guess if we still have the original date
    if (reportDate == json['report_date'] as String && bestGuess != null) {
      reportDate = bestGuess;
    }

    return Report(
      reportId: json['report_id'] as int,
      reportDate: reportDate,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      totalFields: json['total_fields'] as int? ?? fieldsList?.length ?? 0,
      reportType: json['report_type'] as String?,
      reportName: json['report_name'] as String?,
      reportCategory: json['report_category'] as String?,
      fields: parsedFields,
      additionalFields: parsedAdditionalFields,
      patientName: json['patient_name'] as String?,
      profileId: json['profile_id'] as int?,
      patientAge: json.containsKey('patient_age')
          ? () {
              final ageStr = json['patient_age'].toString();
              // Try direct parse first
              var age = int.tryParse(ageStr);
              // If that fails, try to extract number from string like "20 Years"
              if (age == null) {
                final match = RegExp(r'(\d+)').firstMatch(ageStr);
                if (match != null) {
                  age = int.tryParse(match.group(1)!);
                }
              }
              return age;
            }()
          : null,
      patientGender: json['patient_gender'] as String?,
    );
  }
}

class ReportField {
  final int id;
  final String fieldName;
  final String fieldValue;
  final String? fieldUnit;
  final String? normalRange;
  final bool? isNormal;
  final String? fieldType;
  final String? notes;
  final String? createdAt;
  final String? category;

  ReportField({
    required this.id,
    required this.fieldName,
    required this.fieldValue,
    this.fieldUnit,
    this.normalRange,
    this.isNormal,
    this.fieldType,
    this.notes,
    this.createdAt,
    this.category,
  });

  factory ReportField.fromJson(Map<String, dynamic> json) {
    return ReportField(
      id: json['id'] as int,
      fieldName: json['field_name'] as String,
      fieldValue: json['field_value'] as String,
      fieldUnit: json['field_unit'] as String?,
      normalRange: json['normal_range'] as String?,
      isNormal: json['is_normal'] as bool?,
      fieldType: json['field_type'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      category: json['category'] as String?,
    );
  }
}

class AdditionalField {
  final int id;
  final String fieldName;
  final String fieldValue;
  final String category;
  final String? mergedAt;

  AdditionalField({
    required this.id,
    required this.fieldName,
    required this.fieldValue,
    required this.category,
    this.mergedAt,
  });

  factory AdditionalField.fromJson(Map<String, dynamic> json) {
    return AdditionalField(
      id: json['id'] as int,
      fieldName: json['field_name'] as String,
      fieldValue: json['field_value'] as String,
      category: json['category'] as String,
      mergedAt: json['merged_at'] as String?,
    );
  }
}
