import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../widgets/theme_toggle.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Load from cache immediately
    final cached = ReportsService().cachedReports;
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _reports = cached;
        _isLoading = false;
        _error = null;
      });
    }

    // 2. Fetch fresh data
    await _fetchReports(silent: cached != null && cached.isNotEmpty);
  }

  Future<void> _fetchReports({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final reports = await ReportsService().getReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Unauthorized')) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
          return;
        }

        // If we have data, show snackbar instead of full error
        if (_reports.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update reports: $e')),
          );
          // Ensure loading is false
          setState(() {
            _isLoading = false;
          });
        } else {
          // No data, show full error
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
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
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark;

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

  String _getReportTitle(Report report) {
    // Priority 1: Check for explicit "Report Type" or "Test Name" fields
    final titleField = report.fields.firstWhere(
      (f) =>
          f.fieldName.toLowerCase().contains('test name') ||
          f.fieldName.toLowerCase() == 'report type' ||
          f.fieldName.toLowerCase() == 'study' ||
          f.fieldName.toLowerCase() == 'diagnosis' ||
          f.fieldName.toLowerCase().contains('examination') ||
          f.fieldName.toLowerCase().contains('investigation') ||
          f.fieldName.toLowerCase() == 'title' ||
          f.fieldName.toLowerCase() == 'name',
      orElse: () =>
          ReportField(id: 0, fieldName: '', fieldValue: '', createdAt: ''),
    );

    if (titleField.fieldName.isNotEmpty) {
      return titleField.fieldValue;
    }

    // Priority 2: Check additional fields
    final addTitleField = report.additionalFields.firstWhere(
      (f) =>
          f.fieldName.toLowerCase().contains('test name') ||
          f.fieldName.toLowerCase() == 'report type' ||
          f.fieldName.toLowerCase() == 'title',
      orElse: () =>
          AdditionalField(id: 0, fieldName: '', fieldValue: '', category: ''),
    );

    if (addTitleField.fieldName.isNotEmpty) {
      return addTitleField.fieldValue;
    }

    // Priority 3: Use Date and ID as a fallback
    return "Medical Report ${report.reportDate}";
  }

  Future<void> _handleViewReport(Report report) async {
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                _ModernReportViewer(report: report, images: images),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report details: $e')),
        );
      }
    }
  }

  Future<void> _handleShareReport(Report report) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing report for sharing...')),
      );

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

      // Get images
      final images = await ReportsService().getReportImages(report.reportId);
      final xFiles = <XFile>[];

      if (images.isNotEmpty) {
        final token = await ApiClient.instance.getToken();
        final tempDir = await getTemporaryDirectory();

        for (var i = 0; i < images.length; i++) {
          final imageMap = images[i];
          final backendIndex = imageMap['index'] as int?;
          final fileIndex = backendIndex ?? (i + 1);

          final imageUrl =
              '${ApiConfig.baseUrl}${ApiConfig.reports}/${report.reportId}/images/$fileIndex';

          try {
            final response = await http.get(
              Uri.parse(imageUrl),
              headers: token != null
                  ? {'Authorization': 'Bearer $token'}
                  : null,
            );

            if (response.statusCode == 200) {
              final file = File(
                '${tempDir.path}/report_${report.reportId}_$i.jpg',
              );
              await file.writeAsBytes(response.bodyBytes);
              xFiles.add(XFile(file.path));
            }
          } catch (e) {
            debugPrint('Error downloading image for share: $e');
          }
        }
      }

      if (xFiles.isNotEmpty) {
        await Share.shareXFiles(
          xFiles,
          text: buffer.toString(),
          subject: 'Medical Report: ${_getReportTitle(report)}',
        );
      } else {
        await Share.share(
          buffer.toString(),
          subject: 'Medical Report: ${_getReportTitle(report)}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing report: $e')));
      }
    }
  }

  Future<void> _handleDownloadReport(Report report) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading Report #${report.reportId}...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final images = await ReportsService().getReportImages(report.reportId);
      if (images.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images to download for this report'),
            ),
          );
        }
        return;
      }

      final token = await ApiClient.instance.getToken();
      final tempDir = await getTemporaryDirectory();
      int successCount = 0;

      for (var i = 0; i < images.length; i++) {
        final imageMap = images[i];
        final backendIndex = imageMap['index'] as int?;
        final fileIndex = backendIndex ?? (i + 1);

        final imageUrl =
            '${ApiConfig.baseUrl}${ApiConfig.reports}/${report.reportId}/images/$fileIndex';

        try {
          final response = await http.get(
            Uri.parse(imageUrl),
            headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          );

          if (response.statusCode == 200) {
            final filePath =
                '${tempDir.path}/report_${report.reportId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);

            // Save to gallery
            await Gal.putImage(filePath, album: 'Medical Reports');
            successCount++;
          }
        } catch (e) {
          debugPrint('Error downloading image: $e');
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully saved $successCount images to gallery',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download images'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
      }
    }
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
      final matchesSearch = report.reportDate.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

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
              onPressed: () => _fetchReports(silent: false),
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
                      color: _isDarkMode
                          ? Colors.white
                          : const Color(0xFF111827),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
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
                Expanded(
                  child: _buildOutlinedButton(
                    LucideIcons.eye,
                    'View Details',
                    () => _handleViewReport(report),
                  ),
                ),
                const SizedBox(width: 12),
                _buildIconOnlyButton(
                  LucideIcons.share2,
                  () => _handleShareReport(report),
                ),
                const SizedBox(width: 12),
                _buildIconOnlyButton(
                  LucideIcons.download,
                  () => _handleDownloadReport(report),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildOutlinedButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF39A4E6), width: 1.5),
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
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => setState(() {
                          _showAddForm = false;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Report Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _typeController,
                    label: 'Report Type',
                    hint: 'Enter report type',
                    errorText: _validationErrors['type'],
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _dateController,
                    label: 'Date',
                    hint: 'Select report date',
                    errorText: _validationErrors['date'],
                    isRequired: true,
                    readOnly: true,
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: const Color(0xFF39A4E6),

                              colorScheme: ColorScheme.light(
                                primary: const Color(0xFF39A4E6),
                              ),
                              buttonTheme: const ButtonThemeData(
                                textTheme: ButtonTextTheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (selectedDate != null) {
                        setState(() {
                          _dateController.text =
                              '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _doctorController,
                    label: 'Doctor\'s Name',
                    hint: 'Enter doctor\'s name',
                    errorText: _validationErrors['doctor'],
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _hospitalController,
                    label: 'Hospital/Clinic Name',
                    hint: 'Enter hospital or clinic name',
                    errorText: _validationErrors['hospital'],
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_validateReport()) {
                          _handleAddReport();
                        }
                      },
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add Report'),
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
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
    bool isRequired = false,
    bool readOnly = false,
    GestureTapCallback? onTap,
  }) {
    final isDark = _isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF111827),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _ModernReportViewer extends StatefulWidget {
  final Report report;
  final List<Map<String, dynamic>> images;

  const _ModernReportViewer({
    required this.report,
    required this.images,
    Key? key,
  }) : super(key: key);

  @override
  State<_ModernReportViewer> createState() => _ModernReportViewerState();
}

class _ModernReportViewerState extends State<_ModernReportViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  // Cache for downloaded files (index -> path)
  final Map<int, String> _localFilePaths = {};
  final Map<int, bool> _isDownloading = {};
  final Map<int, String> _downloadErrors = {};
  final Map<int, bool> _isPdfMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);

    // Load the first file immediately
    if (widget.images.isNotEmpty) {
      _loadFile(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _isPdf(String filename) {
    return filename.toLowerCase().endsWith('.pdf');
  }

  Future<void> _loadFile(int index) async {
    if (_localFilePaths.containsKey(index) || _isDownloading[index] == true)
      return;

    setState(() {
      _isDownloading[index] = true;
      _downloadErrors.remove(index);
    });

    int retryCount = 0;
    // Increased retries to prevent premature error display
    const maxRetries = 5;

    while (retryCount < maxRetries) {
      try {
        final imageMap = widget.images[index];
        // Use the index from the backend if available, otherwise fallback to list index + 1
        final backendIndex = imageMap['index'] as int?;
        final fileIndex = backendIndex ?? (index + 1);

        final url =
            '${ApiConfig.baseUrl}${ApiConfig.reports}/${widget.report.reportId}/images/$fileIndex';

        final token = await ApiClient.instance.getToken();

        final request = http.Request('GET', Uri.parse(url));
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Connection'] = 'close';

        // Add timeout to prevent hanging
        final response = await request.send().timeout(
          const Duration(seconds: 15),
        );

        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final filename = imageMap['filename'] as String? ?? 'file_$fileIndex';

          // Determine type from header or filename
          bool isPdf = _isPdf(filename);
          final contentType = response.headers['content-type'];
          if (contentType != null) {
            if (contentType.toLowerCase().contains('application/pdf')) {
              isPdf = true;
            } else if (contentType.toLowerCase().contains('image/')) {
              isPdf = false;
            }
          }

          final extension = isPdf ? 'pdf' : 'jpg';
          final file = File(
            '${dir.path}/report_${widget.report.reportId}_${index}_${DateTime.now().millisecondsSinceEpoch}.$extension',
          );

          final sink = file.openWrite();
          await response.stream.pipe(sink);
          await sink.close();

          // Verify file size
          final stat = await file.stat();
          if (stat.size == 0) {
            throw Exception('Downloaded file is empty');
          }

          if (mounted) {
            setState(() {
              _localFilePaths[index] = file.path;
              _isPdfMap[index] = isPdf;
              _isDownloading[index] = false;
            });
          }
          return; // Success
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error downloading file (attempt ${retryCount + 1}): $e');
        retryCount++;
        if (retryCount >= maxRetries) {
          if (mounted) {
            setState(() {
              _isDownloading[index] = false;
              _downloadErrors[index] = e.toString();
            });
          }
        } else {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        }
      }
    }
  }

  String? _getFieldValue(String key) {
    // Try to find in fields
    try {
      final field = widget.report.fields.firstWhere(
        (f) => f.fieldName.toLowerCase().contains(key.toLowerCase()),
        orElse: () =>
            ReportField(id: 0, fieldName: '', fieldValue: '', createdAt: ''),
      );
      if (field.fieldName.isNotEmpty &&
          field.fieldValue.toLowerCase() != 'n/a' &&
          field.fieldValue.toLowerCase() != 'null' &&
          field.fieldValue.trim().isNotEmpty) {
        return field.fieldValue;
      }
    } catch (_) {}

    // Try to find in additional fields
    try {
      final addField = widget.report.additionalFields.firstWhere(
        (f) => f.fieldName.toLowerCase().contains(key.toLowerCase()),
        orElse: () =>
            AdditionalField(id: 0, fieldName: '', fieldValue: '', category: ''),
      );
      if (addField.fieldName.isNotEmpty &&
          addField.fieldValue.toLowerCase() != 'n/a' &&
          addField.fieldValue.toLowerCase() != 'null' &&
          addField.fieldValue.trim().isNotEmpty) {
        return addField.fieldValue;
      }
    } catch (_) {}

    return null;
  }

  String? _getSmartReportType() {
    // List of keys to look for in priority order
    final keys = [
      'report type',
      'test name',
      'study',
      'examination',
      'investigation',
      'diagnosis',
      'title',
    ];

    for (final key in keys) {
      final val = _getFieldValue(key);
      if (val != null) return val;
    }

    return null;
  }

  String _formatFieldName(String name) {
    if (name.isEmpty) return name;
    // Split by underscore or space
    final words = name.replaceAll('_', ' ').split(' ');
    return words
        .map((word) {
          if (word.isEmpty) return '';
          // Handle special cases like WBC, RBC, MCV, etc.
          final upperWord = word.toUpperCase();
          if ([
            'WBC',
            'RBC',
            'MCV',
            'MCH',
            'MCHC',
            'HGB',
            'HCT',
            'BMI',
            'BP',
          ].contains(upperWord)) {
            return upperWord;
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = widget.images;

    final validFields = widget.report.fields
        .where(
          (f) =>
              f.fieldValue.trim().isNotEmpty &&
              f.fieldValue.toLowerCase() != 'n/a' &&
              f.fieldValue.toLowerCase() != 'null' &&
              f.fieldValue.toLowerCase() != 'none',
        )
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Details',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF39A4E6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF39A4E6),
          tabs: const [
            Tab(text: 'Files'),
            Tab(text: 'Extracted Data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.imageOff,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No files available',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildFileViewer(isDark),

          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(context, 'Report Info', [
                _buildInfoTile(context, 'Type', _getSmartReportType()),
                _buildInfoTile(context, 'Date', widget.report.reportDate),
                _buildInfoTile(context, 'Doctor', _getFieldValue('doctor')),
                _buildInfoTile(context, 'Hospital', _getFieldValue('hospital')),
              ]),
              const SizedBox(height: 24),
              if (validFields.isNotEmpty)
                _buildSection(
                  context,
                  'Extracted Fields',
                  validFields
                      .map((field) => _buildFieldTile(context, field))
                      .toList(),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.fileSearch,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No extracted data available',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer(bool isDark) {
    final images = widget.images;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              _loadFile(index);
            });
          },
          itemBuilder: (context, index) {
            final isDownloading = _isDownloading[index] ?? false;
            final error = _downloadErrors[index];
            final localPath = _localFilePaths[index];
            final imageMap = images[index];
            final filename = imageMap['filename'] as String? ?? '';
            final isPdf = _isPdfMap[index] ?? _isPdf(filename);

            if (isDownloading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load file',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _loadFile(index),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (localPath == null) {
              // Trigger load if not already loading
              if (_isDownloading[index] != true &&
                  _downloadErrors[index] == null) {
                _loadFile(index);
              }
              return const Center(child: CircularProgressIndicator());
            }

            if (isPdf) {
              return _PdfViewerPage(filePath: localPath, isDark: isDark);
            }

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  File(localPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Error displaying image'));
                  },
                ),
              ),
            );
          },
        ),
        if (images.length > 1 &&
            !(_isPdfMap[_currentIndex] ??
                _isPdf(images[_currentIndex]['filename'] as String? ?? '')))
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: images.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: const Color(0xFF39A4E6),
                  dotColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                onDotClicked: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
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
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String? value) {
    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == 'n/a' ||
        value.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTile(BuildContext context, ReportField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedName = _formatFieldName(field.fieldName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey[100]!,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedName,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      field.fieldValue,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (field.fieldUnit != null &&
                        field.fieldUnit!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        field.fieldUnit!,
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (field.isNormal != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: field.isNormal!
                    ? (isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFDCFCE7))
                    : (isDark
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: field.isNormal!
                      ? (isDark
                            ? const Color(0xFF059669)
                            : const Color(0xFF86EFAC))
                      : (isDark
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFFCA5A5)),
                ),
              ),
              child: Text(
                field.isNormal! ? 'Normal' : 'Abnormal',
                style: TextStyle(
                  color: field.isNormal!
                      ? (isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF166534))
                      : (isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFF991B1B)),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfViewerPage extends StatefulWidget {
  final String filePath;
  final bool isDark;

  const _PdfViewerPage({required this.filePath, required this.isDark, Key? key})
    : super(key: key);

  @override
  State<_PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<_PdfViewerPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _ready = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading PDF',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.file(
          File(widget.filePath),
          scrollDirection: PdfScrollDirection.vertical,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _totalPages = details.document.pages.count;
              _ready = true;
            });
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _errorMessage = details.error;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _currentPage = details.newPageNumber - 1;
            });
          },
        ),
        if (_ready)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
