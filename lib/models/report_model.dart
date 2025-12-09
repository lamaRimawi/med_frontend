class Report {
  final int reportId;
  final String reportDate;
  final String createdAt;
  final int totalFields;
  final List<ReportField> fields;
  final List<AdditionalField> additionalFields;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String? reportType;

  Report({
    required this.reportId,
    required this.reportDate,
    required this.createdAt,
    required this.totalFields,
    required this.fields,
    required this.additionalFields,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.reportType,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['report_id'] as int,
      reportDate: json['report_date'] as String,
      createdAt: json['created_at'] as String,
      totalFields: json['total_fields'] as int,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => ReportField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      additionalFields: (json['additional_fields'] as List<dynamic>?)
              ?.map((e) => AdditionalField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      patientName: json['patient_name'] as String?,
      patientAge: json.containsKey('patient_age')
          ? int.tryParse(json['patient_age'].toString())
          : null,
      patientGender: json['patient_gender'] as String?,
      reportType: json['report_type'] as String?,
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
  final String createdAt;

  ReportField({
    required this.id,
    required this.fieldName,
    required this.fieldValue,
    this.fieldUnit,
    this.normalRange,
    this.isNormal,
    this.fieldType,
    this.notes,
    required this.createdAt,
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
      createdAt: json['created_at'] as String,
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
