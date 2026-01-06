import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../widgets/theme_toggle.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:mediScan/models/extracted_report_data.dart'; // For TestResult
import 'package:mediScan/widgets/report_content_widget.dart';
import 'package:intl/intl.dart';

import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../services/api_client.dart';
import '../widgets/access_verification_modal.dart';
import '../config/api_config.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/profile_model.dart';
import '../widgets/profile_selector.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/profile_service.dart';
import '../services/profile_state_service.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final int? initialReportId;

  const ReportsScreen({super.key, this.onBack, this.initialReportId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Report> _reports = [];
  Map<int, String> _reportTypesMap = {};
  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  int? _selectedProfileId;
  String? _selectedProfileRelation;
  UserProfile? _selectedProfile; // Added for name display

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _loadInitialData();
    _loadUserProfile(); 
    // Listen to profile changes
    ProfileStateService().profileNotifier.addListener(_onProfileChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('profile_id')) {
      final profileId = int.tryParse(args['profile_id'].toString());
      if (profileId != null && profileId != _selectedProfileId) {
        // Use Future.delayed to avoid calling setState during build
        Future.microtask(() => _switchToProfileById(profileId));
      }
    }
  }

  Future<void> _switchToProfileById(int profileId) async {
    try {
      final profiles = await ProfileService.getProfiles();
      final profile = profiles.firstWhere((p) => p.id == profileId);
      await ProfileStateService().setSelectedProfile(profile);
    } catch (e) {
      debugPrint('Error switching profile from notification: $e');
    }
  }


  void _onProfileChanged() {
    final profile = ProfileStateService().profileNotifier.value;
    if (mounted) {
      setState(() {
        _selectedProfile = profile;
        _selectedProfileId = profile?.id;
        _selectedProfileRelation = profile?.relationship;
        _isLoading = true; // Show loading indicator
        _reports = []; // Clear previous data immediately
        _error = null; // Clear previous errors
      });
      _fetchReports();
    }
  }

  bool _hasHandledInitialReport = false;

  Future<void> _initializeProfile() async {
    // Load the selected profile from global state
    final selectedProfile = await ProfileStateService().getSelectedProfile();
    if (mounted) {
      setState(() {
        _selectedProfile = selectedProfile;
        _selectedProfileId = selectedProfile?.id;
        _selectedProfileRelation = selectedProfile?.relationship;
      });
    }
  }
  Future<void> _loadUserProfile() async {
    try {
      // Try to load from prefs first
      final user = await User.loadFromPrefs();
      if (user != null) {
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      } else {
        // Fetch from API if not in prefs
        final fetchedUser = await UserService().getUserProfile();
        if (mounted) {
          setState(() {
            _currentUser = fetchedUser;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
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
    if (!mounted) return;
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // If 'Self', pass null to avoid backend verification checks reserved for other profiles
      final isSelf = _selectedProfile == null || _selectedProfile?.relationship == 'Self';
      final apiProfileId = isSelf ? null : _selectedProfile?.id;

      final reports = await ReportsService().getReports(
        forceRefresh: true,
        profileId: apiProfileId,
      );

      // Fetch timeline to get report types
      try {
        final timeline = await ReportsService().getTimeline();
        final typeMap = <int, String>{};
        for (var item in timeline) {
          if (item['report_id'] != null && item['report_type'] != null) {
            typeMap[item['report_id']] = item['report_type'];
          }
        }
        if (mounted) {
          setState(() {
            _reportTypesMap = typeMap;
          });
        }
      } catch (e) {
        debugPrint('Failed to fetch timeline for types: $e');
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
          _error = null;
        });

        // Handle initial report navigation
        if (widget.initialReportId != null && !_hasHandledInitialReport) {
          final initialReport = _reports.where((r) => r.reportId == widget.initialReportId).firstOrNull;
          if (initialReport != null) {
            _hasHandledInitialReport = true;
            Future.microtask(() => _handleViewReport(initialReport));
          }
        }
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
        
        // Handle Access Verification Exception from actual API call
        if (e is AccessVerificationException) {
          setState(() {
            _reports = []; // Just show empty list, no error
            _isLoading = false;
          });
          return;
        }

        // If we have data, show snackbar instead of full error
        if (_reports.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update reports: $e')),
          );
          setState(() => _isLoading = false);
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

  Future<void> _showVerificationModal() async {
    // Show modal bottom sheet
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccessVerificationModal(
        resourceType: 'profile',
        resourceId: _selectedProfileId ?? 0,
      ),
    );

    if (result == true) {
      // Verified successfully, retry fetching
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _fetchReports();
    } else {
       // Cancelled/Failed
       if (_reports.isEmpty && mounted) {
          setState(() {
            _error = "Verification required to view reports";
            _isLoading = false;
          });
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
    "Lab Results",
    "Prescriptions",
    "Imaging",
    "Cardiology",
    "Neurology",
    "Orthopedic",
  ];

  @override
  void dispose() {
    ProfileStateService().profileNotifier.removeListener(_onProfileChanged);
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
      final isSelf = _selectedProfile == null || _selectedProfile?.relationship == 'Self';
      await ReportsService().deleteReport(int.parse(id), profileId: isSelf ? null : _selectedProfileId);
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
    // Priority 0: Use report_name if available
    if (report.reportName != null && report.reportName!.isNotEmpty) {
      return report.reportName!;
    }
    
    // Priority 1: Use report_type if available
    if (report.reportType != null && report.reportType!.isNotEmpty) {
      return report.reportType!;
    }

    // Priority 0: Check if we have the type from timeline
    if (_reportTypesMap.containsKey(report.reportId)) {
      final type = _reportTypesMap[report.reportId];
      if (type != null && type.isNotEmpty && type != 'General Report') {
        return type;
      }
    }

    // Priority 1: Check for explicit "Report Type" or "Test Name" fields
    final titleField = report.fields.firstWhere(
      (f) {
        final name = f.fieldName.toLowerCase().replaceAll('_', ' ');
        return name.contains('test name') ||
            name == 'report type' ||
            name == 'study' ||
            name == 'diagnosis' ||
            name.contains('examination') ||
            name.contains('investigation') ||
            name == 'title' ||
            name == 'name';
      },
      orElse: () =>
          ReportField(id: 0, fieldName: '', fieldValue: '', createdAt: ''),
    );

    if (titleField.fieldName.isNotEmpty) {
      return titleField.fieldValue;
    }

    // Keywords to look for in field names that might indicate a report title
    final titleKeywords = [
      'test name',
      'report type',
      'report name',
      'investigation',
      'procedure',
      'study',
      'examination',
      'exam',
      'diagnosis',
      'title',
      'type',
      'test',
    ];

    // Helper to check if a field name matches any keyword
    bool isTitleField(String fieldName) {
      final lower = fieldName.toLowerCase();
      return titleKeywords.any((k) => lower.contains(k));
    }

    // Priority 1: Check main fields
    try {
      final titleField = report.fields.firstWhere(
        (f) => isTitleField(f.fieldName),
      );
      return titleField.fieldValue;
    } catch (_) {}

    // Priority 2: Check additional fields
    try {
      final addTitleField = report.additionalFields.firstWhere(
        (f) => isTitleField(f.fieldName),
      );
      return addTitleField.fieldValue;
    } catch (_) {}

    // Priority 3: Heuristic - Look for the first field that looks like a title
    try {
      final candidate = report.fields.firstWhere((f) {
        final name = f.fieldName.toLowerCase();
        final value = f.fieldValue;

        // Skip common metadata
        if (name.contains('date') ||
            name.contains('time') ||
            name.contains('age') ||
            name.contains('sex') ||
            name.contains('gender'))
          return false;
        if (name.contains('patient') ||
            name.contains('doctor') ||
            name.contains('hospital') ||
            name.contains('id'))
          return false;

        // Skip numeric values
        if (double.tryParse(value) != null) return false;

        // Skip long text (notes)
        if (value.length > 50) return false;

        // Skip short text (abbreviations)
        if (value.length < 3) return false;

        return true;
      });
      return candidate.fieldValue;
    } catch (_) {}

    // Priority 4: Use Date and ID as a fallback
    try {
      final date = DateTime.parse(report.reportDate);
      return "Medical Report ${DateFormat('MMM d, y').format(date)}";
    } catch (_) {
      return "Medical Report ${report.reportDate}";
    }
  }

  Future<void> _handleViewReport(Report report) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final isSelf = _selectedProfile == null || _selectedProfile?.relationship == 'Self';
      final images = await ReportsService().getReportImages(report.reportId, profileId: isSelf ? null : _selectedProfileId);

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
        
        // Fail silently or show generic error if verification is actually blocked by backend
        if (e is AccessVerificationException) {
          return;
        }

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
        const SnackBar(
          content: Text('Preparing report for sharing...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Fetch fresh, full report details to ensure we have all extracted data
      Report fullReport = report;
      try {
        final isSelf = _selectedProfile == null || _selectedProfile?.relationship == 'Self';
        final fetched = await ReportsService().getReport(report.reportId, profileId: isSelf ? null : _selectedProfileId);
        if (fetched != null) {
          fullReport = fetched;
        }
      } catch (e) {
         if (e is AccessVerificationException) {
             debugPrint('Verification needed for full report details during share');
         }
        debugPrint('Could not fetch full report details, using list item: $e');
      }

      if (!mounted) return;

      // Generate formatted PDF using the same method as download
      final pdfFile = await _generatePdf(fullReport);
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        subject: 'Medical Report: ${_getReportTitle(report)}',
        text: 'Sharing medical report from HealthTrack',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Report shared successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            elevation: 8,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.xCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error sharing report: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            elevation: 8,
          ),
        );
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
      final title = _getReportTitle(report).toLowerCase();
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || 
                          (report.patientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                          report.reportDate.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filterType == "all" || report.reportCategory == _filterType;

      // Strict Profile Filtering
      // If we are on a specific profile, only show reports that belong to it
      // IF the report has a profileId.
      bool matchesProfile = true;
      if (_selectedProfileId != null) {
          if (report.profileId != null) {
             matchesProfile = report.profileId == _selectedProfileId;
          } else {
             // If report has no profile ID, assume it belongs to 'Self' (Owner)
             // So if we are strictly viewing a dependent (who should have IDs), hide it?
             // Or if we are viewing Self, show it.
             // Let's assume 'Self' has _selectedProfileId matching the owner.
             // If we are viewing a Dependent (who has a distinct ID), we don't want to see null-ID reports (Self's).
             // So: if _selectedProfileRelation != 'Self' AND report.profileId == null -> Hide
             if (_selectedProfileRelation != 'Self') {
                matchesProfile = false;
             }
          }
      }

      return matchesSearch && matchesFilter && matchesProfile;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : Colors.white,
      body: Stack(
        children: [
          // Background Gradient (Unified Black for Dark Mode)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0A1929),
                        const Color(0xFF0A1929),
                        const Color(0xFF0A1929),
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
            ? const Color(0xFF0F2137).withOpacity(0.9)
            : Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF0F2137) : Colors.grey[100]!,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProfileRelation == 'Self' || _selectedProfile == null
                              ? 'My Medical Reports'
                              : 'Medical Reports for ${_selectedProfile?.firstName ?? "Family Member"}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        if (_selectedProfileRelation != 'Self' && _selectedProfile != null)
                          Text(
                             'Viewing ${_selectedProfile!.firstName}\'s Records',
                             style: TextStyle(
                               fontSize: 12, 
                               color: const Color(0xFF39A4E6), 
                               fontWeight: FontWeight.w500
                             ),
                          )
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
                        color: isDark ? const Color(0xFF0F2137) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F2137)
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
                            ? const Color(0xFF0F2137)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showFilters || _filterType != 'all'
                              ? const Color(0xFF39A4E6)
                              : isDark
                              ? const Color(0xFF0F2137)
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchReports(silent: false),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final reports = _filteredReports;
    return RefreshIndicator(
      onRefresh: () => _fetchReports(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          if (reports.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 64,
                      color: Colors.grey[300],
                    ),
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
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Lab Results':
        return const Color(0xFF39A4E6); // Blue
      case 'Prescriptions':
        return const Color(0xFF10B981); // Emerald
      case 'Imaging':
        return const Color(0xFF8B5CF6); // Purple
      case 'Cardiology':
        return const Color(0xFFEF4444); // Red
      case 'Neurology':
        return const Color(0xFF6366F1); // Indigo
      case 'Orthopedic':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF39A4E6);
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Lab Results':
        return LucideIcons.flaskConical;
      case 'Prescriptions':
        return LucideIcons.pill;
      case 'Imaging':
        return LucideIcons.camera;
      case 'Cardiology':
        return LucideIcons.heart;
      case 'Neurology':
        return LucideIcons.brain;
      case 'Orthopedic':
        return LucideIcons.activity;
      default:
        return LucideIcons.fileText;
    }
  }

  Widget _buildReportCard(Report report, int index) {
    final isDark = _isDarkMode;
    final title = _getReportTitle(report);

    final categoryColor = _getCategoryColor(report.reportCategory);
    final categoryIcon = _getCategoryIcon(report.reportCategory);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF0F2137) : Colors.grey[100]!,
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
                    gradient: LinearGradient(
                      colors: [categoryColor, categoryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_selectedProfileRelation != null && _selectedProfileRelation != 'Self') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF39A4E6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.user, size: 10, color: Color(0xFF39A4E6)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedProfileRelation!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF39A4E6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (report.reportCategory != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  report.reportCategory!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (report.patientName != null &&
                          report.patientName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          report.patientName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              // Ensure valid date format or fallback
                              report.reportDate.contains('T') 
                                  ? report.reportDate.split('T')[0] 
                                  : report.reportDate.split(' ')[0], 
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
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
                const SizedBox(width: 8),
                _buildIconOnlyButton(
                  LucideIcons.share2,
                  () => _handleShareReport(report),
                ),
                const SizedBox(width: 8),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
              : (isDark ? const Color(0xFF0F2137) : const Color(0xFFF1F5F9)), // Navy blue for buttons
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
              color: isDark ? const Color(0xFF0F2137) : Colors.white,
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
        color: isDark ? const Color(0xFF0A1929) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF0F2137) : Colors.grey[300]!,
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

  String? _getFieldValue(String key, [Report? report]) {
    // If report is provided, use it. Otherwise, we can't access widget.report here because this method is in State class but widget.report is not available in all contexts or we need to be careful.
    // Actually, in _ReportsScreenState, we don't have widget.report. We have _reports list.
    // But wait, _getFieldValue was used in _ModernReportViewer which has widget.report.
    // I moved these methods to _ReportsScreenState, but they were originally in _ModernReportViewer or I am confusing contexts.

    if (report == null) return null;

    // Try to find in fields
    try {
      final field = report.fields.firstWhere(
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
      final addField = report.additionalFields.firstWhere(
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

  Future<void> _handleDownloadReport(Report report) async {
    try {
      // Request permissions
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Storage permission is required to save PDF'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }
        }
        // For Android 13+, FileSaver handles scoped storage automatically
      }

      if (!mounted) return;

      // Fetch fresh, full report details to ensure we have all extracted data
      // The list view might have a partial object
      Report fullReport = report;
      try {
        final fetched = await ReportsService().getReport(report.reportId);
        if (fetched != null) {
          fullReport = fetched;
        }
      } catch (e) {
        debugPrint('Could not fetch full report details, using list item: $e');
      }

      if (!mounted) return;

      // Generate PDF using existing helper
      final file = await _generatePdf(fullReport);
      final bytes = await file.readAsBytes();

      String fileName = 'MediScan_Report_${report.reportId}';
      if (report.reportDate.isNotEmpty) {
        // sanitize date for filename
        final dateStr =
            report.reportDate.split(' ')[0].replaceAll(RegExp(r'[^\w-]'), '_');
        fileName += '_$dateStr';
      }

      // Save file
      final path = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Report saved successfully',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            elevation: 8,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                OpenFile.open(path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating/saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _getSmartReportType([Report? report]) {
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
      final val = _getFieldValue(key, report);
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

  Future<File> _generatePdf(Report report) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await DefaultAssetBundle.of(context)
        .load("assets/fonts/Amiri-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    
    final fontBoldData = await DefaultAssetBundle.of(context)
        .load("assets/fonts/Amiri-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);

    // Load Logo
    final logoData = await DefaultAssetBundle.of(context)
        .load("assets/images/logo_3.png");
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Filter fields like in the UI
    final validFields = report.fields.where((f) {
      return f.fieldValue.trim().isNotEmpty &&
          f.fieldValue.toLowerCase() != 'n/a' &&
          f.fieldValue.toLowerCase() != 'null' &&
          f.fieldValue.toLowerCase() != 'none';
    }).toList();

    // App Brand Color
    final brandColor = PdfColor.fromInt(0xFF39A4E6);
    final lightBrandColor = PdfColor.fromInt(0xFFE0F2FE); // Very light blue

    // Get Data - STRICTLY from extracted fields
    String displayDate = _getFieldValue('collection date', report) ??
        _getFieldValue('sample date', report) ??
        _getFieldValue('specimen date', report) ??
        _getFieldValue('examination date', report) ??
        _getFieldValue('result date', report) ??
        _getFieldValue('report date', report) ??
        _getFieldValue('date', report) ??
        ''; 

    // Only fallback to metadata date if absolutely no date found in text
    if (displayDate.isEmpty) {
       // If the metadata date looks different from "just now" (upload time), it might be valid. 
       // But user specifically said "from the report". 
       // We'll keep report.reportDate as a last resort but try to format it nicely.
       displayDate = report.reportDate;
    }
    
    // Normalize date
    if (displayDate.isNotEmpty) {
       try {
         if (displayDate.contains('T')) {
           displayDate = displayDate.split('T')[0];
         } else if (displayDate.contains(' ')) {
           if (displayDate.length > 12) { // Likely has time
              displayDate = displayDate.split(' ')[0];
           }
         }
         // Remove any non-date characters if needed, or keeping it simple
       } catch (_) {}
    }

    // Helper for RTL Text
    pw.TextDirection getTextDirection(String text) {
      return RegExp(r'[\u0600-\u06FF]').hasMatch(text)
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr;
    }

    // Patient Name
    final patientName =
        report.patientName != null && report.patientName!.toLowerCase() != 'unknown' && report.patientName!.isNotEmpty
        ? report.patientName!
        : (_getFieldValue('patient name', report) ??
        _getFieldValue('patient', report) ??
        _getFieldValue('name', report) ??
        _getFieldValue('full name', report) ??
        _currentUser?.fullName ??
        'Not Specified');
    
    // Additional Patient Info
    final dob = _getFieldValue('dob', report) ?? _getFieldValue('date of birth', report) ?? _getFieldValue('birth date', report);
    final age = report.patientAge?.toString() ?? _getFieldValue('age', report);
    final gender = report.patientGender ?? _getFieldValue('gender', report) ?? _getFieldValue('sex', report);

    String patientDetails = '';
    if (age != null) patientDetails += 'Age: $age';
    if (gender != null) patientDetails += (patientDetails.isNotEmpty ? '  •  ' : '') + gender;
    if (dob != null) patientDetails += (patientDetails.isNotEmpty ? '\n' : '') + 'DOB: $dob';


    final doctorName = _getFieldValue('doctor', report) ??
        _getFieldValue('doctor name', report);
    final hospitalName = _getFieldValue('hospital', report) ??
        _getFieldValue('clinic', report);
    
    // Determine report title using standard application logic (prioritizes backend report_name)
    String reportTitle = _getReportTitle(report);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: ttf,
        ),
        build: (pw.Context context) {
          return [
            // Header with Logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logoImage, width: 40, height: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'MediScan',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: brandColor,
                        font: ttf,
                      ),
                    ),
                    pw.Text(
                      'Personal Medical Record',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                        font: ttf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: brandColor, thickness: 2),
            pw.SizedBox(height: 20),

            // Report Title & Meta
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MEDICAL REPORT',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      reportTitle,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                        font: ttf,
                      ),
                    ),
                  ],
                )),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: lightBrandColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DATE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: brandColor,
                          font: ttf,
                        ),
                      ),
                      pw.Text(
                        displayDate,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                          font: ttf,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Patient & Doctor Info Grid
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PATIENT', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold, font: ttfBold)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          patientName,
                          textDirection: getTextDirection(patientName),
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                        ),
                        if (patientDetails.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                             patientDetails,
                             textDirection: getTextDirection(patientDetails),
                             style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: ttf),
                          ),
                        ]
                      ],
                    ),
                  ),
                  if (doctorName != null && doctorName.isNotEmpty && doctorName.toLowerCase() != 'n/a')
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DOCTOR', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold, font: ttfBold)),
                        pw.SizedBox(height: 4),
                         pw.Text(
                          doctorName,
                          textDirection: getTextDirection(doctorName),
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                        ),
                      ],
                    ),
                  ),
                  if (hospitalName != null && hospitalName.isNotEmpty && hospitalName.toLowerCase() != 'n/a')
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('HOSPITAL/CLINIC', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold, font: ttfBold)),
                        pw.SizedBox(height: 4),
                         pw.Text(
                          hospitalName,
                          textDirection: getTextDirection(hospitalName),
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            if (validFields.isNotEmpty) ...[
              pw.Text(
                'EXTRACTED RESULTS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: brandColor,
                  font: ttf,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
                headerDecoration: pw.BoxDecoration(
                  color: lightBrandColor,
                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                ),
                headerStyle: pw.TextStyle(
                  color: brandColor,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey800,
                  font: ttf,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                data: <List<String>>[
                  <String>['TEST NAME', 'VALUE', 'UNIT', 'RANGE', 'STATUS'],
                  ...validFields.map(
                    (field) => [
                      _formatFieldName(field.fieldName),
                      field.fieldValue,
                      field.fieldUnit ?? '-',
                      field.normalRange ?? '-',
                      field.isNormal == true ? 'Normal' : (field.isNormal == false ? 'Abnormal' : '-'),
                    ],
                  ),
                ],
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                },
              ),
            ] else
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'No extracted data available for this report.',
                    style: pw.TextStyle(color: PdfColors.grey600, font: ttf),
                  ),
                ),
              ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by MediScan',
                  style: pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 8,
                    font: ttf,
                  ),
                ),
                pw.Text(
                  'Report ID: #${report.reportId}',
                  style: pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 8,
                    font: ttf,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    
    // Professional Filename Generation
    String safePatientName = patientName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    String safeReportTitle = reportTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    String formattedDate = displayDate.replaceAll(RegExp(r'[^\d-]'), '');
    if (formattedDate.isEmpty) formattedDate = DateTime.now().toString().split(' ')[0];
    
    final fileName = 'MediScan_${safeReportTitle}_${safePatientName}_$formattedDate.pdf';
    final file = File('${output.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
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

  User? _currentUser;
  Report? _fetchedReport;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);
    _loadUserProfile();
    _loadReportDetails();

    // Start staggered loading: Only load the first file initially
    // Subsequent files will be triggered in _loadFile success callback
    if (widget.images.isNotEmpty) {
      _loadFile(0);
    }
  }

  Future<void> _loadReportDetails() async {
    if (mounted) setState(() => _isLoadingDetails = true);
    try {
      final report = await ReportsService().getReport(widget.report.reportId);
      if (mounted) {
        setState(() {
           _fetchedReport = report;
        });
      }
    } catch (e) {
      debugPrint('Error fetching report details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // Try to load from prefs first
      final user = await User.loadFromPrefs();
      if (user != null) {
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      } else {
        // Fetch from API if not in prefs
        final fetchedUser = await UserService().getUserProfile();
        if (mounted) {
          setState(() {
            _currentUser = fetchedUser;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  int? _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    try {
      DateTime birthDate;
      try {
        birthDate = DateTime.parse(dob);
      } catch (_) {
        // Try parsing "D Mon YYYY" format (e.g., "9 Dec 2025")
        final parts = dob.split(' ');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final monthStr = parts[1];
          final year = int.parse(parts[2]);
          final months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final month = months.indexOf(monthStr) + 1;
          if (month > 0) {
            birthDate = DateTime(year, month, day);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }

      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
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
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final imageMap = widget.images[index];
        final backendIndex = imageMap['index'] as int?;
        final fileIndex = backendIndex ?? (index + 1);

        // Debug log to confirm which index we are trying to load
        debugPrint('ReportViewer: _loadFile called for index $index. backendIndex: $backendIndex, using fileIndex: $fileIndex');

        // Use download_url from backend if available, otherwise construct it
        String relativeUrl = imageMap['download_url'] as String? ?? '';
        if (relativeUrl.isEmpty) {
          relativeUrl = '${ApiConfig.reports}/${widget.report.reportId}/images/$fileIndex';
        }

        final url = '${ApiConfig.baseUrl}$relativeUrl';
        final token = await ApiClient.instance.getToken();

        final dir = await getTemporaryDirectory();
        final filename = imageMap['filename'] as String? ?? 'file_$fileIndex';
        bool isPdfFromFilename = _isPdf(filename);
        final extension = isPdfFromFilename ? 'pdf' : 'jpg';

        // Deterministic filename for caching
        final String localFileName = 'report_${widget.report.reportId}_file_$fileIndex.$extension';
        final file = File('${dir.path}/$localFileName');

        // CACHE CHECK: If file exists and is not empty, use it
        if (await file.exists()) {
          final stat = await file.stat();
          if (stat.size > 0) {
            debugPrint('ReportViewer: Using CACHED file for index $index: ${file.path}');
            if (mounted) {
              setState(() {
                _localFilePaths[index] = file.path;
                _isPdfMap[index] = isPdfFromFilename;
                _isDownloading[index] = false;
              });

              // TRIGGER STAGGERED LOADING for next page
              if (index + 1 < widget.images.length && !_isDownloading.containsKey(index + 1) && !_localFilePaths.containsKey(index + 1)) {
                _loadFile(index + 1);
              }
            }
            return;
          }
        }

        debugPrint('ReportViewer: Fetching index $index from $url');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            // Removed 'Connection': 'close' to avoid drops
          },
        ).timeout(const Duration(seconds: 45)); // Increased timeout for PDF/slow connections

        if (response.statusCode == 200) {
          bool isPdf = isPdfFromFilename;
          final contentType = response.headers['content-type'];
          if (contentType != null) {
            if (contentType.toLowerCase().contains('application/pdf')) {
              isPdf = true;
            } else if (contentType.toLowerCase().contains('image/')) {
              isPdf = false;
            }
          }

          await file.writeAsBytes(response.bodyBytes);

          // Verify file size
          if (response.bodyBytes.isEmpty) {
            throw Exception('Downloaded file is empty');
          }

          if (mounted) {
            debugPrint('ReportViewer: SUCCESS loaded index $index from $url');
            setState(() {
              _localFilePaths[index] = file.path;
              _isPdfMap[index] = isPdf;
              _isDownloading[index] = false;
            });

            // Pre-load next page to improve UX
            if (index + 1 < widget.images.length) {
              _loadFile(index + 1);
            }
          }
          return; // Success
        } else {
          debugPrint('ReportViewer: Failed to load index $index. Status code: ${response.statusCode}');
          if (response.statusCode == 404) {
            throw Exception('File not found (404) for index $index at $url');
          }
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint(
          'ReportViewer: Error downloading file (attempt ${retryCount + 1}): $e',
        );
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

  String? _getFieldValue(String key, [Report? report]) {
    final targetReport = report ?? widget.report;
    final normalizedKey = key.toLowerCase().replaceAll('_', ' ');

    // Try to find in fields
    try {
      final field = targetReport.fields.firstWhere(
        (f) => f.fieldName
            .toLowerCase()
            .replaceAll('_', ' ')
            .contains(normalizedKey),
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
      final addField = targetReport.additionalFields.firstWhere(
        (f) => f.fieldName
            .toLowerCase()
            .replaceAll('_', ' ')
            .contains(normalizedKey),
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

    // Heuristic: Guess report type based on common fields
    final fieldNames = widget.report.fields
        .map((f) => f.fieldName.toLowerCase())
        .toList();

    if (fieldNames.any((n) => n.contains('hemoglobin') || n.contains('hgb')) &&
        fieldNames.any((n) => n.contains('wbc') || n.contains('white blood'))) {
      return 'Complete Blood Count (CBC)';
    }

    if (fieldNames.any(
      (n) =>
          n.contains('cholesterol') || n.contains('ldl') || n.contains('hdl'),
    )) {
      return 'Lipid Panel';
    }

    if (fieldNames.any(
      (n) =>
          n.contains('glucose') ||
          n.contains('creatinine') ||
          n.contains('sodium'),
    )) {
      return 'Metabolic Panel';
    }

    if (fieldNames.any(
      (n) => n.contains('tsh') || n.contains('t3') || n.contains('t4'),
    )) {
      return 'Thyroid Function Test';
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
          ? const Color(0xFF0A1929)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F2137) : Colors.white,
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
            Tab(text: 'Original Document'),
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

          ReportContentWidget(
            isDarkMode: isDark,
            patientName: (_fetchedReport?.patientName != null &&
                    _fetchedReport!.patientName!.isNotEmpty &&
                    _fetchedReport!.patientName!.toLowerCase() != 'unknown')
                ? _fetchedReport!.patientName!
                : (widget.report.patientName != null &&
                        widget.report.patientName!.isNotEmpty &&
                        widget.report.patientName!.toLowerCase() != 'unknown')
                    ? widget.report.patientName!
                    : (_getFieldValue('patient name') ??
                        _getFieldValue('name') ??
                        _currentUser?.fullName ??
                        'Unknown'),
            patientAge: (_fetchedReport?.patientAge ??
                    widget.report.patientAge ??
                    _getFieldValue('age') ??
                    _calculateAge(_currentUser?.dateOfBirth) ??
                    0)
                .toString(),
            patientGender: _fetchedReport?.patientGender ??
                widget.report.patientGender ??
                _getFieldValue('gender') ??
                _getFieldValue('sex') ??
                _currentUser?.gender ??
                "Unknown",
            // Helper mapping for ReportField -> TestResult
            results: validFields.map((f) {
              return TestResult(
                name: _formatFieldName(f.fieldName),
                value: f.fieldValue,
                unit: f.fieldUnit ?? '',
                normalRange: f.normalRange ?? '',
                status: f.isNormal == true
                    ? 'normal'
                    : (f.isNormal == false ? 'abnormal' : 'normal'),
                category: f.category,
              );
            }).toList(),
            reportType: widget.report.reportType ??
                _getSmartReportType() ??
                'General Report',
            reportDate: widget.report.reportDate,
            doctorName: _getFieldValue('doctor'),
            hospitalName: _getFieldValue('hospital'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer(bool isDark) {
    final images = widget.images;

    // Determine if current visible file is a PDF to hide the slider dots
    final currentImageMap = images.isNotEmpty ? images[_currentIndex] : null;
    final currentFilename = currentImageMap?['filename'] as String? ?? '';
    final isCurrentPdf = _isPdfMap[_currentIndex] ?? _isPdf(currentFilename);

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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading document ${index + 1} of ${images.length}...',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
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
                        fontWeight: FontWeight.bold,
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
              return _PdfViewerPage(
                filePath: localPath, 
                isDark: isDark,
                isMultiFile: images.length > 1,
              );
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
        // Dots indicator for multiple files (Images only as per user request)
        if (images.length > 1 && !isCurrentPdf)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: images.length,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: const Color(0xFF39A4E6),
                    dotColor: Colors.white38,
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
          ),
      ],
    );
  }

  // Unused helpers removed
}

class _PdfViewerPage extends StatefulWidget {
  final String filePath;
  final bool isDark;
  final bool isMultiFile;

  const _PdfViewerPage({
    required this.filePath,
    required this.isDark,
    this.isMultiFile = false,
    Key? key,
  }) : super(key: key);

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
        if (_ready && _totalPages > 1)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
