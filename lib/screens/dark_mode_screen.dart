import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/theme_toggle.dart';

import 'package:flutter_animate/flutter_animate.dart';

class DarkModeScreen extends StatelessWidget {
  const DarkModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final currentMode = themeProvider?.themeMode ?? ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1929) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(context, isDark),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildOption(
                  context,
                  title: 'Off',
                  icon: LucideIcons.sun,
                  value: ThemeMode.light,
                  groupValue: currentMode,
                  onChanged: (mode) => themeProvider?.setThemeMode(mode),
                  isDark: isDark,
                  subtitle: 'Light mode for a bright experience',
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                _buildOption(
                  context,
                  title: 'On',
                  icon: LucideIcons.moon,
                  value: ThemeMode.dark,
                  groupValue: currentMode,
                  onChanged: (mode) => themeProvider?.setThemeMode(mode),
                  isDark: isDark,
                  subtitle: 'Dark mode for eye comfort in low light',
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                _buildOption(
                  context,
                  title: 'System',
                  icon: LucideIcons.monitor,
                  value: ThemeMode.system,
                  groupValue: currentMode,
                  onChanged: (mode) => themeProvider?.setThemeMode(mode),
                  isDark: isDark,
                  subtitle: 'Automatically adjust based on device settings',
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132F4C), const Color(0xFF0A1929)]
              : [const Color(0xFF39A4E6), const Color(0xFF2B8FD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Dark mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode> onChanged,
    required bool isDark,
    String? subtitle,
  }) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132F4C).withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF39A4E6)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF39A4E6).withOpacity(0.2)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF39A4E6)
                    : const Color(0xFF39A4E6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF39A4E6),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) => onChanged(val!),
              activeColor: const Color(0xFF39A4E6),
            ),
          ],
        ),
      ),
    );
  }
}
