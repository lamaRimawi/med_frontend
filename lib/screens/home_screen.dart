import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/theme_toggle.dart';
import '../widgets/next_gen_background.dart';
import '../widgets/animated_bubble_background.dart';
import '../models/user_model.dart';
// import 'medical_record_screen.dart'; // Removed
import 'camera_upload_screen.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import 'profile_screen.dart';
import 'family_management_screen.dart'; // Added
import 'timeline_screen.dart';
import 'reports_screen.dart';
import '../widgets/report_type_badge.dart';
import '../widgets/modern_bottom_nav_bar.dart';
import '../widgets/web_navbar.dart';
import '../widgets/web_dashboard_view.dart';
import '../widgets/web_profile_view.dart';
import '../widgets/web_reports_view.dart';
import '../widgets/web_timeline_view.dart';
import '../widgets/web_camera_upload_view.dart';
import '../services/user_service.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../widgets/profile_selector.dart';
import '../services/profile_state_service.dart';
import '../models/notification_model.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  bool get _isDarkMode {
    final themeProvider = ThemeProvider.of(context);
    return themeProvider?.themeMode == ThemeMode.dark;
  }

  String _searchQuery = '';
  bool _isSearchFocused = false;
  bool _showNotifications = false;
  String? _selectedAction;
  String? _selectedReportType;
  String _activeTab = 'home';
  bool _showProfile = false;
  // bool _showRecords = false; // Removed
  bool _showReports = false;
  bool _showTimeline = false;
  bool _showVaccinations = false;
  bool _showCameraUpload = false;
  Map<String, String>? _showQuickView;
  bool _showFavorites = false;
  bool _showAnalytics = false;
  bool _showShareModal = false;
  bool _showAllReportTypes = false;
  List<InAppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;
  Timer? _notificationRefreshTimer;
  int _selectedDate = 11;
  User? _currentUser;
  int? _selectedProfileId;
  String? _selectedProfileRelation;
  int? _initialReportId;

  // Recent reports data
  List<Map<String, dynamic>> _dates = [];
  List<Map<String, dynamic>> _reports = [];
  bool _isLoadingReports = true;
  Map<int, String> _reportTypesMap = {};

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _loadUserData();
    _initializeDates();
    _loadReports();
    _loadNotifications();
    // Listen for real-time foreground notifications
    NotificationService().onMessage.listen((_) => _loadNotifications());
    // Periodic refresh for timestamps
    _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _showNotifications) {
        setState(() {}); // Re-render to update relative time labels (e.g. "Now" -> "1s ago")
      }
    });
    // Listen to profile changes
    ProfileStateService().profileNotifier.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileStateService().profileNotifier.removeListener(_onProfileChanged);
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  void _onProfileChanged() {
    final profile = ProfileStateService().profileNotifier.value;
    if (mounted) {
      setState(() {
        _selectedProfileId = profile?.id;
        _selectedProfileRelation = profile?.relationship;
        _isLoadingReports = true;
      });
      _loadReports();
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (_isLoadingNotifications) return;
    setState(() => _isLoadingNotifications = true);
    try {
      final notificationsData = await ApiClient.instance.getNotifications();
      debugPrint('Notifications API Response: $notificationsData');
      if (mounted) {
        setState(() {
          _notifications = notificationsData
              .map((n) => InAppNotification.fromJson(n))
              .toList();
          _unreadCount = _notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> _markAllAsRead() async {
    for (var n in _notifications.where((n) => !n.isRead)) {
      await ApiClient.instance.markNotificationAsRead(n.id);
    }
    _loadNotifications();
  }

  Future<void> _initializeProfile() async {
    // Initialize default profile if none is selected
    await ProfileStateService().initializeDefaultProfile();
    // Load the selected profile
    final selectedProfile = await ProfileStateService().getSelectedProfile();
    if (mounted) {
      setState(() {
        _selectedProfileId = selectedProfile?.id;
        _selectedProfileRelation = selectedProfile?.relationship;
      });
    }
  }

  Future<void> _loadReports() async {
    try {
      // 1. Load from cache first
      final cached = ReportsService().cachedReports;
      if (cached != null) {
        _mapReportsToUi(cached);
        setState(() => _isLoadingReports = false);
      }

      // 2. Fetch fresh
      final isSelf = _selectedProfileRelation == 'Self' || _selectedProfileId == null;
      final reports = await ReportsService().getReports(
        profileId: isSelf ? null : _selectedProfileId,
      );

      // 3. Fetch timeline for better names
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
        _mapReportsToUi(reports);
        setState(() => _isLoadingReports = false);
      }
    } catch (e) {
      debugPrint('Error loading home reports: $e');
      if (e.toString().contains('Unauthorized')) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        return;
      }
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  String _getReportTitle(Report report) {
    // Priority -1: Use report_name if available (Highest Priority)
    if (report.reportName != null && report.reportName!.isNotEmpty) {
      return report.reportName!;
    }

    // Priority 0: Check if we have the type from timeline
    if (_reportTypesMap.containsKey(report.reportId)) {
      final type = _reportTypesMap[report.reportId];
      if (type != null && type.isNotEmpty && type != 'General Report') {
        return type;
      }
    }

    // Priority 1: Check explicit report type from backend
    if (report.reportType != null &&
        report.reportType!.isNotEmpty &&
        report.reportType!.toLowerCase() != 'general' &&
        report.reportType!.toLowerCase() != 'other') {
      return report.reportType!;
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

    // Priority 4: Fallback to first field name (e.g. "WBC") if no better title found
    if (report.fields.isNotEmpty) {
      return report.fields.first.fieldName;
    }

    return "Medical Report";
  }

  void _mapReportsToUi(List<Report> reports) {
    _reports = reports.where((r) {
      // Strict Profile Filtering
      if (_selectedProfileId != null) {
        if (r.profileId != null) {
          return r.profileId == _selectedProfileId;
        } else {
          // If report has no profile ID, assume it belongs to 'Self' (Owner)
          return _selectedProfileRelation == 'Self';
        }
      }
      return true;
    }).map((r) {
      // Parse date
      DateTime dt;
      try {
        dt = DateTime.parse(r.createdAt);
      } catch (_) {
        dt = DateTime.now();
      }

      // Attempt to find doctor
      String doctor = '';
      final docField = r.additionalFields.firstWhere(
        (f) =>
            f.fieldName.toLowerCase().contains('doctor') ||
            f.category.toLowerCase() == 'doctor',
        orElse: () => AdditionalField(
          id: -1,
          fieldName: '',
          fieldValue: '',
          category: '',
        ),
      );
      if (docField.id != -1) doctor = docField.fieldValue;

      // Determine status
      final allNormal = r.fields.every((f) => f.isNormal ?? true);
      final status = allNormal ? 'Normal' : 'Attention';

      // Title - use robust logic
      String title = _getReportTitle(r);

      // Clean up title if it's too long
      if (title.length > 30) title = title.substring(0, 27) + '...';

      return {
        'id': '${r.reportId}',
        'day': '${dt.day}',
        'date':
            '${dt.day} ${_getMonthName(dt.month)} - ${_getDayName(dt.weekday)}',
        'time': (dt.hour == 0 && dt.minute == 0)
            ? ''
            : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        'title': title,
        'doctor': doctor,
        'status': status,
        'type': _determineReportType(r),
      };
    }).toList();
  }

  Future<void> _loadUserData() async {
    try {
      // Try to load from server first
      final userService = UserService();
      final user = await userService.getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Fallback to local storage if server fails
      final user = await User.loadFromPrefs();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }

  void _initializeDates() {
    final now = DateTime.now();
    _selectedDate = now.day;

    // Generate 5 days centered on today
    _dates = List.generate(5, (index) {
      final date = now.subtract(Duration(days: 2 - index));
      return {'day': date.day, 'label': _getDayLabel(date)};
    });
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
    ];
    // Adjust index based on standard weekday (1=Mon, 7=Sun)
    // My array starts with Wed? No, let's use standard.
    const standardDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return standardDays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  void _toggleTheme() {
    ThemeProvider.of(context)?.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCameraUpload && !kIsWeb) {
      return CameraUploadScreen(
        isDarkMode: _isDarkMode,
        onClose: () async {
          setState(() {
            _showCameraUpload = false;
            _activeTab = 'home';
            _selectedIndex = 0;
            _isLoadingReports = true; // Show loading immediately
          });
          // Small delay to allow backend to finish processing/indexing
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadReports();
        },
      );
    }

    Widget body;
    if (_showProfile) {
      body = ProfileScreen(
        onLogout: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        },
        onNavigate: (route) {
          setState(() {
            _showProfile = false;
            _activeTab = 'home';
            _selectedIndex = 0;
          });
          _loadUserData(); // Refresh user data (name, etc.) on Home
        },
      );
    } else if (_showReports) {
      body = ReportsScreen(
        initialReportId: _initialReportId,
        onBack: () => setState(() {
          _showReports = false;
          _activeTab = 'home';
          _selectedIndex = 0;
          _initialReportId = null; // Reset after coming back
        }),
      );
    } else if (_showTimeline) {
      body = TimelineScreen(
        onBack: () => setState(() {
          _showTimeline = false;
          _activeTab = 'home';
          _selectedIndex = 0;
        }),
        isDarkMode: _isDarkMode,
      );
    } else if (_showCameraUpload) {
      body = WebCameraUploadView(
        isDarkMode: _isDarkMode,
        onClose: () async {
          setState(() {
            _showCameraUpload = false;
            _activeTab = 'home';
            _selectedIndex = 0;
            _isLoadingReports = true;
          });
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadReports();
        },
      );
      // } else if (_showRecords) {
      //   body = MedicalRecordScreen(
      //     onBack: () => setState(() {
      //       _showRecords = false;
      //       _activeTab = 'home';
      //     }),
      //   );
    } else {
      body = Stack(
        children: [
          // Animated Background removed

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildRecentReports(),
                        _buildReportTypes(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notifications Panel
          if (_showNotifications) _buildNotificationsPanel(),

          // Quick View Modal
          if (_showQuickView != null) _buildQuickViewModal(),

          // All Report Types Modal
          if (_showAllReportTypes) _buildAllReportTypesModal(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (constraintsContext, constraints) {
        final bool isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: _isDarkMode
                ? const Color(0xFF0A1929)
                : const Color(0xFFF9FAFB),
            body: NextGenBackground(
              isDarkMode: _isDarkMode,
              child: Column(
                children: [
                  WebNavbar(
                    selectedIndex: _selectedIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _showProfile = index == 4;
                        _showReports = index == 1;
                        _showTimeline = index == 3;
                        _showCameraUpload = index == 2;
                        // _showRecords = false;
                      });
                    },
                    user: _currentUser,
                    isDarkMode: _isDarkMode,
                    unreadCount: _unreadCount,
                    onToggleNotifications: () => setState(
                      () => _showNotifications = !_showNotifications,
                    ),
                    onLogout: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    onToggleTheme: () =>
                        ThemeProvider.of(context)?.toggleTheme(),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showReports
                          ? WebReportsView(
                              isDarkMode: _isDarkMode,
                              onBack: () =>
                                  setState(() => _showReports = false),
                            )
                          : _showTimeline
                          ? WebTimelineView(
                              isDarkMode: _isDarkMode,
                              onBack: () =>
                                  setState(() => _showTimeline = false),
                            )
                          : _showProfile
                          ? WebProfileView(
                              isDarkMode: _isDarkMode,
                              onLogout: () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              ),
                              onProfileUpdated: () => _loadUserData(),
                            )
                          : _showCameraUpload
                          ? WebCameraUploadView(
                              isDarkMode: _isDarkMode,
                              onClose: () async {
                                setState(() => _showCameraUpload = false);
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                                _loadReports();
                              },
                            )
                          : WebDashboardView(
                              user: _currentUser,
                              isDarkMode: _isDarkMode,
                              searchQuery: _searchQuery,
                              onSearchChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              reports: _reports,
                              unreadCount: _unreadCount,
                              onUploadTap: () =>
                                  setState(() => _showCameraUpload = true),
                              onToggleNotifications: () => setState(
                                () => _showNotifications = !_showNotifications,
                              ),
                              showNotifications: _showNotifications,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _isDarkMode
              ? const Color(0xFF0A1929)
              : const Color(0xFFF9FAFB),
          extendBody: true,
          body: body,
          bottomNavigationBar: ModernBottomNavBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                // Reset all flags first
                _showProfile = false;
                _showReports = false;
                _showTimeline = false;
                // _showRecords = false;
                _showCameraUpload = false;

                // Set active flag
                if (index == 1) {
                  _showReports = true;
                } else if (index == 3) {
                  _showTimeline = true;
                } else if (index == 4) {
                  _showProfile = true;
                }
              });
            },
            onCameraTap: () => setState(() => _showCameraUpload = true),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Welcome Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.fullName.toUpperCase() ?? 'USER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    if (_selectedProfileRelation != null && _selectedProfileRelation != 'Self')
                      Text(
                        'Viewing ${_selectedProfileRelation}\'s Records',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF39A4E6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              // Theme Toggle Button
              GestureDetector(
                onTap: _toggleTheme,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0F2137) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                      color: const Color(0xFF39A4E6),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Notification Button
              GestureDetector(
                onTap: () =>
                    setState(() => _showNotifications = !_showNotifications),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0F2137) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          LucideIcons.bell,
                          color: Color(0xFF39A4E6),
                          size: 20,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4B4B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF0F2137) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearchFocused
                ? const Color(0xFF39A4E6)
                : (_isDarkMode
                      ? const Color(0xFF0F2137)
                      : const Color(0xFFE5E7EB)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                onTap: () => setState(() => _isSearchFocused = true),
                onSubmitted: (_) => setState(() => _isSearchFocused = false),
                decoration: InputDecoration(
                  hintText: 'Search reports, doctors...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() {
                  _searchQuery = '';
                  _isSearchFocused = false;
                }),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF0F2137)
                        : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    final isSearching = _searchQuery.isNotEmpty;

    final filtered = isSearching
        ? _reports.where((r) {
            final query = _searchQuery.toLowerCase();
            final title = (r['title'] ?? '').toLowerCase();
            final doctor = (r['doctor'] ?? '').toLowerCase();
            final type = (r['type'] ?? '').toLowerCase();
            return title.contains(query) ||
                doctor.contains(query) ||
                type.contains(query);
          }).toList()
        : _reports
              .where((r) => int.tryParse(r['day'] ?? '') == _selectedDate)
              .toList();

    Color textOnBlue = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSearching ? 'Search Results' : 'Recent Reports',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isSearching)
                  Text(
                    'Month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingReports)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else ...[
              // Date selector (Only show if not searching)
              if (!isSearching) ...[
                SizedBox(
                  height: 72,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final idx = _dates.indexWhere(
                              (d) => d['day'] == _selectedDate,
                            );
                            if (idx > 0)
                              _selectedDate = _dates[idx - 1]['day'] as int;
                          });
                        },
                        icon: const Icon(
                          LucideIcons.chevronLeft,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) {
                            final d = _dates[i];
                            final isSel = d['day'] == _selectedDate;
                            return GestureDetector(
                              onTap: () => setState(
                                () => _selectedDate = d['day'] as int,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${d['day']}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isSel
                                            ? const Color(0xFF39A4E6)
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${d['label']}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSel
                                            ? const Color(0xFF39A4E6)
                                            : Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _dates.length,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final idx = _dates.indexWhere(
                              (d) => d['day'] == _selectedDate,
                            );
                            if (idx < _dates.length - 1)
                              _selectedDate = _dates[idx + 1]['day'] as int;
                          });
                        },
                        icon: const Icon(
                          LucideIcons.chevronRight,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              // Header for reports count and "See all"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'report' : 'reports'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showReports = true;
                      _selectedIndex = 1;
                    }),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Column(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      size: 40,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSearching
                          ? 'No matching reports found'
                          : 'No reports for this date',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      isSearching
                          ? 'Try a different search term'
                          : 'Select another day to view reports',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < filtered.length; i++)
                      GestureDetector(
                        onTap: () {
                          final typeKey = (filtered[i]['type'] ?? '')
                              .toLowerCase()
                              .replaceAll(' ', '');
                          setState(() {
                            _showQuickView = {
                              'type': typeKey,
                              'title': filtered[i]['type'] ?? '',
                            };
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: i == filtered.length - 1 ? 0 : 12,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF39A4E6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          filtered[i]['date'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (_selectedProfileRelation != null &&
                                            _selectedProfileRelation !=
                                                'Self') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF39A4E6,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  LucideIcons.user,
                                                  size: 8,
                                                  color: Color(0xFF39A4E6),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _selectedProfileRelation!,
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF39A4E6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if ((filtered[i]['time'] ?? '')
                                            .isNotEmpty) ...[
                                          Text(
                                            filtered[i]['time'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            filtered[i]['title'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if ((filtered[i]['doctor'] ?? '')
                                            .isNotEmpty) ...[
                                          Flexible(
                                            child: Text(
                                              filtered[i]['doctor'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        ReportTypeBadge(
                                          type:
                                              filtered[i]['type'] ?? 'General',
                                          variant: ReportBadgeVariant.compact,
                                          size: BadgeSize.sm,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(
    String title,
    String doctor,
    String date,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Normal'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Normal'
                        ? Colors.green[100]
                        : Colors.orange[100],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            doctor,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isGood = status.contains('Normal') || status.contains('Clear');
    final isScheduled = status.contains('Scheduled');
    final Color bg = isGood
        ? const Color(0x3334D399)
        : (isScheduled ? const Color(0x332B8FD9) : const Color(0x33F59E0B));
    final Color fg = isGood
        ? const Color(0xFFDCFCE7)
        : (isScheduled ? const Color(0xFFDBEAFE) : const Color(0xFFFDE68A));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _determineReportType(Report r) {
    if (r.reportCategory != null && r.reportCategory!.isNotEmpty) {
      return r.reportCategory!;
    }
    String type = 'General';

    // Try to find a matching field in additionalFields
    final typeField = r.additionalFields.firstWhere(
      (f) =>
          f.fieldName.toLowerCase() == 'type' ||
          f.category.toLowerCase() == 'type',
      orElse: () =>
          AdditionalField(id: -1, fieldName: '', fieldValue: '', category: ''),
    );

    if (typeField.id != -1) {
      type = typeField.fieldValue;
    }

    // Normalize type string
    final typeLower = type.toLowerCase();
    if (typeLower.contains('lab') || typeLower.contains('blood'))
      return 'Lab Results';
    if (typeLower.contains('prescription') || typeLower.contains('medication'))
      return 'Prescriptions';
    if (typeLower.contains('imaging') ||
        typeLower.contains('x-ray') ||
        typeLower.contains('scan'))
      return 'Imaging';
    if (typeLower.contains('vital')) return 'Vitals';
    if (typeLower.contains('pathology')) return 'Pathology';
    if (typeLower.contains('cardio')) return 'Cardiology';
    if (typeLower.contains('neuro')) return 'Neurology';
    if (typeLower.contains('ortho')) return 'Orthopedic';
    if (typeLower.contains('temp')) return 'Temperature';
    if (typeLower.contains('resp')) return 'Respiratory';

    return 'General';
  }

  List<Map<String, dynamic>> _getReportTypes() {
    // Calculate counts from cached reports
    final counts = <String, int>{};
    final allReports = ReportsService().cachedReports ?? [];

    for (var r in allReports) {
      final type = _determineReportType(r);
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return [
      {
        'icon': LucideIcons.flaskConical,
        'label': 'Lab Results',
        'color': const Color(0xFF39A4E6),
        'count': counts['Lab Results'] ?? 0,
        'quickView': 'lab',
        'description': 'Blood tests & diagnostics',
      },
      {
        'icon': LucideIcons.pill,
        'label': 'Prescriptions',
        'color': const Color(0xFF10B981),
        'count': counts['Prescriptions'] ?? 0,
        'quickView': 'prescription',
        'description': 'Medication history',
      },
      {
        'icon': LucideIcons.camera,
        'label': 'Imaging',
        'color': const Color(0xFF8B5CF6),
        'count': counts['Imaging'] ?? 0,
        'quickView': 'imaging',
        'description': 'X-rays, MRI, CT scans',
      },
      {
        'icon': LucideIcons.heart,
        'label': 'Cardiology',
        'color': const Color(0xFFEF4444),
        'count': counts['Cardiology'] ?? 0,
        'quickView': 'cardiology',
        'description': 'Heart health',
      },
      {
        'icon': LucideIcons.brain,
        'label': 'Neurology',
        'color': const Color(0xFF6366F1),
        'count': counts['Neurology'] ?? 0,
        'quickView': 'neurology',
        'description': 'Brain & nerves',
      },
      {
        'icon': LucideIcons.activity,
        'label': 'Orthopedic',
        'color': const Color(0xFFF59E0B),
        'count': counts['Orthopedic'] ?? 0,
        'quickView': 'orthopedic',
        'description': 'Bones & joints',
      },
    ];
  }

  Widget _buildReportTypes() {
    final reportTypes = _getReportTypes();
    // Show top 6 on main screen
    final displayTypes = reportTypes.take(6).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report Types',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showAllReportTypes = true),
                child: const Text(
                  'See all',
                  style: TextStyle(color: Color(0xFF39A4E6), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: displayTypes.length,
            itemBuilder: (context, index) {
              final type = displayTypes[index];
              return GestureDetector(
                    onTap: () {
                      setState(
                        () => _selectedReportType = type['label'] as String,
                      );

                      Future.delayed(const Duration(milliseconds: 500), () {
                        setState(() => _selectedReportType = null);

                        // Navigate to full Reports screen
                        if (type['navigateTo'] == 'reports') {
                          setState(() {
                            _showReports = true;
                            _selectedIndex = 1; // Update bottom nav
                          });
                          return;
                        }
                        if (type['quickView'] != null) {
                          setState(() {
                            _showQuickView = {
                              'type': type['quickView'] as String,
                              'title': type['label'] as String,
                            };
                          });
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Subtle gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (type['color'] as Color).withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Count Badge
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    type['color'] as Color,
                                    (type['color'] as Color).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (type['color'] as Color).withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${type['count']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          // Icon and Label
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                      type['icon'] as IconData,
                                      color: type['color'] as Color,
                                      size: 40,
                                    )
                                    .animate(
                                      target:
                                          _selectedReportType == type['label']
                                          ? 1
                                          : 0,
                                    )
                                    .scale(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.2, 1.2),
                                    )
                                    .rotate(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      begin: 0,
                                      end: 0.1,
                                    ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    type['label'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _isDarkMode
                                          ? Colors.grey[200]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 800 + index * 50),
                    duration: const Duration(milliseconds: 400),
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: 800 + index * 50),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPanel() {
    final isDark = _isDarkMode;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showNotifications = false),
        child: Container(
          color: Colors.black.withOpacity(isDark ? 0.7 : 0.4),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping panel
              child: Padding(
                padding: const EdgeInsets.only(top: 80, right: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 384,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF111827).withOpacity(0.8) 
                            : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF39A4E6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _unreadCount > 0
                                            ? '$_unreadCount New'
                                            : 'No new alerts',
                                        style: const TextStyle(
                                          color: Color(0xFF39A4E6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (_unreadCount > 0)
                                      TextButton(
                                        onPressed: _markAllAsRead,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Mark all',
                                          style: TextStyle(
                                            color: Color(0xFF39A4E6),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => setState(() => _showNotifications = false),
                                      icon: const Icon(LucideIcons.x),
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      style: IconButton.styleFrom(
                                        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Divider(
                              height: 1,
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            ),
                          ),

                          // Content
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 480),
                              child: _isLoadingNotifications
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(48.0),
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      ),
                                    )
                                  : _notifications.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(48, 64, 48, 80),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    LucideIcons.bellOff,
                                                    size: 40,
                                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  'All Caught Up!',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? Colors.white : const Color(0xFF111827),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'No new notifications at the moment.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          shrinkWrap: true,
                                          itemCount: _notifications.length,
                                          itemBuilder: (context, index) {
                                            final n = _notifications[index];
                                            return _buildNotificationItem(n, index);
                                          },
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildNotificationItem(InAppNotification notification, int index) {
    final isDark = _isDarkMode;
    final isShare = notification.type == 'profile_share';
    final isConnectionRequest = notification.type == 'connection_request' || 
                               notification.title.toLowerCase().contains('connection request');
    
    final iconColor = (isShare || isConnectionRequest) ? const Color(0xFF8B5CF6) : const Color(0xFF39A4E6);

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await ApiClient.instance.markNotificationAsRead(notification.id);
          _loadNotifications();
        }
        
        // Handle navigation based on type or title
        if (notification.type == 'connection_request' || 
            notification.title.toLowerCase().contains('connection request') ||
            notification.message.toLowerCase().contains('connection request')) {
          
          setState(() => _showNotifications = false);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FamilyManagementScreen(initialTab: 1), // Open Connections tab
            ),
          );
        } else if (notification.type == 'report_upload' || notification.type == 'profile_share') {
          setState(() => _showNotifications = false);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? Colors.transparent 
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Icon(
                      (isShare || isConnectionRequest) ? LucideIcons.userPlus : LucideIcons.filePlus,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                if (!notification.isRead)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tap to view',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildQuickViewModal() {
    final type = _showQuickView!['type']!;
    final title = _showQuickView!['title']!;

    return GestureDetector(
      onTap: () => setState(() => _showQuickView = null),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping modal
            child:
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 40, 20, 100), // More bottom margin to avoid nav bar
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 600,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDarkMode 
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFF39A4E6), const Color(0xFF2B8FD9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Quick overview',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showQuickView = null),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                            ),
                            child: _buildQuickViewContent(type),
                          ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                            border: Border(
                              top: BorderSide(
                                color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showQuickView = null;
                                  _showReports = true;
                                  _selectedIndex = 1;
                                  _initialReportId = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF39A4E6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Explore All Reports',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 200))
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                    ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildQuickViewContent(String typeKey) {
    // Map type key to display label matching _determineReportType
    final keyToLabel = {
      'lab': 'Lab Results',
      'prescription': 'Prescriptions',
      'imaging': 'Imaging',
      'vitals': 'Vitals',
      'pathology': 'Pathology',
      'cardiology': 'Cardiology',
      'neurology': 'Neurology',
      'orthopedic': 'Orthopedic',
      'temperature': 'Temperature',
      'respiratory': 'Respiratory',
      'general': 'General',
    };

    final targetLabel = keyToLabel[typeKey] ?? 'General';
    final filteredReports = _reports
        .where((r) => r['type'] == targetLabel)
        .toList();

    return _buildGenericReportList(filteredReports);
  }

  Widget _buildGenericReportList(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.fileSearch, 
                size: 64, 
                color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No records found',
              style: TextStyle(
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], 
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another category or upload new reports.',
              style: TextStyle(
                color: _isDarkMode ? Colors.grey[600] : Colors.grey[500], 
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final report = reports[index];
        final reportId = int.tryParse(report['id'] ?? '');
        final isNormal = report['status'] == 'Normal';

        return GestureDetector(
          onTap: () {
            if (reportId != null) {
              setState(() {
                _initialReportId = reportId;
                _showQuickView = null;
                _showReports = true;
                _selectedIndex = 1;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: _isDarkMode ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon with status indicator
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (isNormal ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        LucideIcons.fileText,
                        color: isNormal ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isNormal ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'] ?? 'Report',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : const Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['doctor'] ?? 'General Practitioner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar, 
                            size: 12, 
                            color: _isDarkMode ? Colors.grey[600] : Colors.grey[400]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report['date'] ?? '',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildAllReportTypesModal() {
    final reportTypes = _getReportTypes();

    return GestureDetector(
      onTap: () => setState(() => _showAllReportTypes = false),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping modal
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Report Types',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Browse all medical report categories',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Close Button
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showAllReportTypes = false),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: 20,
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: reportTypes.length,
                        itemBuilder: (context, index) {
                          final type = reportTypes[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() => _showAllReportTypes = false);
                              // Delayed navigation to allow modal to close smoothly
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  // if (type['navigateTo'] == 'records') {
                                  //   setState(() => _showRecords = true);
                                  //   return;
                                  // }
                                  if (type['quickView'] != null) {
                                    setState(() {
                                      _showQuickView = {
                                        'type': type['quickView'] as String,
                                        'title': type['label'] as String,
                                      };
                                    });
                                  }
                                },
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _isDarkMode
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFE5E7EB),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Gradient Overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            (type['color'] as Color)
                                                .withOpacity(0.05),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Count Badge
                                  if ((type['count'] as int) > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: type['color'] as Color,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${type['count']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Icon & Label
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (type['color'] as Color)
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            type['icon'] as IconData,
                                            color: type['color'] as Color,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            type['label'] as String,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _isDarkMode
                                                  ? Colors.grey[200]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Footer Stats
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: _isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reportTypes.length} Active Categories',
                              style: const TextStyle(
                                color: Color(
                                  0xFF39A4E6,
                                ), // Blue to match design
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All report types are fully functional',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF39A4E6),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF39A4E6).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.activity,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
