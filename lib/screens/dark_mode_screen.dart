import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/theme_toggle.dart';

class DarkModeScreen extends StatelessWidget {
  const DarkModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final currentMode = themeProvider?.themeMode ?? ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Blue Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Dark mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),

          // Options List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOption(
                  context,
                  title: 'Off',
                  value: ThemeMode.light,
                  groupValue: currentMode,
                  onChanged: (mode) => themeProvider?.setThemeMode(mode),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildOption(
                  context,
                  title: 'On',
                  value: ThemeMode.dark,
                  groupValue: currentMode,
                  onChanged: (mode) => themeProvider?.setThemeMode(mode),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildOption(
                  context,
                  title: 'System',
                  value: ThemeMode.system,
                  groupValue: currentMode,
                  onChanged: (mode) => themeProvider?.setThemeMode(mode),
                  isDark: isDark,
                  subtitle: 'If system is selected, the app will automatically adjust your appearance based on your device\'s system settings.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF39A4E6), width: 2)
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.radio_button_checked,
                    color: Color(0xFF39A4E6),
                  )
                else
                  Icon(
                    Icons.radio_button_off,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
