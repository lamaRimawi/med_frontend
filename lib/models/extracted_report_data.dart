class ExtractedReportData {
  final String reportType; // 'Lab Results', 'Prescription', 'Imaging', 'Vitals', 'Pathology', 'General'
  final PatientInfo patientInfo;
  final String reportDate;
  final DoctorInfo? doctorInfo;
  final List<TestResult>? testResults;
  final List<VitalSign>? vitals;
  final List<Medication>? medications;
  final String? diagnosis;
  final String? observations;
  final List<String>? recommendations;
  final String? nextVisit;
  final List<String>? warnings;
  final String? debugRawJson;

  ExtractedReportData({
    required this.reportType,
    required this.patientInfo,
    required this.reportDate,
    this.doctorInfo,
    this.testResults,
    this.vitals,
    this.medications,
    this.diagnosis,
    this.observations,
    this.recommendations,
    this.nextVisit,
    this.warnings,
    this.debugRawJson,
  });
}

class PatientInfo {
  final String name;
  final int age;
  final String gender;
  final String? id;
  final String? phone;
  final String? email;

  PatientInfo({
    required this.name,
    required this.age,
    required this.gender,
    this.id,
    this.phone,
    this.email,
  });
}

class DoctorInfo {
  final String name;
  final String specialty;
  final String? hospital;

  DoctorInfo({
    required this.name,
    required this.specialty,
    this.hospital,
  });
}

class TestResult {
  final String name;
  final String value;
  final String unit;
  final String normalRange;
  final String status; // 'normal', 'high', 'low', 'critical'

  TestResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.normalRange,
    required this.status,
  });
}

class VitalSign {
  final String name;
  final String value;
  final String unit;
  final String icon; // 'heart', 'thermometer', 'activity', 'droplet'

  VitalSign({
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
  });
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
  });
}
