import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';

import 'package:flutter_animate/flutter_animate.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _generalNotification = true;
  bool _sound = true;
  bool _vibrate = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = await User.loadFromPrefs();
    if (user != null) {
      if (mounted) {
        setState(() {
          _generalNotification = user.notificationsEnabled;
        });
      }
    }
  }

  Future<void> _updateNotificationSetting(bool value) async {
    if (mounted) {
      setState(() {
        _generalNotification = value;
        _isLoading = true;
      });
    }
    try {
      await UserService().updateUserSettings({
        'notifications_enabled': value,
      });
      // Refresh local data
      final user = await UserService().getUserProfile();
      await User.saveToPrefs(user);
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1929) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(isDark),
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39A4E6)),
              minHeight: 2,
            ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildSettingTile(
                  title: 'General Notification',
                  subtitle: 'Receive alerts for medical reports and shares',
                  value: _generalNotification,
                  onChanged: (value) => _updateNotificationSetting(value),
                  isDark: isDark,
                  icon: LucideIcons.bell,
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                _buildSettingTile(
                  title: 'Sound',
                  subtitle: 'Play sound for new notifications',
                  value: _sound,
                  onChanged: (value) => setState(() => _sound = value),
                  isDark: isDark,
                  icon: LucideIcons.volume2,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                _buildSettingTile(
                  title: 'Vibrate',
                  subtitle: 'Haptic feedback on notification received',
                  value: _vibrate,
                  onChanged: (value) => setState(() => _vibrate = value),
                  isDark: isDark,
                  icon: LucideIcons.vibrate,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
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
              'Notification Setting',
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

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132F4C).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF39A4E6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF39A4E6),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.4,
          ),
        ),
        activeColor: const Color(0xFF39A4E6),
        activeTrackColor: const Color(0xFF39A4E6).withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
