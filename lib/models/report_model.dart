class Report {
  final int reportId;
  final String reportDate;
  final String createdAt;
  final int totalFields;
  final String? reportType;
  final String? reportName;
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

    return Report(
      reportId: json['report_id'] as int,
      reportDate: json['report_date'] as String,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      totalFields: json['total_fields'] as int? ?? fieldsList?.length ?? 0,
      reportType: json['report_type'] as String?,
      reportName: json['report_name'] as String?,
      fields:
          fieldsList
              ?.map((e) => ReportField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      additionalFields:
          (json['additional_fields'] as List<dynamic>?)
              ?.map((e) => AdditionalField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
