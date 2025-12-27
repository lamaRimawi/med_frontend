import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/user_model.dart';
import '../widgets/theme_toggle.dart';
import '../config/api_config.dart';
import '../services/timeline_api.dart';
import '../services/reports_service.dart';
import 'next_gen_background.dart';

class WebDashboardView extends StatefulWidget {
  final User? user;
  final bool isDarkMode;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final List<Map<String, String>> reports;
  final VoidCallback onUploadTap;
  final VoidCallback onToggleNotifications;
  final bool showNotifications;

  const WebDashboardView({
    super.key,
    this.user,
    required this.isDarkMode,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.reports,
    required this.onUploadTap,
    required this.onToggleNotifications,
    required this.showNotifications,
  });

  @override
  State<WebDashboardView> createState() => _WebDashboardViewState();
}

class _WebDashboardViewState extends State<WebDashboardView> {
  int? _totalReports;
  String? _healthScore;
  bool _isLoadingStats = true;
  String? _welcomeMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _updateWelcomeMessage();
  }

  void _updateWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _welcomeMessage = 'Good Morning';
    } else if (hour < 17) {
      _welcomeMessage = 'Good Afternoon';
    } else {
      _welcomeMessage = 'Good Evening';
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final reports = await ReportsService().getReports();
      final totalReports = reports.length;
      
      int totalTests = 0;
      int abnormalTests = 0;
      for (var report in reports) {
        for (var field in report.fields) {
          totalTests++;
          if (field.isNormal == false) {
            abnormalTests++;
          }
        }
      }
      final healthScore = totalTests > 0 
          ? ((totalTests - abnormalTests) / totalTests * 100).round()
          : 100;

      if (mounted) {
        setState(() {
          _totalReports = totalReports;
          _healthScore = '$healthScore%';
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _totalReports = widget.reports.length;
          _healthScore = 'N/A';
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHero(),
                  const SizedBox(height: 40),
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                  _buildRecentReports(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTopBar(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: (widget.isDarkMode ? Colors.black : Colors.white).withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Expanded(child: _buildFloatingSearchBar()),
              const SizedBox(width: 40),
              _buildGlassIconButton(LucideIcons.bell, widget.onToggleNotifications, hasBadge: true),
              const SizedBox(width: 15),
              _buildThemeToggle(context),
              const SizedBox(width: 25),
              _buildMiniProfile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      height: 50,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search records, diagnoses...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap, {bool hasBadge = false}) {
    return Stack(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: widget.isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x44EF4444), blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return _buildGlassIconButton(
      widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon, 
      () => ThemeProvider.of(context)?.toggleTheme()
    );
  }

  Widget _buildMiniProfile() {
    String? imageUrl = widget.user?.profileImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
      imageUrl = '$baseUrl$imageUrl';
    }

    return Row(
      children: [
        Text(
          widget.user?.fullName ?? 'User',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 15),
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF39A4E6).withOpacity(0.2),
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
              ? NetworkImage(imageUrl)
              : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(LucideIcons.user, size: 20, color: Color(0xFF39A4E6))
              : null,
        ),
      ],
    );
  }

  Widget _buildWelcomeHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF39A4E6), Color(0xFF2193b0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5539A4E6),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_welcomeMessage, ${widget.user?.fullName?.split(' ')[0] ?? 'User'}!',
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 15),
              Text(
                'You have tracked ${widget.reports.length} reports so far.\nYour health journey is looking great!',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ).animate(delay: 200.ms).fadeIn().slideX(),
              const SizedBox(height: 35),
              ElevatedButton.icon(
                onPressed: widget.onUploadTap,
                icon: const Icon(LucideIcons.plus, size: 20),
                label: const Text('Upload New Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF39A4E6),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  shadowColor: Colors.black26,
                ),
              ).animate(delay: 400.ms).scale(curve: Curves.elasticOut),
            ],
          ),
          Positioned(
            right: 0,
            bottom: -20,
            child: const Icon(
              LucideIcons.heartPulse,
              size: 200,
              color: Colors.white12,
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildGlassStatCard('Total Reports', '${_totalReports ?? 0}', LucideIcons.fileText, const Color(0xFF39A4E6)),
            _buildGlassStatCard('Health Score', _healthScore ?? 'N/A', LucideIcons.activity, const Color(0xFF10B981)),
            _buildGlassStatCard('Recent', '${widget.reports.length}', LucideIcons.clock, const Color(0xFFF59E0B)),
            _buildGlassStatCard('Tests', _totalReports != null ? '${_totalReports! * 5}' : '0', LucideIcons.flaskConical, const Color(0xFF8B5CF6)),
          ],
        );
      },
    );
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            widget.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white60 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {}, 
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF39A4E6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (widget.reports.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                   Icon(LucideIcons.fileX, size: 60, color: Colors.grey.withOpacity(0.3)),
                   const SizedBox(height: 10),
                   Text('No reports found', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
              childAspectRatio: 2.8,
            ),
            itemCount: widget.reports.take(4).length,
            itemBuilder: (context, index) => _buildReportTile(widget.reports[index], index),
          ),
      ],
    );
  }

  Widget _buildReportTile(Map<String, String> report, int index) {
    bool isNormal = report['status'] == 'Normal';
    Color statusColor = isNormal ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF39A4E6).withOpacity(0.2), const Color(0xFF2193b0).withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(LucideIcons.fileText, color: Color(0xFF39A4E6), size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  report['title'] ?? 'Medical Report',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 5),
                    Text(
                      report['date'] ?? 'Unknown Date',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              report['status'] ?? 'Pending',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX();
  }
}
