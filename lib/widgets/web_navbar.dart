import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/user_model.dart';

class WebNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final User? user;
  final bool isDarkMode;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  const WebNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.user,
    required this.isDarkMode,
    required this.onLogout,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              children: [
                _buildLogo(),
                const Spacer(),
                Row(
                  children: [
                    _navItem(0, LucideIcons.home, 'Overview'),
                    const SizedBox(width: 8),
                    _navItem(1, LucideIcons.fileText, 'My Reports'),
                    const SizedBox(width: 8),
                    _navItem(3, LucideIcons.calendar, 'Timeline'),
                    const SizedBox(width: 8),
                    _navItem(2, LucideIcons.upload, 'Upload'),
                  ],
                ),
                const Spacer(),
                _buildUserActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39A4E6).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.activity,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'MediScan',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = selectedIndex == index;
    final Color activeColor = const Color(0xFF39A4E6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? activeColor
                    : (isDarkMode ? Colors.white60 : Colors.grey[600]),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? activeColor
                      : (isDarkMode ? Colors.white70 : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }

  Widget _buildUserActions() {
    return Row(
      children: [
        _navItem(4, LucideIcons.user, 'Profile'),
        const SizedBox(width: 16),
        Container(
          height: 32,
          width: 1,
          color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
        ),
        const SizedBox(width: 16),
        // Theme Toggle
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleTheme,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDarkMode ? Colors.amber : Colors.indigo).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDarkMode ? Colors.amber : Colors.indigo).withOpacity(0.2),
                ),
              ),
              child: Icon(
                isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: isDarkMode ? Colors.amber : Colors.indigo,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Icon(
                LucideIcons.logOut,
                color: Colors.red,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
