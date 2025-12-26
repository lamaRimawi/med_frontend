import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../widgets/theme_toggle.dart';

class WebDashboardView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHero(),
                    const SizedBox(height: 40),
                    _buildStatsGrid(),
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRecentReportsGrid()),
                        const SizedBox(width: 30),
                        Expanded(flex: 1, child: _buildQuickActions()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: 40),
          _buildActionIcon(LucideIcons.bell, onToggleNotifications, hasBadge: true),
          const SizedBox(width: 15),
          _buildThemeToggle(context),
          const SizedBox(width: 20),
          _buildMiniProfile(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search medical records, diagnoses...',
                hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.outfit(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap, {bool hasBadge = false}) {
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        children: [
          Icon(icon, size: 22, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          if (hasBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return IconButton(
      onPressed: () => ThemeProvider.of(context)?.toggleTheme(),
      icon: Icon(
        isDarkMode ? LucideIcons.sun : LucideIcons.moon,
        size: 22,
        color: const Color(0xFF39A4E6),
      ),
    );
  }

  Widget _buildMiniProfile() {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              user?.fullName ?? 'User',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
            ),
            Text(
              'Patient Account',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF39A4E6).withOpacity(0.1),
          child: const Icon(LucideIcons.user, size: 16, color: Color(0xFF39A4E6)),
        ),
      ],
    );
  }

  Widget _buildWelcomeHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39A4E6).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, ${user?.fullName?.split(' ')[0] ?? 'User'}!',
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'You have 3 new reports added this week. Your health trends are looking positive!',
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: onUploadTap,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text('Upload New Report', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF39A4E6),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          const Icon(LucideIcons.heartPulse, size: 140, color: Colors.white24)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _statCard('Total Reports', '24', LucideIcons.fileText, const Color(0xFF39A4E6)),
        _statCard('Health Score', '94%', LucideIcons.activity, const Color(0xFF10B981)),
        _statCard('Pending Tasks', '02', LucideIcons.clock, const Color(0xFFF59E0B)),
        _statCard('Connected Labs', '08', LucideIcons.building, const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500])),
              Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Reports', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
            TextButton(onPressed: () {}, child: Text('View All', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontWeight: FontWeight.w600))),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 2.2,
          ),
          itemCount: reports.length.clamp(0, 4),
          itemBuilder: (context, index) {
            final report = reports[index];
            return _reportCard(report);
          },
        ),
      ],
    );
  }

  Widget _reportCard(Map<String, String> report) {
    bool isNormal = report['status'] == 'Normal';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.fileText, color: Color(0xFF39A4E6), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(report['title'] ?? 'Record', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(report['date'] ?? '', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isNormal ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report['status'] ?? 'Unknown',
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: isNormal ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
        const SizedBox(height: 20),
        _actionButton('Find Doctor', LucideIcons.search, const Color(0xFF39A4E6)),
        const SizedBox(height: 12),
        _actionButton('Book Lab Test', LucideIcons.calendar, const Color(0xFF10B981)),
        const SizedBox(height: 12),
        _actionButton('My Medications', LucideIcons.pill, const Color(0xFF8B5CF6)),
        const SizedBox(height: 12),
        _actionButton('Help Center', LucideIcons.helpCircle, Colors.grey[600]!),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black87)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
