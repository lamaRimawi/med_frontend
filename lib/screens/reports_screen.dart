import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:math' as math;

class Report {
  final String id;
  final String title;
  final String type;
  final String date;
  final String doctor;
  final String hospital;
  final String status;
  final String? fileUrl;

  Report({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.doctor,
    required this.hospital,
    required this.status,
    this.fileUrl,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Report> _reports = [
    Report(
      id: "1",
      title: "Blood Test Report",
      type: "Laboratory",
      date: "18 Nov 2025",
      doctor: "Dr. Sarah Wilson",
      hospital: "City Medical Center",
      status: "completed",
    ),
    Report(
      id: "2",
      title: "X-Ray Chest",
      type: "Radiology",
      date: "15 Nov 2025",
      doctor: "Dr. Michael Chen",
      hospital: "General Hospital",
      status: "completed",
    ),
    Report(
      id: "3",
      title: "ECG Report",
      type: "Cardiology",
      date: "10 Nov 2025",
      doctor: "Dr. James Brown",
      hospital: "Heart Care Clinic",
      status: "completed",
    ),
    Report(
      id: "4",
      title: "MRI Brain Scan",
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

  final _titleController = TextEditingController();
  final _typeController = TextEditingController(); // We'll use a dropdown but keep this for value
  final _dateController = TextEditingController();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();

  Map<String, String> _validationErrors = {
    'title': '',
    'type': '',
    'date': '',
    'doctor': '',
    'hospital': '',
  };

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
    _titleController.dispose();
    _typeController.dispose();
    _dateController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  bool _validateReport() {
    final errors = {
      'title': '',
      'type': '',
      'date': '',
      'doctor': '',
      'hospital': '',
    };
    bool isValid = true;

    if (_titleController.text.trim().isEmpty) {
      errors['title'] = "Report title is required";
      isValid = false;
    } else if (_titleController.text.trim().length < 3) {
      errors['title'] = "Title must be at least 3 characters";
      isValid = false;
    }

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
        title: _titleController.text.trim(),
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

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _typeController.clear();
      _dateController.clear();
      _doctorController.clear();
      _hospitalController.clear();
      _validationErrors = {
        'title': '',
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
          report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.doctor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.hospital.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filterType == "all" || report.type == _filterType;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Will be covered by gradient
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Colors.white, Color(0xFFEFF6FF)],
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
                Expanded(
                  child: _buildReportsList(),
                ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: ClipRRect( // For backdrop blur if supported, or just container
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Reports',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'View and manage your reports',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: const InputDecoration(
                                hintText: 'Search reports...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _showFilters || _filterType != 'all'
                            ? const Color(0xFF39A4E6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showFilters || _filterType != 'all'
                              ? const Color(0xFF39A4E6)
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
                            ..._reportTypes.map((type) => _buildFilterChip(type, type)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${reports.length} ${reports.length == 1 ? 'Report' : 'Reports'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            GestureDetector(
              onTap: () => setState(() => _showAddForm = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39A4E6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.plus, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Add Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (reports.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(LucideIcons.fileText, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty || _filterType != 'all'
                        ? 'Try adjusting your filters'
                        : 'Add your first medical report',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  if (_searchQuery.isEmpty && _filterType == 'all') ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _showAddForm = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                          ),
                          borderRadius: BorderRadius.circular(24),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
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
                  child: const Icon(LucideIcons.fileText, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              report.type,
                              style: const TextStyle(
                                color: Color(0xFF39A4E6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: report.status == 'completed'
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEFCE8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              report.status == 'completed' ? 'Completed' : 'Pending',
                              style: TextStyle(
                                color: report.status == 'completed'
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRow(LucideIcons.stethoscope, report.doctor),
                      const SizedBox(height: 8),
                      _buildInfoRow(LucideIcons.clipboard, report.hospital),
                      const SizedBox(height: 8),
                      _buildInfoRow(LucideIcons.calendar, report.date),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildActionButton(LucideIcons.eye, () {}, const Color(0xFF39A4E6)),
                    const SizedBox(height: 8),
                    _buildActionButton(LucideIcons.download, () {}, const Color(0xFF39A4E6)),
                    const SizedBox(height: 8),
                    _buildActionButton(LucideIcons.x, () => _handleDeleteReport(report.id), Colors.red[400]!),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildAddReportModal() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _resetForm,
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      const Text(
                        'Add Medical Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF39A4E6),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: _resetForm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('Report Title *', _titleController, 'e.g., Blood Test Report', 'title'),
                  const SizedBox(height: 16),
                  _buildDropdownField('Report Type *', _typeController, 'type'),
                  const SizedBox(height: 16),
                  _buildTextField('Report Date *', _dateController, 'YYYY-MM-DD', 'date', isDate: true),
                  const SizedBox(height: 16),
                  _buildTextField('Doctor Name *', _doctorController, 'e.g., Dr. Sarah Wilson', 'doctor'),
                  const SizedBox(height: 16),
                  _buildTextField('Hospital/Clinic *', _hospitalController, 'e.g., City Medical Center', 'hospital'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Note: ',
                            style: TextStyle(
                              color: Color(0xFF39A4E6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: 'You can upload the actual report file after saving this information.',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
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
                              side: BorderSide(color: Colors.grey[200]!, width: 2),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
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

  Widget _buildTextField(String label, TextEditingController controller, String hint, String errorKey, {bool isDate = false}) {
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
                    controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  }
                }
              : null,
          child: AbsorbPointer(
            absorbing: isDate,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _validationErrors[errorKey]!.isNotEmpty ? Colors.red[400]! : Colors.grey[200]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _validationErrors[errorKey]!.isNotEmpty ? Colors.red[400]! : Colors.grey[200]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _validationErrors[errorKey]!.isNotEmpty ? Colors.red[400]! : const Color(0xFF39A4E6),
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

  Widget _buildDropdownField(String label, TextEditingController controller, String errorKey) {
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationErrors[errorKey]!.isNotEmpty ? Colors.red[400]! : Colors.grey[200]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationErrors[errorKey]!.isNotEmpty ? Colors.red[400]! : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationErrors[errorKey]!.isNotEmpty ? Colors.red[400]! : const Color(0xFF39A4E6),
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
        // Glowing Circles
        Positioned(
          left: MediaQuery.of(context).size.width * 0.1,
          top: MediaQuery.of(context).size.height * 0.2,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[400]!.withOpacity(0.08),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 8.seconds,
              ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.1,
          bottom: MediaQuery.of(context).size.height * 0.2,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[300]!.withOpacity(0.08),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
                duration: 10.seconds,
              ),
        ),

        // Floating Medical Icons
        ..._buildFloatingIcons(context),
      ],
    );
  }

  List<Widget> _buildFloatingIcons(BuildContext context) {
    final icons = [
      {'icon': LucideIcons.stethoscope, 'x': 0.2, 'y': 0.1, 'delay': 0.0, 'duration': 20.0},
      {'icon': LucideIcons.syringe, 'x': 0.7, 'y': 0.2, 'delay': 2.0, 'duration': 25.0},
      {'icon': LucideIcons.pill, 'x': 0.85, 'y': 0.6, 'delay': 4.0, 'duration': 22.0},
      {'icon': LucideIcons.heart, 'x': 0.1, 'y': 0.7, 'delay': 1.0, 'duration': 28.0},
      {'icon': LucideIcons.activity, 'x': 0.5, 'y': 0.8, 'delay': 3.0, 'duration': 24.0},
      {'icon': LucideIcons.thermometer, 'x': 0.3, 'y': 0.4, 'delay': 5.0, 'duration': 26.0},
      {'icon': LucideIcons.clipboard, 'x': 0.9, 'y': 0.3, 'delay': 2.5, 'duration': 23.0},
      {'icon': LucideIcons.testTube, 'x': 0.15, 'y': 0.5, 'delay': 4.5, 'duration': 27.0},
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
        child: Icon(
          icon,
          size: 48,
          color: const Color(0xFF39A4E6).withOpacity(0.08),
        )
            .animate(onPlay: (c) => c.repeat())
            .moveY(begin: 0, end: -30, duration: duration.seconds, curve: Curves.easeInOut)
            .then(delay: delay.seconds)
            .moveY(begin: -30, end: 0, duration: duration.seconds, curve: Curves.easeInOut)
            .rotate(begin: 0, end: 0.05, duration: (duration * 0.5).seconds)
            .then()
            .rotate(begin: 0.05, end: -0.05, duration: (duration * 0.5).seconds),
      );
    }).toList();
  }
}
