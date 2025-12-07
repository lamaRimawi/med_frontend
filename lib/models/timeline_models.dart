class TimelineStats {
  final int totalReports;
  final String? lastCheckup;
  final String healthStatus;

  TimelineStats({
    required this.totalReports,
    this.lastCheckup,
    required this.healthStatus,
  });

  factory TimelineStats.fromJson(Map<String, dynamic> json) {
    return TimelineStats(
      totalReports: json['total_reports'] ?? 0,
      lastCheckup: json['last_checkup'],
      healthStatus: json['health_status'] ?? 'Unknown',
    );
  }
}

class TimelineReport {
  final int reportId;
  final String date;
  final String reportType;
  final String? doctorNames;
  final TimelineSummary summary;

  TimelineReport({
    required this.reportId,
    required this.date,
    required this.reportType,
    this.doctorNames,
    required this.summary,
  });

  factory TimelineReport.fromJson(Map<String, dynamic> json) {
    return TimelineReport(
      reportId: json['report_id'],
      date: json['date'],
      reportType: json['report_type'] ?? 'General Report',
      doctorNames: json['doctor_names'],
      summary: TimelineSummary.fromJson(json['summary']),
    );
  }
}

class TimelineSummary {
  final int totalTests;
  final int abnormalCount;
  final List<String> abnormalFields;

  TimelineSummary({
    required this.totalTests,
    required this.abnormalCount,
    required this.abnormalFields,
  });

  factory TimelineSummary.fromJson(Map<String, dynamic> json) {
    return TimelineSummary(
      totalTests: json['total_tests'] ?? 0,
      abnormalCount: json['abnormal_count'] ?? 0,
      abnormalFields: List<String>.from(json['abnormal_fields'] ?? []),
    );
  }
}

class TrendDataPoint {
  final String date;
  final dynamic value;
  final String rawValue;
  final String? unit;
  final bool isNormal;
  final int reportId;

  TrendDataPoint({
    required this.date,
    required this.value,
    required this.rawValue,
    this.unit,
    required this.isNormal,
    required this.reportId,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: json['date'],
      value: json['value'],
      rawValue: json['raw_value'],
      unit: json['unit'],
      isNormal: json['is_normal'] ?? true,
      reportId: json['report_id'],
    );
  }

  double? get numericValue {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class HealthTrends {
  final Map<String, List<TrendDataPoint>> trends;

  HealthTrends({required this.trends});

  factory HealthTrends.fromJson(Map<String, dynamic> json) {
    final trendsData = json['trends'] as Map<String, dynamic>;
    final Map<String, List<TrendDataPoint>> parsedTrends = {};

    trendsData.forEach((key, value) {
      parsedTrends[key] = (value as List)
          .map((item) => TrendDataPoint.fromJson(item))
          .toList();
    });

    return HealthTrends(trends: parsedTrends);
  }
}
