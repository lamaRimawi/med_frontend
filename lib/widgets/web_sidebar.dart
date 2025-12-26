import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                  _navItem(2, LucideIcons.camera, 'Quick Scan'),
                  _navItem(3, LucideIcons.calendar, 'Timeline'),
                  _navItem(4, LucideIcons.user, 'Profile Settings'),
                  const Spacer(),
                  _buildUserCard(),
                ],
              ),
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.activity, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Text(
            'MediScan',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF111827),
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
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? activeColor : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF39A4E6).withOpacity(0.1),
            child: Text(
              user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
              style: GoogleFonts.outfit(
                color: const Color(0xFF39A4E6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User Name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Premium Plan',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF39A4E6),
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

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextButton.icon(
        onPressed: onLogout,
        icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
        label: Text(
          'Sign Out',
          style: GoogleFonts.outfit(
            color: const Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
