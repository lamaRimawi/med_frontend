import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import 'dart:ui';
import '../models/profile_model.dart';
import '../services/profile_state_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../widgets/access_verification_modal.dart';

class WebReportsView extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onBack;

  const WebReportsView({
    super.key,
    required this.isDarkMode,
    this.onBack,
  });

  @override
  State<WebReportsView> createState() => _WebReportsViewState();
}

class _WebReportsViewState extends State<WebReportsView> {
  List<Report> _reports = [];
  Map<int, String> _reportTypesMap = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterType = 'all';
  bool _showFilters = false;
  Report? _selectedReport;
  List<Map<String, dynamic>> _selectedReportImages = [];
  bool _isDetailLoading = false;
  String? _authToken;
  int? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _loadReports();
    // Listen to profile changes
    ProfileStateService().profileNotifier.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileStateService().profileNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    final profile = ProfileStateService().profileNotifier.value;
    if (mounted) {
      setState(() {
        _selectedProfileId = profile?.id;
        _isLoading = true;
      });
      _loadReports();
    }
  }

  Future<void> _initializeProfile() async {
    final selectedProfile = await ProfileStateService().getSelectedProfile();
    if (mounted) {
      setState(() {
        _selectedProfileId = selectedProfile?.id;
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
        'WebReportsView._loadReports: fetching for profileId=$_selectedProfileId',
      );
      final reports = await ReportsService().getReports(
        profileId: _selectedProfileId,
      );
      
      // Fetch timeline to get report types
      try {
        final timeline = await ReportsService().getTimeline(
          profileId: _selectedProfileId,
        );
        final typeMap = <int, String>{};
        for (var item in timeline) {
          if (item['report_id'] != null && item['report_type'] != null) {
            typeMap[item['report_id']] = item['report_type'];
          }
        }
        setState(() {
          _reportTypesMap = typeMap;
        });
      } catch (e) {
        debugPrint('Failed to fetch timeline: $e');
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is AccessVerificationException) {
           setState(() => _isLoading = false);
           _showVerificationDialog();
           return;
        }

        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showVerificationDialog() async {
     if (_selectedProfileId == null) return;
     
     await showDialog(
       context: context,
       builder: (context) => Dialog(
         backgroundColor: Colors.transparent,
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxWidth: 400),
           child: AccessVerificationModal(
              resourceType: 'profile',
              resourceId: _selectedProfileId!,
              onSuccess: () {
                 if (mounted) {
                    setState(() => _isLoading = true);
                    _loadReports();
                 }
              }
           ),
         ),
       ),
     );
  }

  String _getReportTitle(Report report) {
    if (report.reportName != null && report.reportName!.isNotEmpty) {
      return report.reportName!;
    }
    
    if (_reportTypesMap.containsKey(report.reportId)) {
      final type = _reportTypesMap[report.reportId];
      if (type != null && type.isNotEmpty && type != 'General Report') {
        return type;
      }
    }

    if (report.reportType != null && report.reportType!.isNotEmpty) {
      return report.reportType!;
    }

    return 'Medical Report ${report.reportDate.split(' ')[0]}';
  }

  List<Report> get _filteredReports {
    return _reports.where((report) {
      final title = _getReportTitle(report).toLowerCase();
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) ||
          report.reportDate.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _filterType == 'all' || 
          _getReportTitle(report).toLowerCase().contains(_filterType.toLowerCase());
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _handleDeleteReport(int reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: (widget.isDarkMode ? Colors.black : Colors.white).withOpacity(0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  'Delete Report?',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action will permanently remove the report. You cannot undo this.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );

    if (confirmed == true) {
      try {
        await ReportsService().deleteReport(reportId);
        await _loadReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report deleted successfully'),
              backgroundColor: const Color(0xFF10B981),
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
  }

  Future<void> _handleViewReport(Report report) async {
    setState(() {
      _selectedReport = report;
      _isDetailLoading = true;
    });

    try {
      final token = await ApiClient.instance.getToken();
      final images = await ReportsService().getReportImages(report.reportId);
      if (mounted) {
        setState(() {
          _authToken = token;
          _selectedReportImages = images;
          _isDetailLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading report images: $e');
      if (mounted) {
        setState(() => _isDetailLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load images: $e')),
        );
      }
    }
  }

  Future<void> _handleDownloadReport(Report report) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing download...')),
      );

      final token = await ApiClient.instance.getToken();
      
      for (var i = 0; i < _selectedReportImages.length; i++) {
        final imgMap = _selectedReportImages[i];
        final fileIndex = imgMap['index'] ?? (i + 1);
        final url = '${ApiConfig.baseUrl}${ApiConfig.reports}/${report.reportId}/images/$fileIndex';
        
        final response = await http.get(
          Uri.parse(url),
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        );

        if (response.statusCode == 200) {
          String ext = 'jpg';
          final contentType = response.headers['content-type'];
          if (contentType?.contains('pdf') ?? false) ext = 'pdf';
          else if (contentType?.contains('png') ?? false) ext = 'png';

          final filename = imgMap['filename'] ?? 'report_${report.reportId}_$i';
          
          await FileSaver.instance.saveFile(
            name: filename.toString().split('.').first,
            bytes: response.bodyBytes,
            ext: ext,
            mimeType: ext == 'pdf' ? MimeType.pdf : (ext == 'png' ? MimeType.png : MimeType.jpeg),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download started'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleShareReport(Report report) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('📋 Medical Report Summary');
      buffer.writeln('Name: ${_getReportTitle(report)}');
      buffer.writeln('Date: ${report.reportDate}');
      buffer.writeln('-------------------------');
      
      for (var field in report.fields) {
        buffer.writeln('• ${field.fieldName}: ${field.fieldValue} ${field.fieldUnit ?? ""}');
      }
      
      buffer.writeln('-------------------------');
      buffer.writeln('Generated via MediScan Web');

      await Share.share(buffer.toString(), subject: 'Medical Report: ${_getReportTitle(report)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            _buildGlassHeader(),
            _selectedReport != null ? _buildReportDetailView() : Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorView()
                      : _filteredReports.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(40),
                              physics: const BouncingScrollPhysics(),
                              child: _buildReportsGrid(),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'My Reports',
                style: GoogleFonts.outfit(
                  fontSize: 28, // Reduced from 32
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
              const SizedBox(width: 20),
              const Spacer(),
              if (_selectedReport == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39A4E6).withOpacity(0.1), // Reduced opacity
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.2)),
                  ),
                  child: Text(
                    '${_reports.length} Reports',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF39A4E6),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ],
          ),
          if (_selectedReport == null) ...[
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.black.withOpacity(0.2) // Matched Dashboard Search Bar
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25), // More rounded like Dashboard
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: GoogleFonts.outfit(
                        color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        hintText: 'Search reports...',
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildFilterButton(),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            if (_showFilters) ...[
              const SizedBox(height: 20),
              _buildFilterChips(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final isActive = _showFilters || _filterType != 'all';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _showFilters = !_showFilters),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF39A4E6)
                : (widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white), // Matched button style
            borderRadius: BorderRadius.circular(25), // Rounded to match search
            border: Border.all(
              color: isActive
                  ? const Color(0xFF39A4E6)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.filter,
                size: 20,
                color: isActive ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.grey[700]),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 12),
          _buildFilterChip('Laboratory', 'laboratory'),
          const SizedBox(width: 12),
          _buildFilterChip('Radiology', 'radiology'),
          const SizedBox(width: 12),
          _buildFilterChip('Cardiology', 'cardiology'),
          const SizedBox(width: 12),
          _buildFilterChip('Pathology', 'pathology'),
        ],
      ).animate().fadeIn().slideX(),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF39A4E6)
              : (widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF39A4E6)
                : (widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200]!),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (widget.isDarkMode ? Colors.white70 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.1, // Reduced height (was 0.85)
      ),
      itemCount: _filteredReports.length,
      itemBuilder: (context, index) {
        return _buildGlassReportCard(_filteredReports[index], index);
      },
    );
  }

  Widget _buildGlassReportCard(Report report, int index) {
    final title = _getReportTitle(report);
    final hasAbnormal = report.fields.any((f) => f.isNormal == false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleViewReport(report),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.03) // Back to subtle glass
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(widget.isDarkMode ? 0.05 : 0.5), // Subtle border
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02), // Subtle shadow
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Reduced blur for performance/subtlety
              child: Padding(
                padding: const EdgeInsets.all(20), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10), // Reduced icon padding
                          decoration: BoxDecoration(
                            color: const Color(0xFF39A4E6).withOpacity(0.1), // Subtle icon bg
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.fileText, color: Color(0xFF39A4E6), size: 22),
                        ),
                        PopupMenuButton(
                          icon: Icon(
                            LucideIcons.moreVertical,
                            color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.eye, size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text('View', style: GoogleFonts.outfit()),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('Delete', style: GoogleFonts.outfit(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') _handleViewReport(report);
                            if (value == 'delete') _handleDeleteReport(report.reportId);
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title, // Removed toUpperCase for cleaner look
                      style: GoogleFonts.outfit(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 13, color: widget.isDarkMode ? Colors.white38 : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          report.reportDate.split(' ')[0],
                          style: GoogleFonts.inter(
                            color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: hasAbnormal 
                              ? const Color(0xFFEF4444).withOpacity(0.1) 
                              : const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: hasAbnormal 
                                ? const Color(0xFFEF4444).withOpacity(0.2) 
                                : const Color(0xFF10B981).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasAbnormal ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                                size: 12,
                                color: hasAbnormal ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasAbnormal ? 'Review Needed' : 'Normal',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: hasAbnormal ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${report.totalFields} fields',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate(delay: (index * 100).ms)
         .fadeIn(duration: 400.ms)
         .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
      ),
    );
  }

  Widget _buildReportDetailView() {
    final report = _selectedReport!;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        child: Column(
          children: [
            // Detail Header with Back Button
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedReport = null),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.arrowLeft, size: 20, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getReportTitle(report),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Report Date: ${report.reportDate}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                _buildActionButton(
                  icon: LucideIcons.download,
                  label: 'Download',
                  onTap: () => _handleDownloadReport(report),
                  color: const Color(0xFF39A4E6),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: LucideIcons.share2,
                  label: 'Share',
                  onTap: () => _handleShareReport(report),
                  color: const Color(0xFFF97316),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: LucideIcons.trash2,
                  label: 'Delete',
                  onTap: () => _handleDeleteReport(report.reportId),
                  color: const Color(0xFFEF4444),
                ),
              ],
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 30),
            Expanded(
              child: _isDetailLoading 
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medical Data Section
                      Expanded(
                        flex: 3,
                        child: _buildMedicalDataSection(report),
                      ),
                      const SizedBox(width: 30),
                      // Images Section
                      Expanded(
                        flex: 2,
                        child: _buildImageGallerySection(report),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalDataSection(Report report) {
    return Container(
      decoration: BoxDecoration(
        color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Extracted Medical Data',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              if (report.fields.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text('No structured data found', style: GoogleFonts.inter(color: Colors.grey)),
                  ),
                )
              else
                ...report.fields.map((field) => _buildDataRow(field)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(ReportField field) {
    final isNormal = field.isNormal ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNormal ? Colors.white.withOpacity(0.05) : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.fieldName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (field.category != null)
                  Text(
                    field.category!,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${field.fieldValue} ${field.fieldUnit ?? ""}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isNormal 
                      ? (widget.isDarkMode ? Colors.white : Colors.black87)
                      : const Color(0xFFEF4444),
                  ),
                ),
                if (field.normalRange != null)
                  Text(
                    'Range: ${field.normalRange}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            isNormal ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
            size: 18,
            color: isNormal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallerySection(Report report) {
    return Container(
      decoration: BoxDecoration(
        color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Images',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedReportImages.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.imageOff, size: 40, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('No images available', style: GoogleFonts.inter(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: _selectedReportImages.length,
                      itemBuilder: (context, index) {
                        final img = _selectedReportImages[index];
                        final fileIndex = img['index'] ?? (index + 1);
                        final url = '${ApiConfig.baseUrl}${ApiConfig.reports}/${report.reportId}/images/$fileIndex';
                        
                        return GestureDetector(
                          onTap: () => _showFullImage(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              headers: {
                                'Authorization': 'Bearer $_authToken'
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.withOpacity(0.1),
                                child: const Icon(LucideIcons.image, color: Colors.grey),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                          ),
                        ).animate().scale(delay: (index * 100).ms);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  headers: {
                    'Authorization': 'Bearer $_authToken'
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.fileText, size: 60, color: Color(0xFF39A4E6)),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
             'No Reports Found',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Upload or scan a new medical report to get started.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: widget.isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 60, color: Color(0xFFEF4444)),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadReports,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39A4E6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}


