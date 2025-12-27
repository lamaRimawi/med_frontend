import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/user_model.dart';

class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final User? user;
  final bool isDarkMode;
  final VoidCallback onLogout;

  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.user,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 280,
          height: double.infinity,
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.08),
            border: Border(
              right: BorderSide(
                color: (isDarkMode ? Colors.white : const Color(0xFF39A4E6)).withOpacity(0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildLogo(),
              const SizedBox(height: 40),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _navItem(0, LucideIcons.home, 'Overview'),
                      _navItem(1, LucideIcons.fileText, 'My Reports'),
                      _navItem(2, LucideIcons.upload, 'Upload Report'),
                      _navItem(3, LucideIcons.calendar, 'Timeline'),
                      _navItem(4, LucideIcons.user, 'Profile Settings'),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39A4E6).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.activity,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            'MediScan',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = selectedIndex == index;
    final Color activeColor = const Color(0xFF39A4E6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabSelected(index),
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: isActive 
                  ? Border.all(color: activeColor.withOpacity(0.3))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? activeColor
                      : (isDarkMode ? Colors.white60 : Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? activeColor
                        : (isDarkMode ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 200.ms),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onLogout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.logOut,
                  size: 20,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 16),
                Text(
                  'Sign Out',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
