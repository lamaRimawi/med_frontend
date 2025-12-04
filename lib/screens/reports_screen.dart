import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../widgets/theme_toggle.dart';

class Report {
  final String id;
  final String type;
  final String date;
  final String doctor;
  final String hospital;
  final String status;
  final String? fileUrl;

  Report({
    required this.id,
    required this.type,
    required this.date,
    required this.doctor,
    required this.hospital,
    required this.status,
    this.fileUrl,
  });
}

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ReportsScreen({super.key, this.onBack});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Report> _reports = [
    Report(
      id: "1",
      type: "Laboratory",
      date: "18 Nov 2025",
      doctor: "Dr. Sarah Wilson",
      hospital: "City Medical Center",
      status: "completed",
    ),
    Report(
      id: "2",
      type: "Radiology",
      date: "15 Nov 2025",
      doctor: "Dr. Michael Chen",
      hospital: "General Hospital",
      status: "completed",
    ),
    Report(
      id: "3",
      type: "Cardiology",
      date: "10 Nov 2025",
      doctor: "Dr. James Brown",
      hospital: "Heart Care Clinic",
      status: "completed",
    ),
    Report(
      id: "4",
      type: "Radiology",
      date: "05 Nov 2025",
      doctor: "Dr. Emily Davis",
      hospital: "Advanced Imaging Center",
      status: "pending",
    ),
  ];

  bool _showAddForm = false;
  String _searchQuery = "";
  String _filterType = "all";
  bool _showFilters = false;

  final _typeController =
      TextEditingController(); // We'll use a dropdown but keep this for value
  final _dateController = TextEditingController();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();

  Map<String, String> _validationErrors = {
    'type': '',
    'date': '',
    'doctor': '',
    'hospital': '',
  };

  bool get _isDarkMode =>
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

  final List<String> _reportTypes = [
    "Laboratory",
    "Radiology",
    "Cardiology",
    "Pathology",
    "Blood Test",
    "Urine Test",
    "CT Scan",
    "MRI",
    "Ultrasound",
    "Other",
  ];

  @override
  void dispose() {
    _typeController.dispose();
    _dateController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  bool _validateReport() {
    final errors = {'type': '', 'date': '', 'doctor': '', 'hospital': ''};
    bool isValid = true;

    if (_typeController.text.isEmpty) {
      errors['type'] = "Report type is required";
      isValid = false;
    }

    if (_dateController.text.isEmpty) {
      errors['date'] = "Date is required";
      isValid = false;
    }

    if (_doctorController.text.trim().isEmpty) {
      errors['doctor'] = "Doctor name is required";
      isValid = false;
    } else if (_doctorController.text.trim().length < 3) {
      errors['doctor'] = "Doctor name must be at least 3 characters";
      isValid = false;
    }

    if (_hospitalController.text.trim().isEmpty) {
      errors['hospital'] = "Hospital/Clinic name is required";
      isValid = false;
    } else if (_hospitalController.text.trim().length < 3) {
      errors['hospital'] = "Hospital name must be at least 3 characters";
      isValid = false;
    }

    setState(() {
      _validationErrors = errors;
    });
    return isValid;
  }

  void _handleAddReport() {
    if (_validateReport()) {
      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _typeController.text,
        date: _dateController.text, // In a real app, format this date
        doctor: _doctorController.text.trim(),
        hospital: _hospitalController.text.trim(),
        status: "pending",
      );

      setState(() {
        _reports.insert(0, report);
        _resetForm();
      });
    }
  }

  void _handleDeleteReport(String id) {
    setState(() {
      _reports.removeWhere((report) => report.id == id);
    });
  }

  void _handleViewReport(Report report) {
    // Show a dialog or navigate to report details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${report.type}'),
            Text('Date: ${report.date}'),
            Text('Doctor: ${report.doctor}'),
            Text('Hospital: ${report.hospital}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleShareReport(Report report) {
    // Show a toast message indicating share action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${report.type} report...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDownloadReport(Report report) {
    // Show a toast message indicating download action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${report.type} report...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _typeController.clear();
      _dateController.clear();
      _doctorController.clear();
      _hospitalController.clear();
      _validationErrors = {
        'type': '',
        'date': '',
        'doctor': '',
        'hospital': '',
      };
      _showAddForm = false;
    });
  }

  List<Report> get _filteredReports {
    return _reports.where((report) {
      final matchesSearch =
          report.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.doctor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.hospital.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filterType == "all" || report.type == _filterType;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                      ]
                    : [
                        const Color(0xFFEFF6FF),
                        Colors.white,
                        const Color(0xFFEFF6FF),
                      ],
              ),
            ),
          ),

          // Animated Background Elements
          const _AnimatedBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Reports List
                Expanded(child: _buildReportsList()),
              ],
            ),
          ),

          // Add Report Modal
          if (_showAddForm) _buildAddReportModal(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = _isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.9)
            : Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey[100]!,
          ),
        ),
      ),
      child: ClipRRect(
        // For backdrop blur if supported, or just container
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Medical Reports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF475569)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.search,
                            size: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search reports...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _showFilters || _filterType != 'all'
                            ? const Color(0xFF39A4E6)
                            : isDark
                            ? const Color(0xFF334155)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showFilters || _filterType != 'all'
                              ? const Color(0xFF39A4E6)
                              : isDark
                              ? const Color(0xFF475569)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.filter,
                            size: 18,
                            color: _showFilters || _filterType != 'all'
                                ? Colors.white
                                : isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _showFilters || _filterType != 'all'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Filter Options
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _showFilters
                    ? Container(
                        margin: const EdgeInsets.only(top: 16),
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip('All', 'all'),
                            ..._reportTypes.map(
                              (type) => _buildFilterChip(type, type),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF39A4E6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    final reports = _filteredReports;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        if (reports.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(LucideIcons.fileText, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No reports found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...reports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            return _buildReportCard(report, index);
          }),
      ],
    );
  }

  Widget _buildReportCard(Report report, int index) {
    final isDark = _isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A5F)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.date,
                          style: const TextStyle(
                            color: Color(0xFF39A4E6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildIconOnlyButton(
                  LucideIcons.trash2,
                  () => _handleDeleteReport(report.id),
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(LucideIcons.stethoscope, report.doctor),
            const SizedBox(height: 8),
            _buildInfoRow(LucideIcons.clipboard, report.hospital),

            const SizedBox(height: 16),
            Row(
              children: [
                _buildTextButton(LucideIcons.eye, 'View', () => _handleViewReport(report)),
                const SizedBox(width: 12),
                _buildTextButton(LucideIcons.share2, 'Share', () => _handleShareReport(report)),
                const SizedBox(width: 12),
                _buildIconOnlyButton(LucideIcons.download, () => _handleDownloadReport(report)),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final isDark = _isDarkMode;
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final isDark = _isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton(
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final isDark = _isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDark ? const Color(0xFF450A0A) : Colors.red[50])
              : (isDark ? const Color(0xFF334155) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDestructive
              ? (isDark ? Colors.red[300] : Colors.red[600])
              : (isDark ? Colors.grey[300] : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildAddReportModal() {
    final isDark = _isDarkMode;
    return Stack(
      children: [
        GestureDetector(
          onTap: _resetForm,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Medical Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF39A4E6),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                        onPressed: _resetForm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDropdownField('Report Type *', _typeController, 'type'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Report Date *',
                    _dateController,
                    'YYYY-MM-DD',
                    'date',
                    isDate: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Doctor Name *',
                    _doctorController,
                    'e.g., Dr. Sarah Wilson',
                    'doctor',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Hospital/Clinic *',
                    _hospitalController,
                    'e.g., City Medical Center',
                    'hospital',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFDBEAFE),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Note: ',
                            style: TextStyle(
                              color: const Color(0xFF39A4E6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text:
                                'You can upload the actual report file after saving this information.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[300]
                                  : const Color(0xFF4B5563),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _resetForm,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : Colors.grey[200]!,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleAddReport,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF39A4E6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Add Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    String errorKey, {
    bool isDate = false,
  }) {
    final isDark = _isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isDate
              ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    controller.text =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  }
                }
              : null,
          child: AbsorbPointer(
            absorbing: isDate,
            child: TextField(
              controller: controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF334155) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _validationErrors[errorKey]!.isNotEmpty
                        ? Colors.red[400]!
                        : isDark
                        ? const Color(0xFF475569)
                        : Colors.grey[200]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _validationErrors[errorKey]!.isNotEmpty
                        ? Colors.red[400]!
                        : isDark
                        ? const Color(0xFF475569)
                        : Colors.grey[200]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _validationErrors[errorKey]!.isNotEmpty
                        ? Colors.red[400]!
                        : const Color(0xFF39A4E6),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_validationErrors[errorKey]!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _validationErrors[errorKey]!,
              style: TextStyle(color: Colors.red[500], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    String errorKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          items: _reportTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.text = value;
            }
          },
          decoration: InputDecoration(
            hintText: 'Select report type',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationErrors[errorKey]!.isNotEmpty
                    ? Colors.red[400]!
                    : Colors.grey[200]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationErrors[errorKey]!.isNotEmpty
                    ? Colors.red[400]!
                    : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationErrors[errorKey]!.isNotEmpty
                    ? Colors.red[400]!
                    : const Color(0xFF39A4E6),
                width: 2,
              ),
            ),
          ),
        ),
        if (_validationErrors[errorKey]!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _validationErrors[errorKey]!,
              style: TextStyle(color: Colors.red[500], fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating Medical Icons
        ..._buildFloatingIcons(context),
      ],
    );
  }

  List<Widget> _buildFloatingIcons(BuildContext context) {
    final icons = [
      {
        'icon': LucideIcons.stethoscope,
        'x': 0.2,
        'y': 0.1,
        'delay': 0.0,
        'duration': 20.0,
      },
      {
        'icon': LucideIcons.syringe,
        'x': 0.7,
        'y': 0.2,
        'delay': 2.0,
        'duration': 25.0,
      },
      {
        'icon': LucideIcons.pill,
        'x': 0.85,
        'y': 0.6,
        'delay': 4.0,
        'duration': 22.0,
      },
      {
        'icon': LucideIcons.heart,
        'x': 0.1,
        'y': 0.7,
        'delay': 1.0,
        'duration': 28.0,
      },
      {
        'icon': LucideIcons.activity,
        'x': 0.5,
        'y': 0.8,
        'delay': 3.0,
        'duration': 24.0,
      },
      {
        'icon': LucideIcons.thermometer,
        'x': 0.3,
        'y': 0.4,
        'delay': 5.0,
        'duration': 26.0,
      },
      {
        'icon': LucideIcons.clipboard,
        'x': 0.9,
        'y': 0.3,
        'delay': 2.5,
        'duration': 23.0,
      },
      {
        'icon': LucideIcons.testTube,
        'x': 0.15,
        'y': 0.5,
        'delay': 4.5,
        'duration': 27.0,
      },
    ];

    return icons.map((data) {
      final icon = data['icon'] as IconData;
      final x = data['x'] as double;
      final y = data['y'] as double;
      final delay = data['delay'] as double;
      final duration = data['duration'] as double;

      return Positioned(
        left: MediaQuery.of(context).size.width * x,
        top: MediaQuery.of(context).size.height * y,
        child:
            Icon(
                  icon,
                  size: 48,
                  color: const Color(0xFF39A4E6).withOpacity(0.08),
                )
                .animate(onPlay: (c) => c.repeat())
                .moveY(
                  begin: 0,
                  end: -30,
                  duration: duration.seconds,
                  curve: Curves.easeInOut,
                )
                .then(delay: delay.seconds)
                .moveY(
                  begin: -30,
                  end: 0,
                  duration: duration.seconds,
                  curve: Curves.easeInOut,
                )
                .rotate(begin: 0, end: 0.05, duration: (duration * 0.5).seconds)
                .then()
                .rotate(
                  begin: 0.05,
                  end: -0.05,
                  duration: (duration * 0.5).seconds,
                ),
      );
    }).toList();
  }
}
