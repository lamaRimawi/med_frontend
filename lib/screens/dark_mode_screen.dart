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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dark mode',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadioItem(
            context,
            'Off',
            ThemeMode.light,
            currentMode,
            (mode) => themeProvider?.setThemeMode(mode!),
          ),
          _buildRadioItem(
            context,
            'On',
            ThemeMode.dark,
            currentMode,
            (mode) => themeProvider?.setThemeMode(mode!),
          ),
          _buildRadioItem(
            context,
            'System',
            ThemeMode.system,
            currentMode,
            (mode) => themeProvider?.setThemeMode(mode!),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'If system is selected, the app will automatically adjust your appearance based on your device\'s system settings.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioItem(
    BuildContext context,
    String title,
    ThemeMode value,
    ThemeMode groupValue,
    ValueChanged<ThemeMode?> onChanged,
  ) {
    return RadioListTile<ThemeMode>(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: const Color(0xFF39A4E6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
