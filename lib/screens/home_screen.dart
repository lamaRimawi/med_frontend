import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'profile_screen.dart';
import 'camera_upload_screen.dart';
import '../widgets/animated_bubble_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedDate = 11;
  bool _isDarkMode = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  String? _selectedAction;
  bool _showNotifications = false;
  String? _selectedReportType;
  String _activeTab = 'home';

  final List<Map<String, dynamic>> _categories = [
    {'icon': LucideIcons.heart, 'label': 'Favorite', 'color': const Color(0xFFFF6B9D)},
    {'icon': LucideIcons.upload, 'label': 'Upload', 'color': const Color(0xFF39A4E6)},
    {'icon': LucideIcons.clock, 'label': 'Timeline', 'color': const Color(0xFFFFA726)},
    {'icon': LucideIcons.barChart3, 'label': 'Analytics', 'color': const Color(0xFF66BB6A)},
    {'icon': LucideIcons.share2, 'label': 'Share', 'color': const Color(0xFFAB47BC)},
  ];

  final List<Map<String, dynamic>> _dates = [
    {'day': 9, 'label': 'MON'},
    {'day': 10, 'label': 'TUE'},
    {'day': 11, 'label': 'WED'},
    {'day': 12, 'label': 'THU'},
    {'day': 13, 'label': 'FRI'},
    {'day': 14, 'label': 'SAT'},
  ];

  final List<Map<String, String>> _recentReports = [
    {'date': '11 Month - Wednesday - Today', 'time': '10:00 am', 'title': 'Blood Test Report', 'doctor': 'Dr. Olivia Turner'},
    {'date': '16 Month - Monday', 'time': '08:00 am', 'title': 'X-Ray Chest Report', 'doctor': 'Dr. Alexander Bennett'},
  ];

  final List<Map<String, dynamic>> _reportTypes = [
    {'icon': LucideIcons.activity, 'label': 'Blood Test', 'colors': [const Color(0xFFF5F9FF), const Color(0xFFF5F9FF)]},
    {'icon': LucideIcons.fileText, 'label': 'X-Ray', 'colors': [const Color(0xFFF5F9FF), const Color(0xFFF5F9FF)]},
    {'icon': LucideIcons.brain, 'label': 'MRI Scan', 'colors': [const Color(0xFFF5F9FF), const Color(0xFFF5F9FF)]},
    {'icon': LucideIcons.bone, 'label': 'CT Scan', 'colors': [const Color(0xFFF5F9FF), const Color(0xFFF5F9FF)]},
    {'icon': LucideIcons.microscope, 'label': 'Pathology', 'colors': [const Color(0xFFF5F9FF), const Color(0xFFF5F9FF)]},
    {'icon': LucideIcons.stethoscope, 'label': 'Radiology', 'colors': [const Color(0xFFF5F9FF), const Color(0xFFF5F9FF)]},
  ];

  final List<Map<String, String>> _notifications = [
    {'id': '1', 'title': 'Report Ready', 'message': 'Your blood test results are available', 'time': '2h ago', 'type': 'report'},
    {'id': '2', 'title': 'Appointment Reminder', 'message': 'Dr. Turner tomorrow at 10:00 AM', 'time': '5h ago', 'type': 'appointment'},
    {'id': '3', 'title': 'Shared Report', 'message': 'Dr. Bennett viewed your X-Ray', 'time': '1d ago', 'type': 'share'},
  ];



  List<Map<String, String>> get _filteredReports {
    if (_searchController.text.isEmpty) return _recentReports;
    return _recentReports.where((report) =>
      report['title']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      report['doctor']!.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  void _handleActionClick(String label) {
    setState(() => _selectedAction = label);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _selectedAction = null);
    });
  }

  void _handleReportTypeClick(String label) {
    setState(() => _selectedReportType = label);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _selectedReportType = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTab == 'profile') {
      return ProfileScreen(
        onNavigate: (screen) {
          if (screen == 'home') setState(() => _activeTab = 'home');
        },
        onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
        isDarkMode: _isDarkMode,
        onToggleDarkMode: () => setState(() => _isDarkMode = !_isDarkMode),
      );
    }

    final theme = Theme.of(context);
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF030712) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const AnimatedBubbleBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [


                              // Welcome & Avatar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Hi, Welcome Back', style: TextStyle(color: subTextColor, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text('Jane Doe', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF39A4E6).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: const Icon(LucideIcons.user, color: Colors.white, size: 28),
                                  ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Action Buttons Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Dark Mode Toggle
                                  GestureDetector(
                                    onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                                    child: Container(
                                      width: 64,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        children: [
                                          AnimatedPositioned(
                                            duration: 300.ms,
                                            curve: Curves.elasticOut,
                                            left: isDark ? 34 : 2,
                                            top: 2,
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF030712) : Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
                                                ],
                                              ),
                                              child: Icon(
                                                isDark ? LucideIcons.moon : LucideIcons.sun,
                                                size: 16,
                                                color: isDark ? Colors.white : const Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Right Actions
                                  Row(
                                    children: [
                                      _buildIconButton(
                                        icon: LucideIcons.bell,
                                        onTap: () => setState(() => _showNotifications = !_showNotifications),
                                        badgeCount: 3,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildIconButton(
                                        icon: LucideIcons.settings,
                                        onTap: () {},
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF111827) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB), width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(color: textColor),
                                  onChanged: (value) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search reports, doctors...',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: Icon(LucideIcons.search, color: Colors.grey[400], size: 20),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(LucideIcons.x, size: 16),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

                              // Search Results Dropdown
                              if (_searchController.text.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF111827) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    children: _filteredReports.isEmpty
                                        ? [
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Text('No reports found', style: TextStyle(color: subTextColor)),
                                            )
                                          ]
                                        : _filteredReports.map((report) => ListTile(
                                            title: Text(report['title']!, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                            subtitle: Text(report['doctor']!, style: TextStyle(color: subTextColor, fontSize: 12)),
                                            onTap: () {},
                                          )).toList(),
                                  ),
                                ).animate().fadeIn().moveY(begin: -10, end: 0),
                              
                              const SizedBox(height: 24),

                              // Quick Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Quick Actions', style: TextStyle(color: const Color(0xFF39A4E6), fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/reports'),
                                    child: Text('See all', style: TextStyle(color: const Color(0xFF39A4E6), fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: _categories.map((cat) => _buildQuickAction(cat, isDark)).toList(),
                              ),
                            ],
                          ),
                        ),

                        // Recent Reports
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF39A4E6), Color(0xFF1E88E5)], // Richer, smoother blue gradient
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF39A4E6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Recent Reports', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                    Text('Month', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Date Selector
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.chevronLeft, color: Colors.white.withOpacity(0.7)),
                                      const SizedBox(width: 8),
                                      ..._dates.map((date) => _buildDateItem(date)),
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.chevronRight, color: Colors.white.withOpacity(0.7)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Reports List
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/reports'),
                                    child: Text('See all', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._filteredReports.map((report) => _buildReportItem(report)),
                              ],
                            ),
                          ).animate().fadeIn(delay: 400.ms).moveY(begin: 30, end: 0),
                        ),
                        
                        const SizedBox(height: 24),

                        // Report Types
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Report Types', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/reports'),
                                    child: Text('See all', style: TextStyle(color: const Color(0xFF39A4E6), fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                children: _reportTypes.map((type) => _buildReportTypeCard(type)).toList(),
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
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildNavItem(LucideIcons.home, 'Home', 'home', isDark),
                  _buildNavItem(LucideIcons.fileText, 'Reports', 'reports', isDark, onTap: () => Navigator.pushNamed(context, '/reports')),
                  _buildCameraNavItem(),
                  _buildNavItem(LucideIcons.calendar, 'Timeline', 'timeline', isDark),
                  _buildNavItem(LucideIcons.user, 'Profile', 'profile', isDark),
                ],
              ),
            ),
          ),

          // Action Toast
          if (_selectedAction != null)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    '$_selectedAction clicked!',
                    style: TextStyle(color: isDark ? const Color(0xFF111827) : Colors.white, fontWeight: FontWeight.w500),
                  ),
                ).animate().fadeIn().moveY(begin: 20, end: 0),
              ),
            ),

          // Modern Notification Panel
          if (_showNotifications)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showNotifications = false),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 90,
                        right: 20,
                        width: 360,
                        child: GestureDetector(
                          onTap: () {}, // Prevent closing when tapping panel
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 500),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2937) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF39A4E6), Color(0xFF1E88E5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Notifications',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_notifications.length} new',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.x, color: Colors.white),
                                        onPressed: () => setState(() => _showNotifications = false),
                                      ),
                                    ],
                                  ),
                                ),
                                // Notifications List
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(12),
                                    itemCount: _notifications.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final notification = _notifications[index];
                                      final icon = notification['type'] == 'report'
                                          ? LucideIcons.fileText
                                          : notification['type'] == 'appointment'
                                              ? LucideIcons.calendar
                                              : LucideIcons.share2;
                                      
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF39A4E6), Color(0xFF1E88E5)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(icon, color: Colors.white, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    notification['title']!,
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    notification['message']!,
                                                    style: TextStyle(
                                                      color: subTextColor,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFF39A4E6),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        notification['time']!,
                                                        style: const TextStyle(
                                                          color: Color(0xFF39A4E6),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
                                    },
                                  ),
                                ),
                                // Footer Button
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF39A4E6),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'View All Notifications',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                          ).fadeIn(duration: 200.ms),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlob({required double size, required List<Color> colors}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [...colors, Colors.transparent], stops: const [0, 0.5, 1]),
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextInt(4);
    final left = 5.0 + index * 6.5;
    final top = 10.0 + (index * 5) % 70;
    
    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF39A4E6).withOpacity(0.2 + (index % 3) * 0.05),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
        begin: 0, end: -20 - random.nextDouble() * 30,
        duration: (2 + random.nextDouble() * 2).seconds,
      ).fade(begin: 0.2, end: 0.8),
    );
  }

  Widget _buildFloatingShape(int index) {
    final random = math.Random(index + 200);
    final left = random.nextDouble() * 100;
    final top = random.nextDouble() * 100;
    final size = 15.0 + random.nextInt(15);
    final icons = [LucideIcons.pill, LucideIcons.heart, LucideIcons.activity, LucideIcons.dna];
    final icon = icons[index % icons.length];
    
    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Icon(
        icon,
        color: const Color(0xFF39A4E6).withOpacity(0.1),
        size: size,
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
        begin: 0, end: -30 - random.nextDouble() * 20,
        duration: (4 + random.nextDouble() * 4).seconds,
      ).fade(begin: 0.1, end: 0.4).rotate(begin: 0, end: 0.2, duration: 5.seconds),
    );
  }

  Widget _buildFloatingCross(int index) {
    final random = math.Random(index + 100);
    final left = 15.0 + index * 18;
    
    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      bottom: 0,
      child: Icon(
        LucideIcons.plus,
        color: const Color(0xFF39A4E6).withOpacity(0.15),
        size: 20,
      ).animate(onPlay: (c) => c.repeat()).moveY(
        begin: 100, end: -100,
        duration: (15 + index * 2).seconds,
      ).rotate(begin: 0, end: 0.5, duration: 20.seconds),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, int? badgeCount, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: const Color(0xFF39A4E6), size: 20),
            if (badgeCount != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(Map<String, dynamic> category, bool isDark) {
    final isSelected = _selectedAction == category['label'];
    final color = category['color'] as Color;

    return GestureDetector(
      onTap: () => _handleActionClick(category['label']),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Icon(category['icon'], color: color, size: 24),
          ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(height: 8),
          Text(
            category['label'],
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(Map<String, dynamic> date) {
    final isSelected = _selectedDate == date['day'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date['day']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${date['day']}',
              style: TextStyle(
                color: isSelected ? const Color(0xFF39A4E6) : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              date['label'],
              style: TextStyle(
                color: isSelected ? const Color(0xFF39A4E6).withOpacity(0.8) : Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
    );
  }

  Widget _buildReportItem(Map<String, String> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['date']!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(report['time']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(width: 12),
                    Text(report['title']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(report['doctor']!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(Map<String, dynamic> type) {
    final colors = type['colors'] as List<Color>;
    final isSelected = _selectedReportType == type['label'];

    return GestureDetector(
      onTap: () => _handleReportTypeClick(type['label']),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type['icon'], color: const Color(0xFF39A4E6), size: 32),
                const SizedBox(height: 8),
                Text(
                  type['label'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF39A4E6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xFF39A4E6), strokeWidth: 2),
                  ),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String id, bool isDark, {VoidCallback? onTap}) {
    final isActive = _activeTab == id;
    final color = isActive ? const Color(0xFF39A4E6) : (isDark ? Colors.grey[500] : Colors.grey[400]);

    return GestureDetector(
      onTap: onTap ?? () => setState(() => _activeTab = id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF39A4E6).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCameraNavItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraUploadScreen(isDarkMode: _isDarkMode),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF39A4E6).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(LucideIcons.camera, color: Colors.white, size: 32),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -4, duration: 2.seconds),
          Text('Capture', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }
}
