import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../widgets/theme_toggle.dart';

import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ReportsScreen({super.key, this.onBack});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final reports = await ReportsService().getReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
    // TODO: Implement add report with backend if needed
    setState(() {
      _showAddForm = false;
    });
  }

  Future<void> _handleViewImages(Report report) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final images = await ReportsService().getReportImages(report.reportId);
      
      if (mounted) {
        Navigator.pop(context); // Hide loading

        if (images.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images found for this report')),
          );
          return;
        }

        final token = await ApiClient.instance.getToken();
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 500,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Report Images (${images.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final imageUrl = images[index].startsWith('http') 
                                ? images[index] 
                                : '${ApiConfig.baseUrl}${images[index]}';
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  headers: token != null 
                                      ? {'Authorization': 'Bearer $token'} 
                                      : null,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (ctx, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (ctx, err, stack) => const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 48),
                                        SizedBox(height: 8),
                                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteReport(String id) async {
    try {
      await ReportsService().deleteReport(int.parse(id));
      setState(() {
        _reports.removeWhere((report) => report.reportId.toString() == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleViewReport(Report report) {
    final isDark = _isDarkMode;
    final title = _getReportTitle(report);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF39A4E6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.fileText, color: Color(0xFF39A4E6), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.reportDate,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, color: isDark ? Colors.grey[400] : Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: report.fields.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final field = report.fields[index];
                    final isNormal = field.isNormal ?? true; // Default to true if null
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : Colors.grey[100]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.fieldName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      field.fieldValue,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                      ),
                                    ),
                                    if (field.fieldUnit != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        field.fieldUnit!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isNormal 
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFFF59E0B).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isNormal ? LucideIcons.check : LucideIcons.alertTriangle,
                              size: 16,
                              color: isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39A4E6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleShareReport(Report report) async {
    final buffer = StringBuffer();
    buffer.writeln('📋 Medical Report: ${_getReportTitle(report)}');
    buffer.writeln('📅 Date: ${report.reportDate}');
    buffer.writeln('🏥 Fields Extracted: ${report.totalFields}');
    buffer.writeln('----------------------------------------');
    
    for (var field in report.fields) {
      buffer.write('• ${field.fieldName}: ${field.fieldValue}');
      if (field.fieldUnit != null && field.fieldUnit!.isNotEmpty) {
        buffer.write(' ${field.fieldUnit}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('----------------------------------------');
    buffer.writeln('Shared from HealthTrack App 📱');
    
    await Share.share(
      buffer.toString(),
      subject: 'Medical Report: ${_getReportTitle(report)}',
    );
  }

  void _handleDownloadReport(Report report) {
    // Show a toast message indicating download action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading Report #${report.reportId}...'),
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
          report.reportDate.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filterType == "all"; // Simplified for now

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

          // Animated Background Elements removed


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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _fetchReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

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

  String _getReportTitle(Report report) {
    // Try to find a title from fields
    final titleField = report.fields.firstWhere(
      (f) => f.fieldName.toLowerCase().contains('test name') || 
             f.fieldName.toLowerCase().contains('report type') ||
             f.fieldName.toLowerCase().contains('study'),
      orElse: () => ReportField(
        id: 0, 
        fieldName: '', 
        fieldValue: '', 
        createdAt: ''
      ),
    );

    if (titleField.fieldName.isNotEmpty) {
      return titleField.fieldValue;
    }
    
    // If no specific field, try to guess from the first field if it looks like a title
    if (report.fields.isNotEmpty) {
      // Often the first field is the main test name
      return "Medical Report"; 
    }

    return "Medical Report";
  }

  Widget _buildReportCard(Report report, int index) {
    final isDark = _isDarkMode;
    final title = _getReportTitle(report);
    
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.totalFields} Fields Extracted',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildIconOnlyButton(
                  LucideIcons.trash2,
                  () => _handleDeleteReport(report.reportId.toString()),
                  isDestructive: true,
                ),
              ],
            ),
            
            const SizedBox(height: 20),



            Row(
              children: [
                Expanded(child: _buildOutlinedButton(LucideIcons.eye, 'View Details', () => _handleViewReport(report))),
                const SizedBox(width: 12),
                _buildIconOnlyButton(LucideIcons.share2, () => _handleShareReport(report)),
                const SizedBox(width: 12),
                _buildIconOnlyButton(LucideIcons.download, () => _handleDownloadReport(report)),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildOutlinedButton(IconData icon, String label, VoidCallback onTap) {
    final isDark = _isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF39A4E6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF39A4E6)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF39A4E6),
              ),
            ),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive
              ? (isDark ? Colors.red[300] : Colors.red[500])
              : (isDark ? Colors.grey[300] : const Color(0xFF64748B)),
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
