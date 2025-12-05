import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/theme_toggle.dart';
import '../widgets/animated_bubble_background.dart';
import '../models/user_model.dart';
import 'medical_record_screen.dart';
import 'camera_upload_screen.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import 'profile_screen.dart';
import 'timeline_screen.dart';
import 'reports_screen.dart';
import '../widgets/report_type_badge.dart';
import '../widgets/modern_bottom_nav_bar.dart';

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
  bool _showRecords = false;
  bool _showReports = false;
  bool _showTimeline = false;
  bool _showVaccinations = false;
  bool _showCameraUpload = false;
  Map<String, String>? _showQuickView;
  bool _showFavorites = false;
  bool _showAnalytics = false;
  bool _showShareModal = false;
  bool _showAllReportTypes = false;
  int _selectedDate = 11;
  User? _currentUser;

  // Recent reports data
  List<Map<String, dynamic>> _dates = [];
  List<Map<String, String>> _reports = [];
  bool _isLoadingReports = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeDates();
    _loadReports();
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
      final reports = await ReportsService().getReports();
      if (mounted) {
        _mapReportsToUi(reports);
        setState(() => _isLoadingReports = false);
      }
    } catch (e) {
      debugPrint('Error loading home reports: $e');
      if (e.toString().contains('Unauthorized')) {
        if (mounted) {
           Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  void _mapReportsToUi(List<Report> reports) {
    _reports = reports.map((r) {
      // Parse date
      DateTime dt;
      try {
        dt = DateTime.parse(r.createdAt); 
      } catch (_) {
        dt = DateTime.now();
      }
      
      // Attempt to find doctor
      String doctor = 'Unknown Doctor';
      final docField = r.additionalFields.firstWhere(
        (f) => f.fieldName.toLowerCase().contains('doctor') || 
               f.category.toLowerCase() == 'doctor',
        orElse: () => AdditionalField(id: -1, fieldName: '', fieldValue: '', category: ''),
      );
      if (docField.id != -1) doctor = docField.fieldValue;

      // Determine status
      final allNormal = r.fields.every((f) => f.isNormal ?? true);
      final status = allNormal ? 'Normal' : 'Attention';

      // Title - use first field or generic
      String title = 'Medical Report';
      if (r.fields.isNotEmpty) {
        title = r.fields.first.fieldName;
        // Clean up title if it's too long or specific
        if (title.length > 20) title = 'Medical Report'; 
      }

      return {
        'day': '${dt.day}',
        'date': '${dt.day} ${_getMonthName(dt.month)} - ${_getDayName(dt.weekday)}',
        'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        'title': title,
        'doctor': doctor,
        'status': status,
        'type': _determineReportType(r),
      };
    }).toList();
  }

  Future<void> _loadUserData() async {
    final user = await User.loadFromPrefs();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void _initializeDates() {
    final now = DateTime.now();
    _selectedDate = now.day;
    
    // Generate 5 days centered on today
    _dates = List.generate(5, (index) {
      final date = now.subtract(Duration(days: 2 - index));
      return {
        'day': date.day,
        'label': _getDayLabel(date),
      };
    });
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
    // Adjust index based on standard weekday (1=Mon, 7=Sun)
    // My array starts with Wed? No, let's use standard.
    const standardDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return standardDays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _toggleTheme() {
    ThemeProvider.of(context)?.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCameraUpload) {
      return CameraUploadScreen(
        isDarkMode: _isDarkMode,
        onClose: () => setState(() {
          _showCameraUpload = false;
          _activeTab = 'home';
          _selectedIndex = 0;
        }),
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
        },
      );
    } else if (_showReports) {
      body = ReportsScreen(
        onBack: () => setState(() {
          _showReports = false;
          _activeTab = 'home';
          _selectedIndex = 0;
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
    } else if (_showRecords) {
      body = MedicalRecordScreen(
        onBack: () => setState(() {
          _showRecords = false;
          _activeTab = 'home';
        }),
      );
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

    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color(0xFF0F172A)
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
            _showRecords = false;
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
                    Text(
                      'Hi, Welcome Back',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF111827),
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
                    color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
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
                    color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
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
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
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
          color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearchFocused
                ? const Color(0xFF39A4E6)
                : (_isDarkMode
                      ? const Color(0xFF374151)
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
                        ? const Color(0xFF374151)
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
                            onTap: () =>
                                setState(() => _selectedDate = d['day'] as int),
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
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              constraints: const BoxConstraints(minHeight: 56),
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
                  onTap: () => setState(() => _showReports = true),
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
                          color: Colors.white.withOpacity(0.1),
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
                                color: Colors.white,
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
                                          color: textOnBlue.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      _buildStatusBadge(
                                        filtered[i]['status'] ?? 'Pending',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        filtered[i]['time'] ?? '',
                                        style: TextStyle(
                                          color: textOnBlue.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          filtered[i]['title'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
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
                                      Flexible(
                                        child: Text(
                                          filtered[i]['doctor'] ?? '',
                                          style: TextStyle(
                                            color: textOnBlue.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ReportTypeBadge(
                                        type: filtered[i]['type'] ?? 'General',
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
    String type = 'General';
    
    // Try to find a matching field in additionalFields
    final typeField = r.additionalFields.firstWhere(
      (f) => f.fieldName.toLowerCase() == 'type' || f.category.toLowerCase() == 'type',
      orElse: () => AdditionalField(id: -1, fieldName: '', fieldValue: '', category: ''),
    );
    
    if (typeField.id != -1) {
      type = typeField.fieldValue;
    }
    
    // Normalize type string
    final typeLower = type.toLowerCase();
    if (typeLower.contains('lab') || typeLower.contains('blood')) return 'Lab Results';
    if (typeLower.contains('prescription') || typeLower.contains('medication')) return 'Prescriptions';
    if (typeLower.contains('imaging') || typeLower.contains('x-ray') || typeLower.contains('scan')) return 'Imaging';
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
        'icon': LucideIcons.clipboard,
        'label': 'All Records',
        'color': const Color(0xFF39A4E6),
        'count': allReports.length,
        'navigateTo': 'records',
        'description': 'View all medical records',
      },
      {
        'icon': LucideIcons.droplet,
        'label': 'Lab Results',
        'color': const Color(0xFFFF6B9D),
        'count': counts['Lab Results'] ?? 0,
        'quickView': 'lab',
        'description': 'Blood tests & diagnostics',
      },
      {
        'icon': LucideIcons.pill,
        'label': 'Prescriptions',
        'color': const Color(0xFF6C63FF),
        'count': counts['Prescriptions'] ?? 0,
        'quickView': 'prescription',
        'description': 'Medication history',
      },
      {
        'icon': LucideIcons.scan,
        'label': 'Imaging',
        'color': const Color(0xFFA78BFA),
        'count': counts['Imaging'] ?? 0,
        'quickView': 'imaging',
        'description': 'X-rays, MRI, CT scans',
      },
      {
        'icon': LucideIcons.heartPulse,
        'label': 'Cardiology',
        'color': const Color(0xFFEF4444),
        'count': counts['Cardiology'] ?? 0,
        'quickView': 'cardiology',
        'description': 'Heart health',
      },
      {
        'icon': LucideIcons.brainCircuit,
        'label': 'Neurology',
        'color': const Color(0xFF8B5CF6),
        'count': counts['Neurology'] ?? 0,
        'quickView': 'neurology',
        'description': 'Brain & nerves',
      },
      {
        'icon': LucideIcons.bone,
        'label': 'Orthopedic',
        'color': const Color(0xFFF59E0B),
        'count': counts['Orthopedic'] ?? 0,
        'quickView': 'orthopedic',
        'description': 'Bones & joints',
      },
      {
        'icon': LucideIcons.microscope,
        'label': 'Pathology',
        'color': const Color(0xFFFBBF24),
        'count': counts['Pathology'] ?? 0,
        'quickView': 'pathology',
        'description': 'Tissue & cell analysis',
      },
      {
        'icon': LucideIcons.stethoscope,
        'label': 'General',
        'color': const Color(0xFF10B981),
        'count': counts['General'] ?? 0,
        'quickView': 'general',
        'description': 'General checkups',
      },
      {
        'icon': LucideIcons.thermometer,
        'label': 'Temperature',
        'color': const Color(0xFFF97316),
        'count': counts['Temperature'] ?? 0,
        'quickView': 'temperature',
        'description': 'Body temp records',
      },
      {
        'icon': LucideIcons.wind,
        'label': 'Respiratory',
        'color': const Color(0xFF06B6D4),
        'count': counts['Respiratory'] ?? 0,
        'quickView': 'respiratory',
        'description': 'Lungs & breathing',
      },
      {
        'icon': LucideIcons.activity,
        'label': 'Vitals',
        'color': const Color(0xFF34D399),
        'count': counts['Vitals'] ?? 0,
        'quickView': 'vitals',
        'description': 'BP, heart rate',
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

                        // Navigate to full Records screen (legacy flow)
                        if (type['navigateTo'] == 'records') {
                          setState(() => _showRecords = true);
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
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showNotifications = false),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping panel
              child: Container(
                margin: const EdgeInsets.only(top: 80, right: 24),
                width: 384,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You have 3 new notifications',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showNotifications = false),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: _isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _buildNotificationItem(
                            'Report Ready',
                            'Your blood test results are available',
                            '2h ago',
                          ),
                          _buildNotificationItem(
                            'Appointment Reminder',
                            'Dr. Turner tomorrow at 10:00 AM',
                            '5h ago',
                          ),
                          _buildNotificationItem(
                            'Shared Report',
                            'Dr. Bennett viewed your X-Ray',
                            '1d ago',
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
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.fileText,
              color: Colors.white,
              size: 24,
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
                    color: _isDarkMode ? Colors.white : const Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF39A4E6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                      margin: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                        maxHeight: 700,
                      ),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? const Color(0xFF1F2937)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
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
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Quick overview',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _showQuickView = null),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      LucideIcons.x,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Content
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: _buildQuickViewContent(type),
                            ),
                          ),
                          // Footer
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showQuickView = null;
                                    _showRecords = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF39A4E6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'View All Records',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    final filteredReports = _reports.where((r) => r['type'] == targetLabel).toList();
    
    return _buildGenericReportList(filteredReports);
  }

  Widget _buildGenericReportList(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileX, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color(0xFF374151)
                : const Color(0xFFF9FAFB),
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
                      report['title'] ?? 'Report',
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusBadge(report['status'] ?? 'Unknown'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.user, size: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report['doctor'] ?? 'Unknown Doctor',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.calendar, size: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    report['date'] ?? '',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
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
                color: _isDarkMode
                    ? const Color(0xFF1F2937)
                    : Colors.white,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Report Types',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Browse all medical report categories',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        // Close Button
                        GestureDetector(
                          onTap: () => setState(() => _showAllReportTypes = false),
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
                              color: _isDarkMode ? Colors.white : Colors.grey[600],
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
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (type['navigateTo'] == 'records') {
                                  setState(() => _showRecords = true);
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
                                            (type['color'] as Color).withOpacity(0.05),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: type['color'] as Color,
                                          borderRadius: BorderRadius.circular(12),
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (type['color'] as Color).withOpacity(0.1),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            type['label'] as String,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _isDarkMode ? Colors.grey[200] : Colors.grey[700],
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
                                color: Color(0xFF39A4E6), // Blue to match design
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All report types are fully functional',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
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

