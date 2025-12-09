import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

import '../services/timeline_api.dart';
import '../models/timeline_models.dart';


// Medical Record Model
class MedicalRecord {
  final int id;
  final String date;
  final String time;
  final String fullDate;
  final String title;
  final String type;
  final String category;
  final String facility;
  final String doctor;
  final String status;
  final DateTime timestamp;
  final String notes;
  final List<RecordValue>? values;

  MedicalRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.fullDate,
    required this.title,
    required this.type,
    required this.category,
    required this.facility,
    required this.doctor,
    required this.status,
    required this.timestamp,
    required this.notes,
    this.values,
  });
}

class RecordValue {
  final String label;
  final String value;
  final String unit;
  final String? status;

  RecordValue({
    required this.label,
    required this.value,
    required this.unit,
    this.status,
  });
}

class TimelineScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDarkMode;

  const TimelineScreen({
    super.key,
    required this.onBack,
    required this.isDarkMode,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _selectedView = 'month';
  String _selectedCategory = 'all';
  int? _expandedCard;
  String _searchQuery = '';
  bool _showExportMenu = false;
  
  // Backend data
  List<TimelineReport> _timelineReports = [];
  TimelineStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }
  
  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final timeline = await TimelineApi.getTimeline();
      final stats = await TimelineApi.getStats();
      
      setState(() {
        _timelineReports = timeline;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  String _formatFullDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _getCategoryFromType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('lab') || lower.contains('test') || lower.contains('blood')) return 'lab';
    if (lower.contains('x-ray') || lower.contains('scan') || lower.contains('imaging')) return 'imaging';
    if (lower.contains('prescription') || lower.contains('medication')) return 'prescription';
    return 'other';
  }

  // Convert backend data to UI format
  List<MedicalRecord> get _allRecords {
    if (_isLoading || _timelineReports.isEmpty) return [];
    
    return _timelineReports.map((report) {
      final date = DateTime.parse(report.date);
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      return MedicalRecord(
        id: report.reportId,
        date: '${monthNames[date.month - 1]} ${date.day}',
        time: '',
        fullDate: _formatFullDate(date),
        title: report.reportType,
        type: report.reportType,
        category: _getCategoryFromType(report.reportType),
        facility: '',
        doctor: report.doctorNames ?? '',
        status: report.summary.abnormalCount > 0 ? 'Review Required' : 'Normal',
        timestamp: date,
        notes: report.summary.abnormalCount == 0
            ? 'All ${report.summary.totalTests} test(s) within normal range.'
            : '${report.summary.abnormalCount} abnormal: ${report.summary.abnormalFields.join(", ")}',
        values: null,
      );
    }).toList();
  }

  // Dummy Data (kept for reference, not used)
  final List<MedicalRecord> _dummyRecords = [
    MedicalRecord(
      id: 1,
      date: 'Nov 28',
      time: '10:30 AM',
      fullDate: 'Thursday, November 28, 2025',
      title: 'Complete Blood Count',
      type: 'Lab Test',
      category: 'lab',
      facility: 'Quest Diagnostics',
      doctor: 'Dr. Sarah Johnson',
      status: 'Normal',
      timestamp: DateTime(2025, 11, 28, 10, 30),
      notes: 'All values within normal range. Continue current medication.',
      values: [
        RecordValue(label: 'WBC', value: '7.5', unit: 'K/μL', status: 'normal'),
        RecordValue(label: 'RBC', value: '4.8', unit: 'M/μL', status: 'normal'),
        RecordValue(
          label: 'Hemoglobin',
          value: '14.2',
          unit: 'g/dL',
          status: 'normal',
        ),
        RecordValue(
          label: 'Platelets',
          value: '250',
          unit: 'K/μL',
          status: 'normal',
        ),
      ],
    ),
    MedicalRecord(
      id: 2,
      date: 'Nov 26',
      time: '02:15 PM',
      fullDate: 'Tuesday, November 26, 2025',
      title: 'X-Ray Chest PA & Lateral',
      type: 'Imaging',
      category: 'imaging',
      facility: 'Regional Radiology Center',
      doctor: 'Dr. Michael Chen',
      status: 'Clear',
      timestamp: DateTime(2025, 11, 26, 14, 15),
      notes:
          'No abnormalities detected. Lung fields are clear with no signs of infection or masses.',
    ),
    MedicalRecord(
      id: 3,
      date: 'Nov 25',
      time: '09:00 AM',
      fullDate: 'Monday, November 25, 2025',
      title: 'Lisinopril 10mg',
      type: 'Prescription',
      category: 'prescription',
      facility: 'City Medical Clinic',
      doctor: 'Dr. Emily Rodriguez',
      status: 'Active',
      timestamp: DateTime(2025, 11, 25, 9, 0),
      notes:
          'Take once daily in the morning for blood pressure management. 30 day supply with 2 refills.',
    ),
    MedicalRecord(
      id: 4,
      date: 'Nov 24',
      time: '08:30 AM',
      fullDate: 'Sunday, November 24, 2025',
      title: 'Lipid Panel',
      type: 'Lab Test',
      category: 'lab',
      facility: 'LabCorp',
      doctor: 'Dr. Sarah Johnson',
      status: 'Review Required',
      timestamp: DateTime(2025, 11, 24, 8, 30),
      notes:
          'Total cholesterol slightly elevated. Recommend dietary changes and follow-up in 3 months.',
      values: [
        RecordValue(
          label: 'Total Cholesterol',
          value: '210',
          unit: 'mg/dL',
          status: 'high',
        ),
        RecordValue(label: 'LDL', value: '135', unit: 'mg/dL', status: 'high'),
        RecordValue(label: 'HDL', value: '55', unit: 'mg/dL', status: 'normal'),
        RecordValue(
          label: 'Triglycerides',
          value: '140',
          unit: 'mg/dL',
          status: 'normal',
        ),
      ],
    ),
    MedicalRecord(
      id: 5,
      date: 'Nov 20',
      time: '03:00 PM',
      fullDate: 'Wednesday, November 20, 2025',
      title: 'MRI Brain with Contrast',
      type: 'Imaging',
      category: 'imaging',
      facility: 'Advanced Imaging Center',
      doctor: 'Dr. Michael Chen',
      status: 'Normal',
      timestamp: DateTime(2025, 11, 20, 15, 0),
      notes:
          'All brain structures appear normal. No evidence of lesions, masses, or abnormal enhancement.',
    ),
    MedicalRecord(
      id: 6,
      date: 'Nov 18',
      time: '11:00 AM',
      fullDate: 'Monday, November 18, 2025',
      title: 'Tissue Biopsy Analysis',
      type: 'Pathology',
      category: 'pathology',
      facility: 'City Pathology Lab',
      doctor: 'Dr. James Wilson',
      status: 'Benign',
      timestamp: DateTime(2025, 11, 18, 11, 0),
      notes:
          'Microscopic examination shows benign tissue. No malignant cells detected. No further action required.',
    ),
    MedicalRecord(
      id: 7,
      date: 'Nov 15',
      time: '07:30 AM',
      fullDate: 'Friday, November 15, 2025',
      title: 'Fasting Blood Glucose',
      type: 'Lab Test',
      category: 'lab',
      facility: 'Quest Diagnostics',
      doctor: 'Dr. Sarah Johnson',
      status: 'Normal',
      timestamp: DateTime(2025, 11, 15, 7, 30),
      notes:
          'Fasting glucose within normal range. Continue current management plan.',
      values: [
        RecordValue(
          label: 'Glucose (Fasting)',
          value: '95',
          unit: 'mg/dL',
          status: 'normal',
        ),
        RecordValue(label: 'HbA1c', value: '5.4', unit: '%', status: 'normal'),
      ],
    ),
    MedicalRecord(
      id: 8,
      date: 'Nov 12',
      time: '10:00 AM',
      fullDate: 'Tuesday, November 12, 2025',
      title: 'Metformin 500mg',
      type: 'Prescription',
      category: 'prescription',
      facility: 'City Medical Clinic',
      doctor: 'Dr. Emily Rodriguez',
      status: 'Active',
      timestamp: DateTime(2025, 11, 12, 10, 0),
      notes:
          'Take twice daily with meals for blood sugar management. 90 day supply with 3 refills available.',
    ),
    MedicalRecord(
      id: 9,
      date: 'Nov 08',
      time: '01:45 PM',
      fullDate: 'Friday, November 8, 2025',
      title: 'Thyroid Function Test',
      type: 'Lab Test',
      category: 'lab',
      facility: 'LabCorp',
      doctor: 'Dr. Sarah Johnson',
      status: 'Normal',
      timestamp: DateTime(2025, 11, 8, 13, 45),
      notes:
          'TSH and T4 levels are within normal range. No thyroid dysfunction detected.',
      values: [
        RecordValue(
          label: 'TSH',
          value: '2.1',
          unit: 'mIU/L',
          status: 'normal',
        ),
        RecordValue(
          label: 'Free T4',
          value: '1.3',
          unit: 'ng/dL',
          status: 'normal',
        ),
      ],
    ),
    MedicalRecord(
      id: 10,
      date: 'Nov 05',
      time: '11:30 AM',
      fullDate: 'Tuesday, November 5, 2025',
      title: 'Ultrasound Abdomen',
      type: 'Imaging',
      category: 'imaging',
      facility: 'Regional Radiology Center',
      doctor: 'Dr. Michael Chen',
      status: 'Normal',
      timestamp: DateTime(2025, 11, 5, 11, 30),
      notes:
          'Abdominal organs appear normal in size and structure. No masses or abnormalities detected.',
    ),
  ];

  List<MedicalRecord> get _filteredRecords {
    final now = DateTime(2025, 11, 30); // Mock current date as per React code

    // Filter by time period
    var records = _allRecords.where((r) {
      final daysDiff = now.difference(r.timestamp).inDays;
      switch (_selectedView) {
        case 'week':
          return daysDiff <= 7;
        case 'month':
          return daysDiff <= 30;
        case 'year':
          return daysDiff <= 365;
        default:
          return true;
      }
    }).toList();

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      records = records
          .where(
            (r) =>
                r.title.toLowerCase().contains(query) ||
                r.type.toLowerCase().contains(query) ||
                r.facility.toLowerCase().contains(query) ||
                r.doctor.toLowerCase().contains(query) ||
                r.notes.toLowerCase().contains(query) ||
                r.status.toLowerCase().contains(query),
          )
          .toList();
    }

    // Filter by category
    if (_selectedCategory != 'all') {
      records = records.where((r) => r.category == _selectedCategory).toList();
    }

    // Sort by timestamp descending
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  Map<String, int> get _categoryCounts {
    final searchFiltered = _allRecords.where((r) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return r.title.toLowerCase().contains(query) ||
          r.type.toLowerCase().contains(query) ||
          r.facility.toLowerCase().contains(query) ||
          r.doctor.toLowerCase().contains(query) ||
          r.notes.toLowerCase().contains(query) ||
          r.status.toLowerCase().contains(query);
    }).toList();

    return {
      'all': searchFiltered.length,
      'lab': searchFiltered.where((r) => r.category == 'lab').length,
      'prescription': searchFiltered
          .where((r) => r.category == 'prescription')
          .length,
      'imaging': searchFiltered.where((r) => r.category == 'imaging').length,
      'pathology': searchFiltered
          .where((r) => r.category == 'pathology')
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (!isDark)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF9FAFB), Color(0xFFEFF6FF)],
                ),
              ),
            ),

          Column(
            children: [
              // Header
              _buildHeader(isDark, textColor, subTextColor, borderColor),

              // Search Bar
              _buildSearchBar(isDark, borderColor),

              // Category Pills
              _buildCategoryPills(isDark, borderColor),

              // Timeline Content
              Expanded(
                child: _buildTimelineContent(
                  isDark,
                  textColor,
                  subTextColor,
                  borderColor,
                ),
              ),
            ],
          ),

          // Export Menu Overlay
          if (_showExportMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showExportMenu = false),
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 100, // Adjust based on header height
                        right: 16,
                        child: _buildExportMenu(isDark, borderColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color textColor,
    Color? subTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1D26).withOpacity(0.95)
            : Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.activity,
                                    color: Color(0xFF39A4E6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Medical Timeline',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_filteredRecords.length} ${_filteredRecords.length == 1 ? 'record' : 'records'}',
                                style: TextStyle(
                                    fontSize: 12, color: subTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showExportMenu = !_showExportMenu),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]!.withOpacity(0.8)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.download,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // View Selector (Desktop style but adapted for mobile)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withOpacity(0.8)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ['week', 'month', 'year'].map((view) {
                    final isSelected = _selectedView == view;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedView = view;
                          _expandedCard = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF39A4E6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF39A4E6),
                                      Color(0xFF2B8DD4),
                                    ],
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF39A4E6,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            view,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : subTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1D26).withOpacity(0.5)
            : Colors.white.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withOpacity(0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: _searchQuery.isNotEmpty
                  ? Border.all(
                      color: const Color(0xFF39A4E6).withOpacity(0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _expandedCard = null;
                    }),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search records, doctors, facilities...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _searchQuery = '';
                      _expandedCard = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills(bool isDark, Color borderColor) {
    final categories = [
      {'id': 'all', 'label': 'All', 'icon': LucideIcons.fileText},
      {'id': 'lab', 'label': 'Lab', 'icon': LucideIcons.droplet},
      {'id': 'prescription', 'label': 'Rx', 'icon': LucideIcons.pill},
      {'id': 'imaging', 'label': 'Imaging', 'icon': LucideIcons.scan},
      {'id': 'pathology', 'label': 'Path', 'icon': LucideIcons.microscope},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1D26).withOpacity(0.5)
            : Colors.white.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) {
            final id = cat['id'] as String;
            final label = cat['label'] as String;
            final icon = cat['icon'] as IconData;
            final isActive = _selectedCategory == id;
            final count = _categoryCounts[id] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = id;
                  _expandedCard = null;
                }),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF39A4E6)
                        : isDark
                        ? Colors.grey[800]!.withOpacity(0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isActive ? null : Border.all(color: borderColor),
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF39A4E6), Color(0xFF2B8DD4)],
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF39A4E6).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isActive
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.2)
                              : (isDark ? Colors.grey[700] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? Colors.white
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimelineContent(
    bool isDark,
    Color textColor,
    Color? subTextColor,
    Color borderColor,
  ) {
    final records = _filteredRecords;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? LucideIcons.search
                    : LucideIcons.calendar,
                size: 40,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'Try selecting a different time period or category',
              style: TextStyle(fontSize: 14, color: subTextColor),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _searchQuery = ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8DD4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF39A4E6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Clear Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Timeline Line
        Positioned(
          left: 39,
          top: 0,
          bottom: 0,
          width: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
                    : [Colors.grey[200]!, Colors.blue[200]!, Colors.grey[200]!],
              ),
            ),
          ),
        ),

        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final config = _getCategoryConfig(record.category);
            final statusInfo = _getStatusInfo(record.status);
            final isExpanded = _expandedCard == record.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Dot
                  SizedBox(
                    width: 48,
                    child: Center(
                      child:
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: config['gradient'] as List<Color>,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (config['color'] as Color).withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Icon(
                              config['icon'] as IconData,
                              color: Colors.white,
                              size: 24,
                            ),
                          ).animate().scale(
                            duration: 300.ms,
                            delay: (index * 50).ms,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _expandedCard = isExpanded ? null : record.id,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1D26)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (statusInfo['bg'] as Color)
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    statusInfo['icon']
                                                        as String,
                                                    style: TextStyle(
                                                      color:
                                                          statusInfo['text']
                                                              as Color,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    record.status,
                                                    style: TextStyle(
                                                      color:
                                                          statusInfo['text']
                                                              as Color,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              LucideIcons.clock,
                                              size: 12,
                                              color: subTextColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              record.time,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: subTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          record.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.calendar,
                                              size: 12,
                                              color: subTextColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              record.date,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                              child: Text(
                                                '•',
                                                style: TextStyle(
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              record.type,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                        LucideIcons.chevronDown,
                                        color: subTextColor,
                                        size: 20,
                                      )
                                      .animate(target: isExpanded ? 1 : 0)
                                      .rotate(begin: 0, end: 0.5),
                                ],
                              ),

                              // Quick Info
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]!.withOpacity(0.3)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.mapPin,
                                            size: 14,
                                            color: subTextColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Facility',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: subTextColor,
                                                  ),
                                                ),
                                                Text(
                                                  record.facility,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.activity,
                                            size: 14,
                                            color: subTextColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Doctor',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: subTextColor,
                                                  ),
                                                ),
                                                Text(
                                                  record.doctor,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Expanded Content
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                child: isExpanded
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),

                                          // Test Results
                                          if (record.values != null &&
                                              record.values!.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.grey[800]!
                                                          .withOpacity(0.3)
                                                    : const Color(
                                                        0xFFEFF6FF,
                                                      ).withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Test Results',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: subTextColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  GridView.count(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    crossAxisCount: 2,
                                                    mainAxisSpacing: 8,
                                                    crossAxisSpacing: 8,
                                                    childAspectRatio: 2.5,
                                                    children: record.values!.map((
                                                      val,
                                                    ) {
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? Colors
                                                                    .grey[800]!
                                                                    .withOpacity(
                                                                      0.5,
                                                                    )
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          alignment: Alignment.centerLeft,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                val.label,
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  color:
                                                                      subTextColor,
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Text(
                                                                    val.value,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          textColor,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 2,
                                                                  ),
                                                                  Text(
                                                                    val.unit,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          9,
                                                                      color:
                                                                          subTextColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              if (val.status !=
                                                                  null)
                                                                Text(
                                                                  val.status ==
                                                                          'normal'
                                                                      ? '✓ Normal'
                                                                      : (val.status ==
                                                                                'high'
                                                                            ? '↑ High'
                                                                            : '↓ Low'),
                                                                  style: TextStyle(
                                                                    fontSize: 9,
                                                                    color:
                                                                        val.status ==
                                                                            'normal'
                                                                        ? Colors
                                                                              .green
                                                                        : (val.status ==
                                                                                  'high'
                                                                              ? Colors.orange
                                                                              : Colors.red),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],

                                          // Notes
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.grey[800]!
                                                        .withOpacity(0.3)
                                                  : Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Clinical Notes',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: subTextColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  record.notes,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.grey[300]
                                                        : Colors.grey[700],
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // Actions
                                          Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {}, // Placeholder
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFF39A4E6),
                                                              Color(0xFF2B8DD4),
                                                            ],
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFF39A4E6,
                                                          ).withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          LucideIcons.eye,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'View Full Report',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                onTap: () {}, // Placeholder
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.grey[800]
                                                        : Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    LucideIcons.share2,
                                                    size: 16,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1);
          },
        ),
      ],
    );
  }

  Widget _buildExportMenu(bool isDark, Color borderColor) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Export ${_filteredRecords.length} ${_filteredRecords.length == 1 ? 'record' : 'records'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ),
          _buildExportItem(
            isDark,
            'PDF Document',
            'Printable format',
            LucideIcons.fileText,
            Colors.red,
          ),
          _buildExportItem(
            isDark,
            'CSV Spreadsheet',
            'Excel compatible',
            LucideIcons.fileText,
            Colors.green,
          ),
          _buildExportItem(
            isDark,
            'JSON Data',
            'Complete data export',
            LucideIcons.fileText,
            Colors.blue,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().scale(duration: 200.ms, alignment: Alignment.topRight);
  }

  Widget _buildExportItem(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => setState(() => _showExportMenu = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryConfig(String category) {
    switch (category) {
      case 'lab':
        return {
          'icon': LucideIcons.droplet,
          'color': const Color(0xFF39A4E6),
          'gradient': [Colors.blue, Colors.cyan],
        };
      case 'prescription':
        return {
          'icon': LucideIcons.pill,
          'color': const Color(0xFF8B5CF6),
          'gradient': [Colors.purple, Colors.pink],
        };
      case 'imaging':
        return {
          'icon': LucideIcons.scan,
          'color': const Color(0xFFF59E0B),
          'gradient': [Colors.orange, Colors.amber],
        };
      case 'pathology':
        return {
          'icon': LucideIcons.microscope,
          'color': const Color(0xFF10B981),
          'gradient': [Colors.green, Colors.teal],
        };
      default:
        return {
          'icon': LucideIcons.fileText,
          'color': Colors.grey,
          'gradient': [Colors.grey, Colors.blueGrey],
        };
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Normal':
      case 'Clear':
      case 'Benign':
        return {'bg': Colors.green, 'text': Colors.green, 'icon': '✓'};
      case 'Active':
        return {'bg': Colors.purple, 'text': Colors.purple, 'icon': '●'};
      case 'Review Required':
        return {'bg': Colors.orange, 'text': Colors.orange, 'icon': '!'};
      default:
        return {'bg': Colors.grey, 'text': Colors.grey, 'icon': '•'};
    }
  }
}
